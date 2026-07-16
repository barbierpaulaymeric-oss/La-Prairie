import Foundation

/// Calcul pur du calendrier d'arrosage — logique isolée pour être testable.
public enum WateringPlanner {
    public struct Recommendation: Equatable, Sendable {
        public let nextDate: Date
        public let intervalDays: Int
        public let postponedForRain: Bool
        public let reason: String
    }

    /// Probabilité de pluie au-delà de laquelle un arrosage est reporté d'un jour.
    public static let rainPostponeThreshold: Double = 0.6

    public static func recommendation(intervalDays: Int,
                                      lastCare: Date?,
                                      rainProbabilityTomorrow: Double?,
                                      now: Date = Date(),
                                      calendar: Calendar = .current) -> Recommendation {
        let interval = max(1, intervalDays)
        let reference = lastCare ?? now
        var next = calendar.date(byAdding: .day, value: interval, to: reference) ?? now

        // Un arrosage déjà en retard est dû aujourd'hui, pas dans le passé.
        if next < now { next = now }

        var postponed = false
        var reason = "Intervalle de \(interval) j selon le besoin en eau."
        if let rain = rainProbabilityTomorrow, rain >= rainPostponeThreshold,
           calendar.isDate(next, inSameDayAs: now) || calendar.isDateInTomorrow(next) {
            next = calendar.date(byAdding: .day, value: 1, to: next) ?? next
            postponed = true
            reason = "Pluie prévue (\(Int(rain * 100)) %) : arrosage reporté d'un jour."
        }

        // Notification à 9 h le jour dit.
        var components = calendar.dateComponents([.year, .month, .day], from: next)
        components.hour = 9
        components.minute = 0
        let scheduled = calendar.date(from: components) ?? next

        return Recommendation(nextDate: max(scheduled, now),
                              intervalDays: interval,
                              postponedForRain: postponed,
                              reason: reason)
    }

    /// Prochain mois de récolte à venir (pour les rappels "vos tomates sont mûres").
    public static func nextHarvestMonthStart(harvestMonths: [Int],
                                             now: Date = Date(),
                                             calendar: Calendar = .current) -> Date? {
        guard !harvestMonths.isEmpty else { return nil }
        let currentYear = calendar.component(.year, from: now)
        let candidates = (0...1).flatMap { yearOffset in
            harvestMonths.compactMap { month in
                calendar.date(from: DateComponents(year: currentYear + yearOffset, month: month, day: 1, hour: 9))
            }
        }
        return candidates.filter { $0 > now }.min()
    }
}
