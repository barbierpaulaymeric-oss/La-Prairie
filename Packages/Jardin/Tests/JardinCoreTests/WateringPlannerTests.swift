import XCTest
@testable import JardinCore

final class WateringPlannerTests: XCTestCase {
    let calendar = Calendar(identifier: .gregorian)

    func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testIntervalFromLastCare() {
        let lastCare = date(2026, 7, 1)
        let now = date(2026, 7, 2)
        let reco = WateringPlanner.recommendation(intervalDays: 4, lastCare: lastCare,
                                                  rainProbabilityTomorrow: nil,
                                                  now: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: reco.nextDate), 5)
        XCTAssertEqual(reco.intervalDays, 4)
        XCTAssertFalse(reco.postponedForRain)
    }

    func testOverdueWateringIsDueNow() {
        let lastCare = date(2026, 6, 1)
        let now = date(2026, 7, 10)
        let reco = WateringPlanner.recommendation(intervalDays: 2, lastCare: lastCare,
                                                  rainProbabilityTomorrow: nil,
                                                  now: now, calendar: calendar)
        XCTAssertGreaterThanOrEqual(reco.nextDate, now)
        XCTAssertTrue(calendar.isDate(reco.nextDate, inSameDayAs: now))
    }

    func testRainPostponesImminentWatering() {
        let lastCare = date(2026, 7, 1)
        let now = date(2026, 7, 3, hour: 8)
        let reco = WateringPlanner.recommendation(intervalDays: 2, lastCare: lastCare,
                                                  rainProbabilityTomorrow: 0.8,
                                                  now: now, calendar: calendar)
        XCTAssertTrue(reco.postponedForRain)
        XCTAssertEqual(calendar.component(.day, from: reco.nextDate), 4)
    }

    func testLightRainDoesNotPostpone() {
        let lastCare = date(2026, 7, 1)
        let now = date(2026, 7, 3, hour: 8)
        let reco = WateringPlanner.recommendation(intervalDays: 2, lastCare: lastCare,
                                                  rainProbabilityTomorrow: 0.3,
                                                  now: now, calendar: calendar)
        XCTAssertFalse(reco.postponedForRain)
    }

    func testRainDoesNotPostponeDistantWatering() {
        let lastCare = date(2026, 7, 1)
        let now = date(2026, 7, 2, hour: 8)
        let reco = WateringPlanner.recommendation(intervalDays: 7, lastCare: lastCare,
                                                  rainProbabilityTomorrow: 0.9,
                                                  now: now, calendar: calendar)
        XCTAssertFalse(reco.postponedForRain)
        XCTAssertEqual(calendar.component(.day, from: reco.nextDate), 8)
    }

    func testNextHarvestMonthWrapsToNextYear() {
        let now = date(2026, 11, 15)
        let next = WateringPlanner.nextHarvestMonthStart(harvestMonths: [6, 7], now: now, calendar: calendar)
        XCTAssertNotNil(next)
        XCTAssertEqual(calendar.component(.year, from: next!), 2027)
        XCTAssertEqual(calendar.component(.month, from: next!), 6)
    }

    func testWaterNeedIntervalsAreOrdered() {
        XCTAssertLessThan(WaterNeed.eleve.baseWateringIntervalDays, WaterNeed.moyen.baseWateringIntervalDays)
        XCTAssertLessThan(WaterNeed.moyen.baseWateringIntervalDays, WaterNeed.faible.baseWateringIntervalDays)
    }
}
