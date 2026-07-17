import Foundation

/// Classifieur k-plus-proches-voisins sur les empreintes Vision des photos
/// validées/corrigées par l'utilisateur.
///
/// C'est le cœur de l'apprentissage continu : chaque correction ajoute un exemple,
/// et la reconnaissance s'améliore immédiatement, sur l'appareil, sans réentraînement.
/// Logique pure et déterministe — testable sans Vision.
public enum PersonalPlantClassifier {
    public struct Example: Sendable {
        public let label: String
        public let vector: [Float]

        public init(label: String, vector: [Float]) {
            self.label = label
            self.vector = vector
        }

        public init?(label: String, featurePrintData: Data) {
            let vector = FloatVector.decode(featurePrintData)
            guard !vector.isEmpty else { return nil }
            self.init(label: label, vector: vector)
        }
    }

    /// Distance (sur vecteurs normalisés L2, donc ∈ [0, 2]) au-delà de laquelle
    /// un voisin n'est plus considéré comme pertinent.
    public static let defaultMaxDistance: Float = 0.75

    /// Nombre minimal d'exemples avant d'oser une prédiction personnelle.
    public static let minimumExamples = 3

    public static func classify(vector: [Float],
                                examples: [Example],
                                k: Int = 5,
                                maxDistance: Float = defaultMaxDistance) -> [IdentificationCandidate] {
        guard examples.count >= minimumExamples, !vector.isEmpty else { return [] }
        let query = FloatVector.l2Normalized(vector)

        let neighbors = examples
            .compactMap { example -> (label: String, distance: Float)? in
                guard example.vector.count == vector.count else { return nil }
                let distance = FloatVector.euclideanDistance(query, FloatVector.l2Normalized(example.vector))
                return distance <= maxDistance ? (example.label, distance) : nil
            }
            .sorted { $0.distance < $1.distance }
            .prefix(k)

        guard !neighbors.isEmpty else { return [] }

        // Vote pondéré par l'inverse de la distance.
        var weights: [String: Float] = [:]
        for neighbor in neighbors {
            weights[neighbor.label, default: 0] += 1 / (neighbor.distance + 0.05)
        }
        let totalWeight = weights.values.reduce(0, +)
        guard totalWeight > 0 else { return [] }

        // La confiance combine le vote relatif et la proximité absolue du meilleur voisin,
        // pour éviter une confiance de 100 % avec un unique voisin lointain.
        let bestDistance = neighbors.first?.distance ?? maxDistance
        let proximity = Double(max(0, 1 - bestDistance / maxDistance))

        return weights
            .map { label, weight in
                let vote = Double(weight / totalWeight)
                return IdentificationCandidate(name: label,
                                               confidence: vote * (0.55 + 0.45 * proximity),
                                               source: .personnel)
            }
            .sorted { $0.confidence > $1.confidence }
    }
}
