import CoreLocation
import Foundation

public struct WeatherSummary: Sendable, Equatable {
    public let temperatureCelsius: Double
    public let conditionDescription: String
    public let conditionSymbol: String
    public let rainProbabilityToday: Double
    public let rainProbabilityTomorrow: Double

    public init(temperatureCelsius: Double, conditionDescription: String,
                conditionSymbol: String, rainProbabilityToday: Double,
                rainProbabilityTomorrow: Double) {
        self.temperatureCelsius = temperatureCelsius
        self.conditionDescription = conditionDescription
        self.conditionSymbol = conditionSymbol
        self.rainProbabilityToday = rainProbabilityToday
        self.rainProbabilityTomorrow = rainProbabilityTomorrow
    }
}

public protocol WeatherProviding: Sendable {
    func summary(latitude: Double, longitude: Double) async -> WeatherSummary?
}

/// Implémentation neutre quand WeatherKit n'est pas disponible ou pas autorisé.
public struct NoWeatherProvider: WeatherProviding {
    public init() {}
    public func summary(latitude: Double, longitude: Double) async -> WeatherSummary? { nil }
}

#if canImport(WeatherKit)
import WeatherKit

/// WeatherKit nécessite l'entitlement idoine et un compte développeur ;
/// toute erreur (entitlement manquant, réseau) dégrade silencieusement en `nil`.
public struct WeatherKitProvider: WeatherProviding {
    public init() {}

    public func summary(latitude: Double, longitude: Double) async -> WeatherSummary? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let weather = try await WeatherKit.WeatherService.shared.weather(for: location)
            let today = weather.dailyForecast.first
            let tomorrow = weather.dailyForecast.dropFirst().first
            return WeatherSummary(
                temperatureCelsius: weather.currentWeather.temperature.converted(to: .celsius).value,
                conditionDescription: weather.currentWeather.condition.description,
                conditionSymbol: weather.currentWeather.symbolName,
                rainProbabilityToday: today?.precipitationChance ?? 0,
                rainProbabilityTomorrow: tomorrow?.precipitationChance ?? 0
            )
        } catch {
            return nil
        }
    }
}
#endif

public enum WeatherProviderFactory {
    public static func make() -> WeatherProviding {
        #if canImport(WeatherKit)
        return WeatherKitProvider()
        #else
        return NoWeatherProvider()
        #endif
    }
}

/// Accès ponctuel à la position (autorisation « pendant l'utilisation », optionnelle).
public final class LocationService: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    public static let shared = LocationService()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    public var isAuthorized: Bool {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return true
        default: return false
        }
    }

    /// Retourne la position courante, ou `nil` si refusée/indisponible. Un seul appel à la fois.
    public func currentCoordinate() async -> CLLocationCoordinate2D? {
        if continuation != nil { return nil }
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        guard isAuthorized || manager.authorizationStatus == .notDetermined else { return nil }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.first?.coordinate)
        continuation = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .notDetermined, let continuation, !isAuthorized {
            continuation.resume(returning: nil)
            self.continuation = nil
        } else if isAuthorized, continuation != nil {
            manager.requestLocation()
        }
    }
}
