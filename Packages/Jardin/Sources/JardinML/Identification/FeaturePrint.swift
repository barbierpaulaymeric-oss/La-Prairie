import CoreGraphics
import Foundation
import Vision

/// Empreintes d'images Vision (`VNGenerateImageFeaturePrintRequest`) : la base de
/// l'apprentissage continu. Chaque photo validée devient un vecteur stocké localement,
/// comparable aux photos futures sans réentraîner de modèle.
public enum FeaturePrintExtractor {
    public static func extract(from cgImage: CGImage) throws -> Data {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        guard let observation = request.results?.first as? VNFeaturePrintObservation else {
            throw IdentificationError.featurePrintFailed
        }
        return observation.data
    }
}

/// Sérialisation des vecteurs d'empreintes ([Float] ⇄ Data), indépendante de Vision
/// pour rester testable et réutilisable côté export.
public enum FloatVector {
    public static func decode(_ data: Data) -> [Float] {
        guard data.count >= MemoryLayout<Float>.size,
              data.count % MemoryLayout<Float>.size == 0 else { return [] }
        return data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }
    }

    public static func encode(_ vector: [Float]) -> Data {
        vector.withUnsafeBufferPointer { Data(buffer: $0) }
    }

    public static func l2Normalized(_ vector: [Float]) -> [Float] {
        let norm = sqrt(vector.reduce(Float(0)) { $0 + $1 * $1 })
        guard norm > 0 else { return vector }
        return vector.map { $0 / norm }
    }

    public static func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return .greatestFiniteMagnitude }
        var sum: Float = 0
        for i in 0..<a.count {
            let d = a[i] - b[i]
            sum += d * d
        }
        return sqrt(sum)
    }
}
