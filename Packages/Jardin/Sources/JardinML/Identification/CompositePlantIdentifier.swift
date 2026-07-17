import CoreGraphics
import Foundation

/// Pipeline d'identification, du plus personnalisé au plus générique :
///
/// 1. **Classifieur personnel** (kNN sur les photos validées par l'utilisateur) —
///    c'est lui qui « apprend » des corrections ;
/// 2. **Modèle Core ML embarqué** s'il est présent dans le bundle ;
/// 3. **Taxonomie Vision** d'Apple (toujours disponible, hors-ligne) ;
/// 4. **API distante** (Pl@ntNet/Plant.id) seulement si configurée et si la
///    confiance locale reste faible.
///
/// Les candidats sont fusionnés par nom, avec bonus lorsque plusieurs sources concordent.
public final class CompositePlantIdentifier: @unchecked Sendable {
    public struct Configuration: Sendable {
        public var remoteAPI: RemoteAPIConfiguration?
        /// Seuil de confiance locale sous lequel l'API distante est interrogée.
        public var remoteFallbackThreshold: Double

        public init(remoteAPI: RemoteAPIConfiguration? = nil, remoteFallbackThreshold: Double = 0.5) {
            self.remoteAPI = remoteAPI
            self.remoteFallbackThreshold = remoteFallbackThreshold
        }
    }

    let bundledIdentifier: BundledCoreMLIdentifier?
    let taxonomyIdentifier: VisionTaxonomyIdentifier
    public var configuration: Configuration

    public init(configuration: Configuration = Configuration(),
                bundledModelName: String = "PlantClassifier") {
        self.configuration = configuration
        self.bundledIdentifier = BundledCoreMLIdentifier(modelNamed: bundledModelName)
        self.taxonomyIdentifier = VisionTaxonomyIdentifier()
    }

    /// `learningExamples` : paires (étiquette, empreinte) issues du store — injectées
    /// pour que JardinML reste sans dépendance à la persistance.
    public func identify(cgImage: CGImage,
                         learningExamples: [(label: String, featurePrint: Data)]) async -> IdentificationOutcome {
        var groups: [[IdentificationCandidate]] = []
        var usedSources: [IdentificationSource] = []

        let featurePrint = try? FeaturePrintExtractor.extract(from: cgImage)

        if let featurePrint {
            let examples = learningExamples.compactMap {
                PersonalPlantClassifier.Example(label: $0.label, featurePrintData: $0.featurePrint)
            }
            let personal = PersonalPlantClassifier.classify(vector: FloatVector.decode(featurePrint),
                                                            examples: examples)
            if !personal.isEmpty {
                groups.append(personal)
                usedSources.append(.personnel)
            }
        }

        if let bundled = bundledIdentifier,
           let candidates = try? await bundled.identify(cgImage: cgImage), !candidates.isEmpty {
            groups.append(candidates)
            usedSources.append(.modeleEmbarque)
        }

        if let taxonomy = try? await taxonomyIdentifier.identify(cgImage: cgImage), !taxonomy.isEmpty {
            groups.append(taxonomy)
            usedSources.append(.visionApple)
        }

        var merged = IdentificationOutcome.merge(groups)

        if shouldUseRemoteFallback(bestLocalConfidence: merged.first?.confidence),
           let remoteConfig = configuration.remoteAPI {
            let remote = RemoteAPIIdentifier(configuration: remoteConfig)
            if let candidates = try? await remote.identify(cgImage: cgImage), !candidates.isEmpty {
                groups.append(candidates)
                usedSources.append(.apiDistante)
                merged = IdentificationOutcome.merge(groups)
            }
        }

        return IdentificationOutcome(candidates: Array(merged.prefix(6)),
                                     featurePrint: featurePrint,
                                     usedSources: usedSources)
    }

    func shouldUseRemoteFallback(bestLocalConfidence: Double?) -> Bool {
        guard configuration.remoteAPI != nil else { return false }
        return (bestLocalConfidence ?? 0) < configuration.remoteFallbackThreshold
    }
}
