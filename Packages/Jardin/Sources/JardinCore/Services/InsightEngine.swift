import Foundation

/// Croise récoltes, observations et fiches pour produire des suggestions actionnables.
/// Chaque règle émet un `InsightDraft` avec une clé de déduplication stable.
public enum InsightEngine {
    public struct Input: Sendable {
        public let plants: [PlantSnapshot]
        public let harvests: [HarvestSnapshot]
        public let observations: [ObservationSnapshot]
        public let year: Int

        public init(plants: [PlantSnapshot], harvests: [HarvestSnapshot],
                    observations: [ObservationSnapshot], year: Int) {
            self.plants = plants
            self.harvests = harvests
            self.observations = observations
            self.year = year
        }
    }

    public static func generate(_ input: Input, calendar: Calendar = .current) -> [InsightDraft] {
        var drafts: [InsightDraft] = []
        drafts += yieldDropInsights(input, calendar: calendar)
        drafts += speciesAverageInsights(input, calendar: calendar)
        drafts += zoneDisparityInsights(input)
        drafts += recurringTagInsights(input)
        drafts += healthDeclineInsights(input)
        return drafts
    }

    static func yieldDropInsights(_ input: Input, calendar: Calendar) -> [InsightDraft] {
        input.plants.compactMap { plant in
            guard let change = HarvestAnalytics.yearOverYearChange(input.harvests, plantID: plant.id,
                                                                   year: input.year, calendar: calendar),
                  change <= -0.25 else { return nil }
            let percent = Int(abs(change) * 100)
            var message = "Le rendement de « \(plant.name) » est en baisse de \(percent) % par rapport à l'an dernier."
            if let correlation = correlateWithObservations(input, plantID: plant.id) {
                message += " \(correlation)"
            } else {
                message += " Vérifiez l'arrosage, l'ensoleillement ou le pH du sol."
            }
            return InsightDraft(kind: .baisseRendement,
                                severity: percent >= 40 ? .alerte : .attention,
                                message: message,
                                plantID: plant.id,
                                dedupeKey: "baisse-\(plant.id)-\(input.year)")
        }
    }

    /// Relie une baisse de rendement aux observations photo de la même saison.
    static func correlateWithObservations(_ input: Input, plantID: UUID) -> String? {
        let seasonObservations = input.observations.filter {
            $0.plantID == plantID && Calendar.current.component(.year, from: $0.date) == input.year
        }
        let tagCounts = Dictionary(grouping: seasonObservations.flatMap(\.tags).map { $0.lowercased() },
                                   by: { $0 }).mapValues(\.count)
        guard let dominant = tagCounts.max(by: { $0.value < $1.value }), dominant.value >= 2 else { return nil }
        let cause: String
        switch dominant.key {
        case "jaunissement", "sol sec": cause = "manque d'eau ou carence (azote, magnésium)"
        case "excès d'eau", "flétrissement": cause = "excès d'arrosage ou sol mal drainé"
        case "taches", "maladie": cause = "maladie foliaire (mildiou, oïdium)"
        case "parasites": cause = "pression de ravageurs"
        default: cause = "un problème récurrent signalé « \(dominant.key) »"
        }
        return "Vos photos de la saison montrent « \(dominant.key) » à \(dominant.value) reprises. Cause probable : \(cause)."
    }

    static func speciesAverageInsights(_ input: Input, calendar: Calendar) -> [InsightDraft] {
        input.plants.compactMap { plant in
            guard plant.averageYieldKg > 0 else { return nil }
            let total = input.harvests
                .filter { $0.plantID == plant.id && calendar.component(.year, from: $0.date) == input.year }
                .reduce(0) { $0 + $1.quantityKg }
            guard total > 0,
                  let deviation = HarvestAnalytics.deviationFromSpeciesAverage(totalKg: total,
                                                                               speciesAverageKg: plant.averageYieldKg),
                  deviation <= -0.2 else { return nil }
            let percent = Int(abs(deviation) * 100)
            return InsightDraft(kind: .baisseRendement,
                                severity: .info,
                                message: "« \(plant.name) » produit \(percent) % de moins que la moyenne de l'espèce (\(Formatters.kg(plant.averageYieldKg))/an). Vérifiez l'arrosage et l'exposition.",
                                plantID: plant.id,
                                dedupeKey: "moyenne-\(plant.id)-\(input.year)")
        }
    }

    static func zoneDisparityInsights(_ input: Input) -> [InsightDraft] {
        HarvestAnalytics.zoneDisparities(input.harvests).map { disparity in
            let percent = Int(disparity.relativeGap * 100)
            return InsightDraft(kind: .comparaisonZone,
                                severity: .attention,
                                message: "Vos \(disparity.speciesName.lowercased())s rendent \(percent) % de moins en « \(disparity.worstZone) » qu'en « \(disparity.bestZone) ». Vérifiez l'ensoleillement ou le pH du sol de cette zone.",
                                plantID: nil,
                                dedupeKey: "zone-\(disparity.speciesName)-\(disparity.worstZone)")
        }
    }

    static func recurringTagInsights(_ input: Input) -> [InsightDraft] {
        HarvestAnalytics.recurringTags(input.observations).map { recurring in
            let advice: String
            switch recurring.tag {
            case "jaunissement": advice = "Vérifiez l'arrosage et un éventuel manque d'azote ou de magnésium."
            case "taches", "maladie": advice = "Traitez préventivement (purin de prêle, bicarbonate) et aérez le feuillage."
            case "parasites": advice = "Inspectez le revers des feuilles et installez des auxiliaires."
            case "sol sec": advice = "Paillez et augmentez la fréquence d'arrosage."
            case "excès d'eau": advice = "Espacez les arrosages et vérifiez le drainage."
            case "flétrissement": advice = "Contrôlez l'humidité du sol matin et soir."
            default: advice = "Consultez la fiche de la plante pour ajuster son entretien."
            }
            return InsightDraft(kind: .tendanceObservations,
                                severity: .attention,
                                message: "« \(recurring.tag) » signalé \(recurring.occurrences) fois récemment sur « \(recurring.plantName) ». \(advice)",
                                plantID: recurring.plantID,
                                dedupeKey: "tag-\(recurring.plantID)-\(recurring.tag)")
        }
    }

    static func healthDeclineInsights(_ input: Input) -> [InsightDraft] {
        input.plants.compactMap { plant in
            guard let trend = HarvestAnalytics.healthTrend(input.observations, plantID: plant.id),
                  trend <= -0.2 else { return nil }
            return InsightDraft(kind: .santeEnDeclin,
                                severity: .alerte,
                                message: "L'état de « \(plant.name) » se dégrade sur vos dernières photos (score de santé en baisse de \(Int(abs(trend) * 100)) points). Une observation rapprochée est conseillée.",
                                plantID: plant.id,
                                dedupeKey: "sante-\(plant.id)-\(Int(trend * 100))")
        }
    }
}

public enum Formatters {
    public static func kg(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = value < 10 ? 1 : 0
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(number) kg"
    }

    public static func percent(_ value: Double) -> String {
        "\(value >= 0 ? "+" : "−")\(Int(abs(value) * 100)) %"
    }

    /// Longueur lisible : « 35 cm » sous le mètre, « 1,5 m » au-delà.
    public static func meters(_ value: Double) -> String {
        if value < 1 {
            return "\(Int((value * 100).rounded())) cm"
        }
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "\(Int(rounded)) m"
        }
        return String(format: "%.1f m", rounded).replacingOccurrences(of: ".", with: ",")
    }
}
