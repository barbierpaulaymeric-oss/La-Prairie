import XCTest
@testable import JardinCore

final class InsightEngineTests: XCTestCase {
    let calendar = Calendar(identifier: .gregorian)
    let plantID = UUID()

    func date(_ year: Int, _ month: Int, _ day: Int = 15) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func plant(name: String = "Courgette verte", averageYield: Double = 0) -> PlantSnapshot {
        PlantSnapshot(id: plantID, name: name, speciesName: "Courgette", category: .potager,
                      zoneName: "Potager", waterNeed: .eleve, wateringIntervalDays: 2,
                      notificationsEnabled: true, harvestMonths: [6, 7, 8],
                      averageYieldKg: averageYield, plantedDate: date(2026, 4))
    }

    func harvest(year: Int, kg: Double) -> HarvestSnapshot {
        HarvestSnapshot(id: UUID(), plantID: plantID, plantName: "Courgette verte",
                        speciesName: "Courgette", zoneName: "Potager",
                        date: date(year, 7), quantityKg: kg, quality: 3)
    }

    func observation(month: Int, tags: [String], health: Double = 0.6) -> ObservationSnapshot {
        ObservationSnapshot(id: UUID(), plantID: plantID, plantName: "Courgette verte",
                            date: date(2026, month), tags: tags,
                            healthScore: health, detectedIssues: [])
    }

    func testYieldDropProducesInsightWithPhotoCorrelation() {
        let input = InsightEngine.Input(
            plants: [plant()],
            harvests: [harvest(year: 2025, kg: 5.0), harvest(year: 2026, kg: 2.5)],
            observations: [observation(month: 6, tags: ["excès d'eau"]),
                           observation(month: 7, tags: ["excès d'eau"])],
            year: 2026
        )
        let drafts = InsightEngine.yieldDropInsights(input, calendar: calendar)
        XCTAssertEqual(drafts.count, 1)
        let draft = drafts[0]
        XCTAssertEqual(draft.kind, .baisseRendement)
        XCTAssertEqual(draft.severity, .alerte)
        XCTAssertTrue(draft.message.contains("50 %"))
        XCTAssertTrue(draft.message.contains("excès d'eau"), "La corrélation photo doit apparaître : \(draft.message)")
        XCTAssertTrue(draft.message.contains("excès d'arrosage"))
    }

    func testSmallYieldDropIgnored() {
        let input = InsightEngine.Input(
            plants: [plant()],
            harvests: [harvest(year: 2025, kg: 5.0), harvest(year: 2026, kg: 4.5)],
            observations: [], year: 2026
        )
        XCTAssertTrue(InsightEngine.yieldDropInsights(input, calendar: calendar).isEmpty)
    }

    func testBelowSpeciesAverageProducesInfo() {
        let input = InsightEngine.Input(
            plants: [plant(averageYield: 6.0)],
            harvests: [harvest(year: 2026, kg: 3.0)],
            observations: [], year: 2026
        )
        let drafts = InsightEngine.speciesAverageInsights(input, calendar: calendar)
        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts[0].severity, .info)
        XCTAssertTrue(drafts[0].message.contains("50 %"))
    }

    func testHealthDeclineProducesAlert() {
        let input = InsightEngine.Input(
            plants: [plant()],
            harvests: [],
            observations: [observation(month: 5, tags: [], health: 0.9),
                           observation(month: 6, tags: [], health: 0.5)],
            year: 2026
        )
        let drafts = InsightEngine.healthDeclineInsights(input)
        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts[0].kind, .santeEnDeclin)
        XCTAssertEqual(drafts[0].severity, .alerte)
    }

    func testDedupeKeysAreStableAcrossRuns() {
        let input = InsightEngine.Input(
            plants: [plant()],
            harvests: [harvest(year: 2025, kg: 5.0), harvest(year: 2026, kg: 2.0)],
            observations: [], year: 2026
        )
        let first = InsightEngine.generate(input, calendar: calendar)
        let second = InsightEngine.generate(input, calendar: calendar)
        XCTAssertEqual(first.map(\.dedupeKey), second.map(\.dedupeKey))
    }
}
