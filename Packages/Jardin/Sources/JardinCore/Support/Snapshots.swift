import CoreData
import Foundation

/// Instantanés immuables des entités, pour alimenter les services purs
/// (analyses, planification, notifications) sans dépendre d'un contexte Core Data.

public struct PlantSnapshot: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let speciesName: String?
    public let category: PlantCategory
    public let zoneName: String?
    public let waterNeed: WaterNeed
    public let wateringIntervalDays: Int
    public let notificationsEnabled: Bool
    public let harvestMonths: [Int]
    public let averageYieldKg: Double
    public let plantedDate: Date?

    public init(id: UUID, name: String, speciesName: String?, category: PlantCategory,
                zoneName: String?, waterNeed: WaterNeed, wateringIntervalDays: Int,
                notificationsEnabled: Bool, harvestMonths: [Int], averageYieldKg: Double,
                plantedDate: Date?) {
        self.id = id
        self.name = name
        self.speciesName = speciesName
        self.category = category
        self.zoneName = zoneName
        self.waterNeed = waterNeed
        self.wateringIntervalDays = wateringIntervalDays
        self.notificationsEnabled = notificationsEnabled
        self.harvestMonths = harvestMonths
        self.averageYieldKg = averageYieldKg
        self.plantedDate = plantedDate
    }

    public init(_ plant: PlantMO) {
        self.init(
            id: plant.id ?? UUID(),
            name: plant.displayName,
            speciesName: plant.species?.commonName,
            category: plant.category,
            zoneName: plant.zone?.name,
            waterNeed: plant.effectiveWaterNeed,
            wateringIntervalDays: plant.wateringIntervalDays,
            notificationsEnabled: plant.notificationsEnabled,
            harvestMonths: plant.species?.harvestMonths ?? [],
            averageYieldKg: plant.species?.averageYieldKg ?? 0,
            plantedDate: plant.plantedDate
        )
    }
}

public struct HarvestSnapshot: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let plantID: UUID
    public let plantName: String
    public let speciesName: String?
    public let zoneName: String?
    public let date: Date
    public let quantityKg: Double
    public let quality: Int

    public init(id: UUID, plantID: UUID, plantName: String, speciesName: String?,
                zoneName: String?, date: Date, quantityKg: Double, quality: Int) {
        self.id = id
        self.plantID = plantID
        self.plantName = plantName
        self.speciesName = speciesName
        self.zoneName = zoneName
        self.date = date
        self.quantityKg = quantityKg
        self.quality = quality
    }

    public init?(_ harvest: HarvestMO) {
        guard let plant = harvest.plant, let date = harvest.date else { return nil }
        self.init(
            id: harvest.id ?? UUID(),
            plantID: plant.id ?? UUID(),
            plantName: plant.displayName,
            speciesName: plant.species?.commonName,
            zoneName: plant.zone?.name,
            date: date,
            quantityKg: harvest.quantityKg,
            quality: Int(harvest.quality)
        )
    }
}

public struct ObservationSnapshot: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let plantID: UUID
    public let plantName: String
    public let date: Date
    public let tags: [String]
    public let healthScore: Double
    public let detectedIssues: [String]

    public init(id: UUID, plantID: UUID, plantName: String, date: Date,
                tags: [String], healthScore: Double, detectedIssues: [String]) {
        self.id = id
        self.plantID = plantID
        self.plantName = plantName
        self.date = date
        self.tags = tags
        self.healthScore = healthScore
        self.detectedIssues = detectedIssues
    }

    public init?(_ observation: ObservationMO) {
        guard let plant = observation.plant, let date = observation.date else { return nil }
        self.init(
            id: observation.id ?? UUID(),
            plantID: plant.id ?? UUID(),
            plantName: plant.displayName,
            date: date,
            tags: observation.tags,
            healthScore: observation.healthScore,
            detectedIssues: observation.detectedIssues
        )
    }
}

/// Résultat d'analyse ML d'une photo, produit par `JardinML` et persisté par `JardinCore`.
/// Ce type valeur est la frontière entre les deux modules.
public struct ObservationAnalysis: Sendable {
    public var mlLabel: String?
    public var mlConfidence: Double
    public var healthScore: Double
    public var detectedIssues: [String]
    public var foregroundAreaRatio: Double
    public var featurePrint: Data?

    public init(mlLabel: String? = nil, mlConfidence: Double = 0, healthScore: Double = -1,
                detectedIssues: [String] = [], foregroundAreaRatio: Double = 0,
                featurePrint: Data? = nil) {
        self.mlLabel = mlLabel
        self.mlConfidence = mlConfidence
        self.healthScore = healthScore
        self.detectedIssues = detectedIssues
        self.foregroundAreaRatio = foregroundAreaRatio
        self.featurePrint = featurePrint
    }
}

public struct InsightDraft: Hashable, Sendable {
    public let kind: InsightKind
    public let severity: InsightSeverity
    public let message: String
    public let plantID: UUID?
    /// Clé stable identifiant le sujet de l'analyse (ex : "baisse-<plantID>-2026"),
    /// pour ne pas recréer la même suggestion à chaque recalcul.
    public let dedupeKey: String

    public init(kind: InsightKind, severity: InsightSeverity, message: String,
                plantID: UUID?, dedupeKey: String) {
        self.kind = kind
        self.severity = severity
        self.message = message
        self.plantID = plantID
        self.dedupeKey = dedupeKey
    }
}
