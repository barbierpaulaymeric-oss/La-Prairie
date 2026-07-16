import CoreGraphics
import Foundation
import Vision

/// Reconnaissance de base sans aucun modèle à embarquer : la taxonomie intégrée de
/// Vision (`VNClassifyImageRequest`, ~1300 classes) couvre beaucoup de plantes
/// comestibles courantes. Sert de socle avant le modèle Core ML et l'API distante.
public struct VisionTaxonomyIdentifier: PlantIdentifying {
    public init() {}

    /// Identifiants de la taxonomie Vision → nom commun français de notre base.
    static let frenchNames: [String: String] = [
        "tomato": "Tomate", "cherry_tomato": "Tomate",
        "zucchini": "Courgette", "squash": "Courgette",
        "cucumber": "Concombre",
        "carrot": "Carotte",
        "lettuce": "Laitue", "salad": "Laitue",
        "spinach": "Épinard",
        "radish": "Radis",
        "strawberry": "Fraisier",
        "raspberry": "Framboisier",
        "apple": "Pommier",
        "bell_pepper": "Poivron", "pepper": "Poivron",
        "eggplant": "Aubergine", "aubergine": "Aubergine",
        "green_bean": "Haricot vert", "bean": "Haricot vert",
        "basil": "Basilic",
        "mint": "Menthe",
        "rosemary": "Romarin",
        "thyme": "Thym",
        "parsley": "Persil",
        "chive": "Ciboulette",
        "sage": "Sauge officinale",
        "oregano": "Origan",
        "lavender": "Lavande",
        "marigold": "Œillet d'Inde",
    ]

    /// Classes génériques utiles comme indice quand rien de précis ne ressort.
    static let genericPlantIdentifiers: Set<String> = [
        "plant", "flower", "tree", "herb", "vegetable", "fruit", "leaf", "foliage",
    ]

    public func identify(cgImage: CGImage) async throws -> [IdentificationCandidate] {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        let observations = (request.results ?? []).filter { $0.confidence > 0.05 }
        return Self.candidates(from: observations.map { ($0.identifier, Double($0.confidence)) })
    }

    /// Transformation pure (identifiant, confiance) → candidats, testable sans Vision.
    public static func candidates(from classifications: [(identifier: String, confidence: Double)]) -> [IdentificationCandidate] {
        var specific: [IdentificationCandidate] = []
        var genericBest: (String, Double)?

        for (identifier, confidence) in classifications {
            let key = identifier.lowercased()
            if let frenchName = frenchNames[key] {
                specific.append(IdentificationCandidate(name: frenchName,
                                                        confidence: confidence,
                                                        source: .visionApple))
            } else if genericPlantIdentifiers.contains(key) {
                if confidence > (genericBest?.1 ?? 0) { genericBest = (key, confidence) }
            }
        }

        var merged = IdentificationOutcome.merge([specific])
        if merged.isEmpty, let generic = genericBest {
            // Indice générique uniquement : confiance plafonnée, l'UI proposera la recherche manuelle.
            merged = [IdentificationCandidate(name: "Plante non identifiée (\(generic.0))",
                                              confidence: min(generic.1, 0.3),
                                              source: .visionApple)]
        }
        return merged
    }
}
