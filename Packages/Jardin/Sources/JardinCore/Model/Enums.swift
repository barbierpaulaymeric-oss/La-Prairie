import Foundation

public enum PlantCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case aromatique
    case potager
    case fruitier
    case fleur
    case autre

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .aromatique: return "Aromatique"
        case .potager: return "Potager"
        case .fruitier: return "Fruitier"
        case .fleur: return "Fleur"
        case .autre: return "Autre"
        }
    }

    public var systemImage: String {
        switch self {
        case .aromatique: return "leaf"
        case .potager: return "carrot"
        case .fruitier: return "tree"
        case .fleur: return "camera.macro"
        case .autre: return "sparkles"
        }
    }

    /// Emprise au sol par défaut (diamètre en mètres) quand la fiche n'en précise pas.
    public var defaultSpreadM: Double {
        switch self {
        case .aromatique: return 0.35
        case .potager: return 0.5
        case .fruitier: return 3.0
        case .fleur: return 0.3
        case .autre: return 0.4
        }
    }
}

public enum WaterNeed: String, CaseIterable, Codable, Identifiable, Sendable {
    case faible
    case moyen
    case eleve

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .faible: return "Faible"
        case .moyen: return "Moyen"
        case .eleve: return "Élevé"
        }
    }

    /// Intervalle d'arrosage de base en jours, avant ajustement météo.
    public var baseWateringIntervalDays: Int {
        switch self {
        case .faible: return 7
        case .moyen: return 4
        case .eleve: return 2
        }
    }
}

public enum SunNeed: String, CaseIterable, Codable, Identifiable, Sendable {
    case ombre
    case miOmbre
    case soleil

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .ombre: return "Ombre"
        case .miOmbre: return "Mi-ombre"
        case .soleil: return "Plein soleil"
        }
    }
}

public enum ZoneKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case potager
    case aromatiques
    case verger
    case serre
    case massif
    case autre

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .potager: return "Potager"
        case .aromatiques: return "Aromatiques"
        case .verger: return "Verger"
        case .serre: return "Serre"
        case .massif: return "Massif"
        case .autre: return "Autre"
        }
    }

    public var defaultColorHex: String {
        switch self {
        case .potager: return "#2E8B57"
        case .aromatiques: return "#556B2F"
        case .verger: return "#90EE90"
        case .serre: return "#DEB887"
        case .massif: return "#8FBC8F"
        case .autre: return "#F5F5DC"
        }
    }
}

public enum InsightKind: String, CaseIterable, Codable, Sendable {
    case baisseRendement
    case comparaisonZone
    case tendanceObservations
    case santeEnDeclin
    case meteo
    case info
}

public enum InsightSeverity: Int16, CaseIterable, Codable, Sendable {
    case info = 0
    case attention = 1
    case alerte = 2

    public var label: String {
        switch self {
        case .info: return "Info"
        case .attention: return "Attention"
        case .alerte: return "Alerte"
        }
    }
}

public enum LearningSource: String, CaseIterable, Codable, Sendable {
    case identification
    case correction
    case manuelle

    public var label: String {
        switch self {
        case .identification: return "Identification validée"
        case .correction: return "Correction utilisateur"
        case .manuelle: return "Ajout manuel"
        }
    }
}

public enum GrowthStage: String, CaseIterable, Codable, Sendable {
    case jeunePousse
    case croissance
    case mature
    case senescent

    public var label: String {
        switch self {
        case .jeunePousse: return "Jeune pousse"
        case .croissance: return "En croissance"
        case .mature: return "Mature"
        case .senescent: return "Sénescent"
        }
    }
}

/// Tags proposés par défaut pour les observations ; l'utilisateur peut en créer d'autres.
public enum ObservationTags {
    public static let presets: [String] = [
        "jaunissement", "taches", "maladie", "parasites",
        "flétrissement", "croissance rapide", "croissance lente",
        "floraison", "fructification", "récolte record",
        "sol sec", "excès d'eau",
    ]
}

public enum ConservationMethods {
    public static let presets: [String] = [
        "Frais", "Séchage", "Congélation", "Lacto-fermentation",
        "Stérilisation (bocaux)", "Confiture", "Cave / silo", "Sirop",
    ]
}

public enum Months {
    public static let shortLabels = ["Jan", "Fév", "Mar", "Avr", "Mai", "Juin",
                                     "Juil", "Août", "Sep", "Oct", "Nov", "Déc"]

    public static func label(for month: Int) -> String {
        guard (1...12).contains(month) else { return "?" }
        return shortLabels[month - 1]
    }

    /// Encode une liste de mois (1–12) en chaîne stockable ("6,7,8").
    public static func encode(_ months: [Int]) -> String {
        months.sorted().map(String.init).joined(separator: ",")
    }

    public static func decode(_ raw: String?) -> [Int] {
        guard let raw, !raw.isEmpty else { return [] }
        return raw.split(separator: ",").compactMap { Int($0) }.filter { (1...12).contains($0) }
    }
}
