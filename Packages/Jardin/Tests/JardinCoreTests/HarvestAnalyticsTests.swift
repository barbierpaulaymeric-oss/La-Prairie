import XCTest
@testable import JardinCore

final class HarvestAnalyticsTests: XCTestCase {
    let calendar = Calendar(identifier: .gregorian)
    let plantA = UUID()
    let plantB = UUID()
    let plantC = UUID()

    func date(_ year: Int, _ month: Int, _ day: Int = 15) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func harvest(_ plantID: UUID, name: String, species: String? = "Tomate",
                 zone: String? = "Potager", year: Int, month: Int, kg: Double) -> HarvestSnapshot {
        HarvestSnapshot(id: UUID(), plantID: plantID, plantName: name, speciesName: species,
                        zoneName: zone, date: date(year, month), quantityKg: kg, quality: 4)
    }

    func testMonthlyYieldGroupsByPlantAndMonth() {
        let harvests = [
            harvest(plantA, name: "Tomate 1", year: 2026, month: 7, kg: 1.0),
            harvest(plantA, name: "Tomate 1", year: 2026, month: 7, kg: 2.0),
            harvest(plantA, name: "Tomate 1", year: 2026, month: 8, kg: 1.5),
        ]
        let points = HarvestAnalytics.monthlyYield(harvests, year: 2026, calendar: calendar)
        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points.first?.totalKg, 3.0)
        XCTAssertEqual(points.last?.totalKg, 1.5)
    }

    func testYearFilterExcludesOtherYears() {
        let harvests = [
            harvest(plantA, name: "T", year: 2025, month: 7, kg: 5.0),
            harvest(plantA, name: "T", year: 2026, month: 7, kg: 1.0),
        ]
        let totals = HarvestAnalytics.totalByPlant(harvests, year: 2026, calendar: calendar)
        XCTAssertEqual(totals.count, 1)
        XCTAssertEqual(totals.first?.totalKg, 1.0)
    }

    func testYearOverYearChangeDetectsDrop() {
        let harvests = [
            harvest(plantA, name: "T", year: 2025, month: 7, kg: 4.0),
            harvest(plantA, name: "T", year: 2026, month: 7, kg: 2.0),
        ]
        let change = HarvestAnalytics.yearOverYearChange(harvests, plantID: plantA,
                                                         year: 2026, calendar: calendar)
        XCTAssertEqual(change!, -0.5, accuracy: 0.001)
    }

    func testYearOverYearChangeNilWithoutHistory() {
        let harvests = [harvest(plantA, name: "T", year: 2026, month: 7, kg: 2.0)]
        XCTAssertNil(HarvestAnalytics.yearOverYearChange(harvests, plantID: plantA,
                                                         year: 2026, calendar: calendar))
    }

    func testZoneDisparityAveragesPerPlant() {
        // Zone ombragée : 2 pieds à 1 kg de moyenne ; zone ensoleillée : 1 pied à 4 kg.
        let harvests = [
            harvest(plantA, name: "T1", zone: "Soleil", year: 2026, month: 7, kg: 4.0),
            harvest(plantB, name: "T2", zone: "Ombre", year: 2026, month: 7, kg: 1.0),
            harvest(plantC, name: "T3", zone: "Ombre", year: 2026, month: 7, kg: 1.0),
        ]
        let disparities = HarvestAnalytics.zoneDisparities(harvests, threshold: 0.3)
        XCTAssertEqual(disparities.count, 1)
        XCTAssertEqual(disparities.first?.bestZone, "Soleil")
        XCTAssertEqual(disparities.first?.worstZone, "Ombre")
        XCTAssertEqual(disparities.first!.relativeGap, 0.75, accuracy: 0.001)
    }

    func testZoneDisparityBelowThresholdIgnored() {
        let harvests = [
            harvest(plantA, name: "T1", zone: "A", year: 2026, month: 7, kg: 1.0),
            harvest(plantB, name: "T2", zone: "B", year: 2026, month: 7, kg: 0.9),
        ]
        XCTAssertTrue(HarvestAnalytics.zoneDisparities(harvests, threshold: 0.3).isEmpty)
    }

    func testRecurringTagsWithinWindow() {
        let observations = [
            ObservationSnapshot(id: UUID(), plantID: plantA, plantName: "Tomate", date: date(2026, 7, 1),
                                tags: ["jaunissement"], healthScore: 0.6, detectedIssues: []),
            ObservationSnapshot(id: UUID(), plantID: plantA, plantName: "Tomate", date: date(2026, 7, 20),
                                tags: ["Jaunissement"], healthScore: 0.5, detectedIssues: []),
            ObservationSnapshot(id: UUID(), plantID: plantA, plantName: "Tomate", date: date(2026, 3, 1),
                                tags: ["jaunissement"], healthScore: 0.8, detectedIssues: []),
        ]
        let recurring = HarvestAnalytics.recurringTags(observations, minOccurrences: 2, windowDays: 45)
        XCTAssertEqual(recurring.count, 1)
        XCTAssertEqual(recurring.first?.tag, "jaunissement")
        XCTAssertEqual(recurring.first?.occurrences, 2)
    }

    func testHealthTrendDetectsDecline() {
        let observations = [
            ObservationSnapshot(id: UUID(), plantID: plantA, plantName: "T", date: date(2026, 6, 1),
                                tags: [], healthScore: 0.9, detectedIssues: []),
            ObservationSnapshot(id: UUID(), plantID: plantA, plantName: "T", date: date(2026, 7, 1),
                                tags: [], healthScore: 0.6, detectedIssues: []),
        ]
        let trend = HarvestAnalytics.healthTrend(observations, plantID: plantA)
        XCTAssertEqual(trend!, -0.3, accuracy: 0.001)
    }

    func testHealthTrendIgnoresUnknownScores() {
        let observations = [
            ObservationSnapshot(id: UUID(), plantID: plantA, plantName: "T", date: date(2026, 6, 1),
                                tags: [], healthScore: -1, detectedIssues: []),
        ]
        XCTAssertNil(HarvestAnalytics.healthTrend(observations, plantID: plantA))
    }
}
