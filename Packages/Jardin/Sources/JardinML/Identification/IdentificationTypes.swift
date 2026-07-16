import CoreGraphics
import Foundation

public enum IdentificationSource: String, Sendable, CaseIterable {
    case personnel        // exemples de l'utilisateur (kNN sur empreintes Vision)
    case modeleEmbarque   // modèle Core ML livré avec l'app
    case visionApple      // taxonomie intégrée de Vision
    case apiDistante      // Pl@ntNet / Plant.id en dernier recours

    public var label: String {
        switch self {
        case .personnel: return "Votre jardin"
        case .modeleEmbarque: return "Modèle embarqué"
        case .visionApple: return "Vision (Apple)"
        case .apiDistante: return "API en ligne"
        }
    }
}

public struct IdentificationCandidate: Identifiable, Hashable, Sendable {
    public var id: String { "\(normalizedName)-\(source.rawValue)" }
    public let name: String
    public let scientificName: String?
    /// Confiance 0…1 affichée à l'utilisateur.
    public let confidence: Double
    public let source: IdentificationSource

    public init(name: String, scientificName: String? = nil, confidence: Double,
                source: IdentificationSource) {
        self.name = name
        self.scientificName = scientificName
        self.confidence = min(max(confidence, 0), 1)
        self.source = source
    }

    public var normalizedName: String {
        name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
    }
}

public struct IdentificationOutcome: Sendable {
    public let candidates: [IdentificationCandidate]
    public let featurePrint: Data?
    public let usedSources: [IdentificationSource]

    public var best: IdentificationCandidate? { candidates.first }

    public init(candidates: [IdentificationCandidate], featurePrint: Data?,
                usedSources: [IdentificationSource]) {
        self.candidates = candidates
        self.featurePrint = featurePrint
        self.usedSources = usedSources
    }

    /// Fusionne des candidats multi-sources : dédoublonnés par nom normalisé,
    /// la meilleure confiance gagne, léger bonus quand plusieurs sources concordent.
    public static func merge(_ groups: [[IdentificationCandidate]]) -> [IdentificationCandidate] {
        var byName: [String: IdentificationCandidate] = [:]
        var sourceCount: [String: Int] = [:]
        for group in groups {
            for candidate in group {
                let key = candidate.normalizedName
                sourceCount[key, default: 0] += 1
                if let existing = byName[key] {
                    if candidate.confidence > existing.confidence { byName[key] = candidate }
                } else {
                    byName[key] = candidate
                }
            }
        }
        return byName.map { key, candidate in
            let agreementBonus = Double(sourceCount[key, default: 1] - 1) * 0.08
            return IdentificationCandidate(name: candidate.name,
                                           scientificName: candidate.scientificName,
                                           confidence: candidate.confidence + agreementBonus,
                                           source: candidate.source)
        }
        .sorted { $0.confidence > $1.confidence }
    }
}

public protocol PlantIdentifying: Sendable {
    func identify(cgImage: CGImage) async throws -> [IdentificationCandidate]
}

public enum IdentificationError: LocalizedError {
    case featurePrintFailed
    case modelUnavailable
    case network(String)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .featurePrintFailed: return "Impossible d'analyser l'image."
        case .modelUnavailable: return "Aucun modèle de reconnaissance disponible."
        case .network(let detail): return "Erreur réseau : \(detail)"
        case .invalidResponse: return "Réponse du service de reconnaissance invalide."
        }
    }
}
