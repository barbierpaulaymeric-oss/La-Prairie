import Foundation
import UserNotifications

/// Notifications locales : arrosage, récoltes, alertes d'analyse.
/// Identifiants déterministes par plante pour pouvoir annuler/reprogrammer proprement.
public final class NotificationScheduler: @unchecked Sendable {
    public static let shared = NotificationScheduler()

    public enum Kind: String {
        case watering = "arrosage"
        case harvest = "recolte"
        case insight = "analyse"
    }

    private let center = UNUserNotificationCenter.current()

    public init() {}

    @discardableResult
    public func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    public func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    static func identifier(_ kind: Kind, plantID: UUID) -> String {
        "jardin.\(kind.rawValue).\(plantID.uuidString)"
    }

    /// Reprogramme arrosage + rappel de récolte pour toutes les plantes actives.
    /// À appeler après toute modification pertinente (plante, préférences, météo du matin).
    public func refreshSchedules(for plants: [PlantSnapshot],
                                 lastCareDates: [UUID: Date] = [:],
                                 rainProbabilityTomorrow: Double? = nil,
                                 globallyEnabled: Bool = true) async {
        var obsolete: [String] = []
        for plant in plants {
            obsolete.append(Self.identifier(.watering, plantID: plant.id))
            obsolete.append(Self.identifier(.harvest, plantID: plant.id))
        }
        center.removePendingNotificationRequests(withIdentifiers: obsolete)
        guard globallyEnabled else { return }

        for plant in plants where plant.notificationsEnabled {
            await scheduleWatering(for: plant,
                                   lastCare: lastCareDates[plant.id],
                                   rainProbabilityTomorrow: rainProbabilityTomorrow)
            await scheduleHarvestReminder(for: plant)
        }
    }

    func scheduleWatering(for plant: PlantSnapshot, lastCare: Date?, rainProbabilityTomorrow: Double?) async {
        let recommendation = WateringPlanner.recommendation(
            intervalDays: plant.wateringIntervalDays,
            lastCare: lastCare,
            rainProbabilityTomorrow: rainProbabilityTomorrow
        )

        let content = UNMutableNotificationContent()
        content.title = "Arrosage : \(plant.name)"
        content.body = recommendation.postponedForRain
            ? recommendation.reason
            : "C'est le moment d'arroser « \(plant.name) » (besoin \(plant.waterNeed.label.lowercased()))."
        content.sound = .default
        content.userInfo = ["plantID": plant.id.uuidString, "kind": Kind.watering.rawValue]

        let interval = max(60, recommendation.nextDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: Self.identifier(.watering, plantID: plant.id),
                                            content: content, trigger: trigger)
        try? await center.add(request)
    }

    func scheduleHarvestReminder(for plant: PlantSnapshot) async {
        guard let nextHarvest = WateringPlanner.nextHarvestMonthStart(harvestMonths: plant.harvestMonths) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Période de récolte"
        content.body = "La saison de récolte de « \(plant.name) » commence — pensez à vérifier la maturité."
        content.sound = .default
        content.userInfo = ["plantID": plant.id.uuidString, "kind": Kind.harvest.rawValue]

        let interval = max(60, nextHarvest.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: Self.identifier(.harvest, plantID: plant.id),
                                            content: content, trigger: trigger)
        try? await center.add(request)
    }

    /// Alerte immédiate issue du moteur d'analyse (ex : jaunissement récurrent détecté).
    public func notifyInsight(_ insight: InsightDraft) async {
        guard insight.severity != .info else { return }
        let content = UNMutableNotificationContent()
        content.title = insight.severity == .alerte ? "Alerte jardin" : "Conseil jardin"
        content.body = insight.message
        content.sound = insight.severity == .alerte ? .default : nil
        let request = UNNotificationRequest(identifier: "jardin.insight.\(insight.dedupeKey)",
                                            content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
        try? await center.add(request)
    }

    public func cancelAll(for plantID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.identifier(.watering, plantID: plantID),
            Self.identifier(.harvest, plantID: plantID),
        ])
    }
}
