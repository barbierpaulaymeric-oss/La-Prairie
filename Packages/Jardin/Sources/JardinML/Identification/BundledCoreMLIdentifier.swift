import CoreGraphics
import CoreML
import Foundation
import Vision

/// Modèle Core ML embarqué (ex : `PlantClassifier.mlpackage` entraîné avec
/// `MLTraining/train_initial_classifier.py` sur PlantVillage/iNaturalist puis ajouté
/// à la cible app). L'app fonctionne sans lui : l'initialiseur échoue proprement et
/// le pipeline composite passe aux sources suivantes.
public final class BundledCoreMLIdentifier: PlantIdentifying, @unchecked Sendable {
    private let visionModel: VNCoreMLModel
    private let modelName: String

    public init?(modelNamed name: String = "PlantClassifier", bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: name, withExtension: "mlmodelc"),
              let coreMLModel = try? MLModel(contentsOf: url),
              let visionModel = try? VNCoreMLModel(for: coreMLModel) else { return nil }
        self.visionModel = visionModel
        self.modelName = name
    }

    public func identify(cgImage: CGImage) async throws -> [IdentificationCandidate] {
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNClassificationObservation] else {
            return []
        }
        return observations
            .prefix(5)
            .filter { $0.confidence > 0.05 }
            .map { observation in
                IdentificationCandidate(name: Self.humanReadable(observation.identifier),
                                        confidence: Double(observation.confidence),
                                        source: .modeleEmbarque)
            }
    }

    /// Les labels d'entraînement utilisent des underscores ("tomate_cerise") : on les
    /// restitue lisibles, la casse d'origine du premier mot étant conservée.
    static func humanReadable(_ identifier: String) -> String {
        let words = identifier.replacingOccurrences(of: "_", with: " ")
        return words.prefix(1).uppercased() + words.dropFirst()
    }
}
