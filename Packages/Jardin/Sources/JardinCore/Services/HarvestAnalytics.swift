import Foundation

/// Agrégations et corrélations sur les récoltes et observations.
/// Fonctions pures sur des snapshots : testables sans Core Data.
public enum HarvestAnalytics {
    public struct YieldPoint: Identifiable, Hashable, Sendable {
        public var id: String { "\(label)-\(monthDate.timeIntervalSince1970)" }
        public let monthDate: Date
        public let label: String
        public let totalKg: Double

        public init(monthDate: Date, label: String, totalKg: Double) {
            self.monthDate = monthDate
            self.label = label
            self.totalKg = totalKg
        }
    }

    public struct GroupTotal: Identifiable, Hashable, Sendable {
        public var id: String { label }
        public let label: String
        public let totalKg: Double

        public init(label: String, totalKg: Double) {
            self.label = label
            self.totalKg = totalKg
        }
    }

    static func monthStart(of date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    /// Rendement mensuel, groupé par plante (pour le graphique principal).
    public static func monthlyYield(_ harvests: [HarvestSnapshot],
                                    year: Int? = nil,
                                    calendar: Calendar = .current) -> [YieldPoint] {
        let filtered = harvests.filter { harvest in
            guard let year else { return true }
            return calendar.component(.year, from: harvest.date) == year
        }
        var buckets: [String: [Date: Double]] = [:]
        for harvest in filtered {
            let month = monthStart(of: harvest.date, calendar: calendar)
            buckets[harvest.plantName, default: [:]][month, default: 0] += harvest.quantityKg
        }
        return buckets.flatMap { plantName, months in
            months.map { YieldPoint(monthDate: $0.key, label: plantName, totalKg: $0.value) }
        }
        .sorted { $0.monthDate < $1.monthDate }
    }

    public static func totalByPlant(_ harvests: [HarvestSnapshot], year: Int? = nil,
                                    calendar: Calendar = .current) -> [GroupTotal] {
        totals(harvests, year: year, calendar: calendar) { $0.plantName }
    }

    public static func totalByZone(_ harvests: [HarvestSnapshot], year: Int? = nil,
                                   calendar: Calendar = .current) -> [GroupTotal] {
        totals(harvests, year: year, calendar: calendar) { $0.zoneName ?? "Hors zone" }
    }

    private static func totals(_ harvests: [HarvestSnapshot], year: Int?,
                               calendar: Calendar,
                               key: (HarvestSnapshot) -> String) -> [GroupTotal] {
        var buckets: [String: Double] = [:]
        for harvest in harvests {
            if let year, calendar.component(.year, from: harvest.date) != year { continue }
            buckets[key(harvest), default: 0] += harvest.quantityKg
        }
        return buckets.map { GroupTotal(label: $0.key, totalKg: $0.value) }
            .sorted { $0.totalKg > $1.totalKg }
    }

    /// Variation du rendement d'une plante entre deux années (ex : -0.4 pour −40 %).
    public static func yearOverYearChange(_ harvests: [HarvestSnapshot],
                                          plantID: UUID,
                                          year: Int,
                                          calendar: Calendar = .current) -> Double? {
        let mine = harvests.filter { $0.plantID == plantID }
        let current = mine.filter { calendar.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.quantityKg }
        let previous = mine.filter { calendar.component(.year, from: $0.date) == year - 1 }
            .reduce(0) { $0 + $1.quantityKg }
        guard previous > 0, current > 0 || previous > 0 else { return nil }
        return (current - previous) / previous
    }

    /// Écart du rendement annuel d'une plante par rapport à la moyenne de son espèce.
    public static func deviationFromSpeciesAverage(totalKg: Double, speciesAverageKg: Double) -> Double? {
        guard speciesAverageKg > 0 else { return nil }
        return (totalKg - speciesAverageKg) / speciesAverageKg
    }

    /// Compare le rendement moyen d'une même espèce entre zones.
    /// Retourne les paires (zone la plus productive, zone la moins productive) si l'écart dépasse `threshold`.
    public struct ZoneDisparity: Hashable, Sendable {
        public let speciesName: String
        public let bestZone: String
        public let bestAverageKg: Double
        public let worstZone: String
        public let worstAverageKg: Double

        public var relativeGap: Double {
            guard bestAverageKg > 0 else { return 0 }
            return (bestAverageKg - worstAverageKg) / bestAverageKg
        }
    }

    public static func zoneDisparities(_ harvests: [HarvestSnapshot],
                                       threshold: Double = 0.3) -> [ZoneDisparity] {
        // moyenne par plante puis par zone, pour ne pas favoriser les zones à nombreux pieds
        var perSpeciesZonePlant: [String: [String: [UUID: Double]]] = [:]
        for harvest in harvests {
            guard let speciesName = harvest.speciesName, let zone = harvest.zoneName else { continue }
            perSpeciesZonePlant[speciesName, default: [:]][zone, default: [:]][harvest.plantID, default: 0] += harvest.quantityKg
        }

        var results: [ZoneDisparity] = []
        for (speciesName, zones) in perSpeciesZonePlant where zones.count >= 2 {
            let averages = zones.mapValues { plants -> Double in
                plants.values.reduce(0, +) / Double(plants.count)
            }
            guard let best = averages.max(by: { $0.value < $1.value }),
                  let worst = averages.min(by: { $0.value < $1.value }),
                  best.key != worst.key, best.value > 0 else { continue }
            let disparity = ZoneDisparity(speciesName: speciesName,
                                          bestZone: best.key, bestAverageKg: best.value,
                                          worstZone: worst.key, worstAverageKg: worst.value)
            if disparity.relativeGap >= threshold { results.append(disparity) }
        }
        return results.sorted { $0.relativeGap > $1.relativeGap }
    }

    /// Tags d'observation récurrents (≥ `minOccurrences` sur une fenêtre de 45 jours) pour une plante.
    public struct RecurringTag: Hashable, Sendable {
        public let plantID: UUID
        public let plantName: String
        public let tag: String
        public let occurrences: Int
        public let lastDate: Date
    }

    public static func recurringTags(_ observations: [ObservationSnapshot],
                                     minOccurrences: Int = 2,
                                     windowDays: Double = 45) -> [RecurringTag] {
        var results: [RecurringTag] = []
        let byPlant = Dictionary(grouping: observations, by: \.plantID)
        for (plantID, plantObservations) in byPlant {
            var tagDates: [String: [Date]] = [:]
            for observation in plantObservations {
                for tag in observation.tags {
                    tagDates[tag.lowercased(), default: []].append(observation.date)
                }
            }
            for (tag, dates) in tagDates {
                let sorted = dates.sorted()
                var best = 1
                var start = 0
                for end in 0..<sorted.count {
                    while sorted[end].timeIntervalSince(sorted[start]) > windowDays * 86400 { start += 1 }
                    best = max(best, end - start + 1)
                }
                if best >= minOccurrences, let last = sorted.last {
                    results.append(RecurringTag(plantID: plantID,
                                                plantName: plantObservations.first?.plantName ?? "",
                                                tag: tag, occurrences: best, lastDate: last))
                }
            }
        }
        return results.sorted { $0.occurrences > $1.occurrences }
    }

    /// Tendance du score de santé sur les dernières observations d'une plante (pente < 0 = déclin).
    public static func healthTrend(_ observations: [ObservationSnapshot],
                                   plantID: UUID,
                                   lastN: Int = 3) -> Double? {
        let scores = observations
            .filter { $0.plantID == plantID && $0.healthScore >= 0 }
            .sorted { $0.date < $1.date }
            .suffix(lastN)
            .map(\.healthScore)
        guard scores.count >= 2, let first = scores.first, let last = scores.last else { return nil }
        return last - first
    }
}
