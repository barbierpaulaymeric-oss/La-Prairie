import XCTest
@testable import JardinML

final class CandidateMergeTests: XCTestCase {
    func testMergeDeduplicatesByNormalizedName() {
        let merged = IdentificationOutcome.merge([
            [IdentificationCandidate(name: "Tomate", confidence: 0.6, source: .visionApple)],
            [IdentificationCandidate(name: "tomate", confidence: 0.8, source: .modeleEmbarque)],
        ])
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.source, .modeleEmbarque, "La meilleure confiance doit gagner")
        XCTAssertEqual(merged.first!.confidence, 0.88, accuracy: 0.001, "Bonus de concordance attendu")
    }

    func testMergeHandlesDiacritics() {
        let merged = IdentificationOutcome.merge([
            [IdentificationCandidate(name: "Épinard", confidence: 0.5, source: .visionApple)],
            [IdentificationCandidate(name: "epinard", confidence: 0.4, source: .apiDistante)],
        ])
        XCTAssertEqual(merged.count, 1)
    }

    func testMergeSortsByConfidence() {
        let merged = IdentificationOutcome.merge([
            [IdentificationCandidate(name: "Menthe", confidence: 0.3, source: .visionApple),
             IdentificationCandidate(name: "Basilic", confidence: 0.9, source: .visionApple)],
        ])
        XCTAssertEqual(merged.map(\.name), ["Basilic", "Menthe"])
    }

    func testConfidenceClamped() {
        let candidate = IdentificationCandidate(name: "X", confidence: 1.7, source: .personnel)
        XCTAssertEqual(candidate.confidence, 1.0)
    }
}

final class VisionTaxonomyMappingTests: XCTestCase {
    func testKnownIdentifiersMapToFrenchNames() {
        let candidates = VisionTaxonomyIdentifier.candidates(from: [
            ("tomato", 0.85), ("vegetable", 0.9), ("car", 0.99),
        ])
        XCTAssertEqual(candidates.first?.name, "Tomate")
        XCTAssertEqual(candidates.first?.confidence ?? 0, 0.85, accuracy: 0.001)
        XCTAssertFalse(candidates.contains { $0.name.contains("car") })
    }

    func testGenericFallbackWhenNothingSpecific() {
        let candidates = VisionTaxonomyIdentifier.candidates(from: [
            ("plant", 0.9), ("car", 0.2),
        ])
        XCTAssertEqual(candidates.count, 1)
        XCTAssertTrue(candidates[0].name.contains("non identifiée"))
        XCTAssertLessThanOrEqual(candidates[0].confidence, 0.3, "Confiance générique plafonnée")
    }

    func testEmptyInputGivesNoCandidates() {
        XCTAssertTrue(VisionTaxonomyIdentifier.candidates(from: []).isEmpty)
    }
}

final class CompositeFallbackPolicyTests: XCTestCase {
    func testRemoteFallbackOnlyWhenConfiguredAndUncertain() {
        let noRemote = CompositePlantIdentifier(configuration: .init(remoteAPI: nil))
        XCTAssertFalse(noRemote.shouldUseRemoteFallback(bestLocalConfidence: 0.1))

        let config = RemoteAPIConfiguration(provider: .plantNet, apiKey: "clef")
        let withRemote = CompositePlantIdentifier(configuration: .init(remoteAPI: config,
                                                                       remoteFallbackThreshold: 0.5))
        XCTAssertTrue(withRemote.shouldUseRemoteFallback(bestLocalConfidence: 0.3))
        XCTAssertTrue(withRemote.shouldUseRemoteFallback(bestLocalConfidence: nil))
        XCTAssertFalse(withRemote.shouldUseRemoteFallback(bestLocalConfidence: 0.8))
    }

    func testHumanReadableLabels() {
        XCTAssertEqual(BundledCoreMLIdentifier.humanReadable("tomate_cerise"), "Tomate cerise")
        XCTAssertEqual(BundledCoreMLIdentifier.humanReadable("basilic"), "Basilic")
    }
}
