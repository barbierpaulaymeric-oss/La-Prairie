import Foundation
import JardinCore

/// Estimation de croissance entre deux photos d'une même plante, à partir de la
/// surface de premier plan (part de l'image occupée par le sujet). Approximation
/// honnête : le message reste prudent et n'est produit que si les deux mesures
/// sont exploitables.
public enum GrowthAnalyzer {
    public struct Comparison: Sendable, Equatable {
        /// Variation relative de surface en % (ex : +15) ; `nil` si non quantifiable.
        public let areaChangePercent: Double?
        public let message: String
    }

    public static func compare(previousRatio: Double, currentRatio: Double,
                               daysBetween: Int? = nil) -> Comparison {
        guard previousRatio > 0.01, currentRatio > 0.005 else {
            return Comparison(areaChangePercent: nil,
                              message: "Croissance non quantifiable (cadrages trop différents).")
        }
        let change = (currentRatio - previousRatio) / previousRatio * 100
        let bounded = max(min(change, 300), -90)
        let interval = daysBetween.map { " en \($0) jours" } ?? " depuis la dernière photo"

        let message: String
        switch bounded {
        case 5...:
            message = "La plante a grandi d'environ \(Int(bounded)) % (surface visible)\(interval)."
        case ..<(-5):
            message = "La surface visible a diminué d'environ \(Int(abs(bounded))) %\(interval) — taille, récolte ou stress ?"
        default:
            message = "Croissance stable\(interval)."
        }
        return Comparison(areaChangePercent: bounded, message: message)
    }

    /// Stade de croissance estimé à partir de l'âge et de la durée de vie de l'espèce.
    /// Heuristique volontairement simple, affichée comme telle dans l'interface.
    public static func estimateStage(ageDays: Int?, lifespanYears: Double) -> GrowthStage {
        guard let ageDays, ageDays >= 0, lifespanYears > 0 else { return .croissance }
        let lifeRatio = Double(ageDays) / (lifespanYears * 365.25)
        switch lifeRatio {
        case ..<0.12: return .jeunePousse
        case ..<0.5: return .croissance
        case ..<0.85: return .mature
        default: return .senescent
        }
    }
}
