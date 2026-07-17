import XCTest
@testable import JardinML

final class HealthMathTests: XCTestCase {
    /// Construit un tampon RGBA rempli par blocs de couleurs (proportions exactes).
    func buffer(colors: [(rgb: (UInt8, UInt8, UInt8), count: Int)]) -> (pixels: [UInt8], width: Int, height: Int) {
        var pixels: [UInt8] = []
        for (rgb, count) in colors {
            for _ in 0..<count {
                pixels.append(contentsOf: [rgb.0, rgb.1, rgb.2, 255])
            }
        }
        return (pixels, pixels.count / 4, 1)
    }

    let green: (UInt8, UInt8, UInt8) = (40, 160, 60)      // teinte ~130
    let yellow: (UInt8, UInt8, UInt8) = (210, 190, 40)    // teinte ~53
    let brown: (UInt8, UInt8, UInt8) = (120, 70, 30)      // teinte ~27, sombre
    let grey: (UInt8, UInt8, UInt8) = (128, 128, 128)     // saturation nulle → ignoré

    func testHealthyFoliageScoresHigh() {
        let b = buffer(colors: [(green, 90), (grey, 10)])
        let report = HealthMath.analyze(pixels: b.pixels, width: b.width, height: b.height)
        XCTAssertEqual(report.score, 1.0, accuracy: 0.01)
        XCTAssertTrue(report.issues.isEmpty)
        XCTAssertEqual(report.vegetationRatio, 0.9, accuracy: 0.01)
    }

    func testYellowingDetected() {
        let b = buffer(colors: [(green, 60), (yellow, 40)])
        let report = HealthMath.analyze(pixels: b.pixels, width: b.width, height: b.height)
        XCTAssertEqual(report.yellowRatio, 0.4, accuracy: 0.02)
        XCTAssertEqual(report.score, 0.6, accuracy: 0.02)
        XCTAssertTrue(report.issues.contains { $0.label.contains("Jaunissement") })
    }

    func testBrownSpotsDetected() {
        let b = buffer(colors: [(green, 80), (brown, 20)])
        let report = HealthMath.analyze(pixels: b.pixels, width: b.width, height: b.height)
        XCTAssertEqual(report.brownRatio, 0.2, accuracy: 0.02)
        XCTAssertTrue(report.issues.contains { $0.label.contains("Taches") })
    }

    func testNoVegetationReturnsUnknownScore() {
        let b = buffer(colors: [(grey, 100)])
        let report = HealthMath.analyze(pixels: b.pixels, width: b.width, height: b.height)
        XCTAssertEqual(report.score, -1)
        XCTAssertTrue(report.issues.contains { $0.label.contains("peu visible") })
    }

    func testMaskRestrictsAnalysis() {
        // Moitié verte (masquée comme fond), moitié jaune (premier plan).
        let b = buffer(colors: [(green, 50), (yellow, 50)])
        var mask = [Bool](repeating: false, count: 100)
        for index in 50..<100 { mask[index] = true }
        let report = HealthMath.analyze(pixels: b.pixels, width: b.width, height: b.height, mask: mask)
        XCTAssertEqual(report.yellowRatio, 1.0, accuracy: 0.01,
                       "Seule la zone masquée premier plan doit être analysée")
    }

    func testRGBToHSVKnownValues() {
        let red = HealthMath.rgbToHSV(r: 1, g: 0, b: 0)
        XCTAssertEqual(red.hue, 0, accuracy: 0.5)
        let greenHue = HealthMath.rgbToHSV(r: 0, g: 1, b: 0)
        XCTAssertEqual(greenHue.hue, 120, accuracy: 0.5)
        let blue = HealthMath.rgbToHSV(r: 0, g: 0, b: 1)
        XCTAssertEqual(blue.hue, 240, accuracy: 0.5)
        XCTAssertEqual(blue.saturation, 1)
        XCTAssertEqual(blue.value, 1)
    }
}

final class GrowthAnalyzerTests: XCTestCase {
    func testGrowthDetected() {
        let comparison = GrowthAnalyzer.compare(previousRatio: 0.20, currentRatio: 0.23)
        XCTAssertEqual(comparison.areaChangePercent!, 15, accuracy: 0.5)
        XCTAssertTrue(comparison.message.contains("grandi"))
        XCTAssertTrue(comparison.message.contains("15"))
    }

    func testShrinkageDetected() {
        let comparison = GrowthAnalyzer.compare(previousRatio: 0.4, currentRatio: 0.3, daysBetween: 12)
        XCTAssertEqual(comparison.areaChangePercent!, -25, accuracy: 0.5)
        XCTAssertTrue(comparison.message.contains("diminué"))
        XCTAssertTrue(comparison.message.contains("12 jours"))
    }

    func testStableGrowth() {
        let comparison = GrowthAnalyzer.compare(previousRatio: 0.3, currentRatio: 0.31)
        XCTAssertTrue(comparison.message.contains("stable"))
    }

    func testUnusableRatiosGiveNoPercent() {
        let comparison = GrowthAnalyzer.compare(previousRatio: 0.001, currentRatio: 0.3)
        XCTAssertNil(comparison.areaChangePercent)
    }

    func testExtremeChangeIsBounded() {
        let comparison = GrowthAnalyzer.compare(previousRatio: 0.02, currentRatio: 0.9)
        XCTAssertEqual(comparison.areaChangePercent!, 300, accuracy: 0.5)
    }

    func testStageEstimation() {
        XCTAssertEqual(GrowthAnalyzer.estimateStage(ageDays: 20, lifespanYears: 1), .jeunePousse)
        XCTAssertEqual(GrowthAnalyzer.estimateStage(ageDays: 120, lifespanYears: 1), .croissance)
        XCTAssertEqual(GrowthAnalyzer.estimateStage(ageDays: 250, lifespanYears: 1), .mature)
        XCTAssertEqual(GrowthAnalyzer.estimateStage(ageDays: 350, lifespanYears: 1), .senescent)
        XCTAssertEqual(GrowthAnalyzer.estimateStage(ageDays: nil, lifespanYears: 1), .croissance)
    }
}
