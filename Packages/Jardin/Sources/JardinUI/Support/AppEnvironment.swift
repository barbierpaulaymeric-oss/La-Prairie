import JardinCore
import JardinML
import SwiftUI

/// Racine de composition : stores (réel et démo), identifieur ML partagé,
/// préférences globales. Injecté en `environmentObject` à la racine.
@MainActor
public final class AppEnvironment: ObservableObject {
    public static let demoModeKey = "demoModeEnabled"
    public static let notificationsKey = "notificationsGloballyEnabled"
    public static let weatherKey = "weatherEnabled"

    @Published public var demoMode: Bool {
        didSet { UserDefaults.standard.set(demoMode, forKey: Self.demoModeKey) }
    }

    @Published public var lastWeather: WeatherSummary?

    public let liveStore: GardenStore
    public private(set) lazy var demoStore = GardenStore(persistence: .demo)

    public var store: GardenStore { demoMode ? demoStore : liveStore }

    /// Identifieur composite unique (le chargement du modèle Core ML est coûteux).
    public let identifier: CompositePlantIdentifier

    public let weatherProvider: WeatherProviding

    public init(persistence: PersistenceController = .shared) {
        self.demoMode = UserDefaults.standard.bool(forKey: Self.demoModeKey)
        self.liveStore = GardenStore(persistence: persistence)
        self.identifier = CompositePlantIdentifier(
            configuration: .init(remoteAPI: RemoteAPIConfiguration.fromDefaults())
        )
        self.weatherProvider = WeatherProviderFactory.make()
        SeedService.seedSpeciesIfNeeded(in: persistence.container.viewContext)
    }

    /// À appeler quand les réglages de l'API distante changent.
    public func reloadRemoteAPIConfiguration() {
        identifier.configuration.remoteAPI = RemoteAPIConfiguration.fromDefaults()
    }

    /// Rafraîchit météo, notifications et analyses — appelé au lancement et
    /// au retour au premier plan.
    public func performDailyRefresh() async {
        var rainTomorrow: Double?
        if UserDefaults.standard.bool(forKey: Self.weatherKey),
           let coordinate = await LocationService.shared.currentCoordinate() {
            lastWeather = await weatherProvider.summary(latitude: coordinate.latitude,
                                                        longitude: coordinate.longitude)
            rainTomorrow = lastWeather?.rainProbabilityTomorrow
        }
        await store.refreshInsights()
        await store.refreshNotificationSchedules(rainProbabilityTomorrow: rainTomorrow)
    }
}
