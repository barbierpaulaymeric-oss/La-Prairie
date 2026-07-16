import XCTest
@testable import JardinML

final class PersonalClassifierTests: XCTestCase {
    /// Vecteurs synthétiques : trois groupes autour d'axes orthogonaux, avec bruit léger.
    func cluster(axis: Int, dimensions: Int = 8, jitter: Float, seedOffset: Float = 0) -> [Float] {
        var vector = [Float](repeating: jitter + seedOffset * 0.01, count: dimensions)
        vector[axis] = 1
        return vector
    }

    func examples() -> [PersonalPlantClassifier.Example] {
        (0..<4).flatMap { index in
            [
                PersonalPlantClassifier.Example(label: "Basilic", vector: cluster(axis: 0, jitter: 0.05, seedOffset: Float(index))),
                PersonalPlantClassifier.Example(label: "Menthe", vector: cluster(axis: 1, jitter: 0.05, seedOffset: Float(index))),
                PersonalPlantClassifier.Example(label: "Tomate", vector: cluster(axis: 2, jitter: 0.05, seedOffset: Float(index))),
            ]
        }
    }

    func testClassifiesNearestCluster() {
        let candidates = PersonalPlantClassifier.classify(vector: cluster(axis: 1, jitter: 0.08),
                                                          examples: examples())
        XCTAssertEqual(candidates.first?.name, "Menthe")
        XCTAssertEqual(candidates.first?.source, .personnel)
        XCTAssertGreaterThan(candidates.first!.confidence, 0.5)
    }

    func testCorrectionShiftsPrediction() {
        // L'utilisateur corrige : des exemples « Menthe » très proches du vecteur requête
        // doivent l'emporter sur les « Basilic » plus lointains.
        var learned = examples().filter { $0.label == "Basilic" }
        let query = cluster(axis: 3, jitter: 0.02)
        learned += (0..<3).map { _ in PersonalPlantClassifier.Example(label: "Menthe", vector: query) }

        let candidates = PersonalPlantClassifier.classify(vector: query, examples: learned)
        XCTAssertEqual(candidates.first?.name, "Menthe",
                       "Après correction, les exemples utilisateur doivent primer")
    }

    func testRejectsWhenTooFar() {
        var opposite = [Float](repeating: 0, count: 8)
        opposite[7] = -1
        let candidates = PersonalPlantClassifier.classify(vector: opposite,
                                                          examples: examples(),
                                                          maxDistance: 0.3)
        XCTAssertTrue(candidates.isEmpty, "Aucun voisin sous le seuil → aucune prédiction")
    }

    func testNeedsMinimumExamples() {
        let few = Array(examples().prefix(2))
        let candidates = PersonalPlantClassifier.classify(vector: cluster(axis: 0, jitter: 0.05),
                                                          examples: few)
        XCTAssertTrue(candidates.isEmpty)
    }

    func testIgnoresMismatchedDimensions() {
        let bad = [PersonalPlantClassifier.Example(label: "Corrompu", vector: [1, 0]),
                   PersonalPlantClassifier.Example(label: "Corrompu", vector: [0, 1]),
                   PersonalPlantClassifier.Example(label: "Corrompu", vector: [1, 1])]
        let candidates = PersonalPlantClassifier.classify(vector: cluster(axis: 0, jitter: 0),
                                                          examples: bad)
        XCTAssertTrue(candidates.isEmpty)
    }

    func testConfidencesSumBelowOne() {
        let candidates = PersonalPlantClassifier.classify(vector: cluster(axis: 0, jitter: 0.3),
                                                          examples: examples())
        let total = candidates.reduce(0) { $0 + $1.confidence }
        XCTAssertLessThanOrEqual(total, 1.001)
    }
}

final class FloatVectorTests: XCTestCase {
    func testRoundTrip() {
        let vector: [Float] = [1.5, -2.25, 0, 42]
        XCTAssertEqual(FloatVector.decode(FloatVector.encode(vector)), vector)
    }

    func testDecodeRejectsMisalignedData() {
        XCTAssertEqual(FloatVector.decode(Data([1, 2, 3])), [])
        XCTAssertEqual(FloatVector.decode(Data()), [])
    }

    func testNormalization() {
        let normalized = FloatVector.l2Normalized([3, 4])
        XCTAssertEqual(normalized[0], 0.6, accuracy: 0.0001)
        XCTAssertEqual(normalized[1], 0.8, accuracy: 0.0001)
        XCTAssertEqual(FloatVector.l2Normalized([0, 0]), [0, 0])
    }

    func testEuclideanDistance() {
        XCTAssertEqual(FloatVector.euclideanDistance([0, 0], [3, 4]), 5, accuracy: 0.0001)
        XCTAssertEqual(FloatVector.euclideanDistance([1], [1, 2]), .greatestFiniteMagnitude)
    }
}
