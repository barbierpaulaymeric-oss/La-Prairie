import CoreData
import CoreGraphics
import Foundation

/// Façade principale sur la persistance, utilisée par les ViewModels.
/// Toutes les mutations passent par ici ; les listes SwiftUI utilisent `@FetchRequest`
/// (réactif et sans fuite), les écritures et opérations lourdes ce service.
@MainActor
public final class GardenStore: ObservableObject {
    public let persistence: PersistenceController
    public var context: NSManagedObjectContext { persistence.container.viewContext }

    @Published public var lastError: String?

    public init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    public func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            lastError = error.localizedDescription
        }
    }

    // MARK: Plantes

    @discardableResult
    public func createPlant(name: String,
                            species: PlantSpeciesMO?,
                            category: PlantCategory? = nil,
                            position: CGPoint = CGPoint(x: 0.5, y: 0.5),
                            zone: GardenZoneMO? = nil,
                            plantedDate: Date? = Date()) -> PlantMO {
        let plant = PlantMO(context: context)
        plant.name = name
        plant.species = species
        plant.category = category ?? species?.category ?? .autre
        plant.posX = position.x
        plant.posY = position.y
        plant.zone = zone ?? zoneContaining(position)
        plant.plantedDate = plantedDate
        save()
        return plant
    }

    public func movePlant(_ plant: PlantMO, to position: CGPoint) {
        plant.posX = min(max(position.x, 0), 1)
        plant.posY = min(max(position.y, 0), 1)
        plant.zone = zoneContaining(position) ?? plant.zone
        plant.updatedAt = Date()
        save()
    }

    public func deletePlant(_ plant: PlantMO) {
        if let id = plant.id { NotificationScheduler.shared.cancelAll(for: id) }
        context.delete(plant)
        save()
    }

    public func zoneContaining(_ point: CGPoint) -> GardenZoneMO? {
        let request = NSFetchRequest<GardenZoneMO>(entityName: "GardenZone")
        let zones = (try? context.fetch(request)) ?? []
        return zones.first { $0.contains(point) }
    }

    // MARK: Fiches espèces

    public func fetchSpecies(matching query: String? = nil) -> [PlantSpeciesMO] {
        let request = NSFetchRequest<PlantSpeciesMO>(entityName: "PlantSpecies")
        if let query, !query.isEmpty {
            request.predicate = NSPredicate(
                format: "commonName CONTAINS[cd] %@ OR scientificName CONTAINS[cd] %@", query, query
            )
        }
        request.sortDescriptors = [NSSortDescriptor(key: "commonName", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    public func species(named name: String) -> PlantSpeciesMO? {
        let request = NSFetchRequest<PlantSpeciesMO>(entityName: "PlantSpecies")
        request.predicate = NSPredicate(format: "commonName ==[cd] %@", name)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Retrouve une fiche par nom commun ou scientifique, sinon la crée (identification inconnue).
    public func findOrCreateSpecies(commonName: String, scientificName: String? = nil,
                                    category: PlantCategory = .autre) -> PlantSpeciesMO {
        if let existing = species(named: commonName) { return existing }
        if let scientificName {
            let request = NSFetchRequest<PlantSpeciesMO>(entityName: "PlantSpecies")
            request.predicate = NSPredicate(format: "scientificName ==[cd] %@", scientificName)
            request.fetchLimit = 1
            if let existing = try? context.fetch(request).first { return existing }
        }
        let created = PlantSpeciesMO(context: context)
        created.commonName = commonName
        created.scientificName = scientificName
        created.category = category
        created.isBuiltIn = false
        save()
        return created
    }

    public func markSpeciesModified(_ species: PlantSpeciesMO) {
        species.isUserModified = true
        save()
    }

    // MARK: Observations

    @discardableResult
    public func addObservation(to plant: PlantMO,
                               note: String?,
                               tags: [String],
                               photo: (photo: Data, thumbnail: Data)?,
                               analysis: ObservationAnalysis?) -> ObservationMO {
        let observation = ObservationMO(context: context)
        observation.plant = plant
        observation.note = note
        observation.tags = tags
        observation.photoData = photo?.photo
        observation.thumbnailData = photo?.thumbnail
        if let analysis {
            observation.mlLabel = analysis.mlLabel
            observation.mlConfidence = analysis.mlConfidence
            observation.healthScore = analysis.healthScore
            observation.detectedIssues = analysis.detectedIssues
            observation.foregroundAreaRatio = analysis.foregroundAreaRatio
        }
        plant.updatedAt = Date()
        save()
        return observation
    }

    // MARK: Récoltes

    @discardableResult
    public func addHarvest(to plant: PlantMO,
                           date: Date,
                           quantityKg: Double,
                           quality: Int,
                           conservationMethod: String?,
                           notes: String?,
                           photo: (photo: Data, thumbnail: Data)?) -> HarvestMO {
        let harvest = HarvestMO(context: context)
        harvest.plant = plant
        harvest.date = date
        harvest.quantityKg = quantityKg
        harvest.quality = Int16(quality)
        harvest.conservationMethod = conservationMethod
        harvest.notes = notes
        harvest.photoData = photo?.photo
        harvest.thumbnailData = photo?.thumbnail
        save()
        return harvest
    }

    // MARK: Zones

    @discardableResult
    public func createZone(name: String, kind: ZoneKind, points: [CGPoint],
                           soilType: String? = nil, sunExposure: SunNeed? = nil) -> GardenZoneMO {
        let zone = GardenZoneMO(context: context)
        zone.name = name
        zone.kind = kind
        zone.colorHex = kind.defaultColorHex
        zone.points = points
        zone.soilType = soilType
        zone.sunExposure = sunExposure
        save()
        return zone
    }

    public func deleteZone(_ zone: GardenZoneMO) {
        context.delete(zone)
        save()
    }

    // MARK: Apprentissage continu

    @discardableResult
    public func recordLearningExample(label: String,
                                      tags: [String],
                                      featurePrint: Data?,
                                      photo: (photo: Data, thumbnail: Data)?,
                                      source: LearningSource,
                                      plantID: UUID?) -> LearningExampleMO {
        let example = LearningExampleMO(context: context)
        example.label = label
        example.tags = tags
        example.featurePrintData = featurePrint
        example.photoData = photo?.photo
        example.thumbnailData = photo?.thumbnail
        example.source = source
        example.plantID = plantID
        save()
        return example
    }

    /// Paires (étiquette, empreinte) pour le classifieur personnel kNN.
    public func learningFeaturePrints() -> [(label: String, featurePrint: Data)] {
        let request = NSFetchRequest<LearningExampleMO>(entityName: "LearningExample")
        request.predicate = NSPredicate(format: "featurePrintData != nil AND label != nil")
        let examples = (try? context.fetch(request)) ?? []
        return examples.compactMap { example in
            guard let label = example.label, let print = example.featurePrintData else { return nil }
            return (label, print)
        }
    }

    public func learningExampleCount() -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LearningExample")
        return (try? context.count(for: request)) ?? 0
    }

    // MARK: Analyses (insights)

    /// Persiste les suggestions nouvelles (déduplication par clé) et retourne celles ajoutées.
    @discardableResult
    public func storeInsights(_ drafts: [InsightDraft]) -> [InsightDraft] {
        let request = NSFetchRequest<InsightMO>(entityName: "Insight")
        let existingKeys = Set(((try? context.fetch(request)) ?? []).compactMap(\.dedupeKey))

        var added: [InsightDraft] = []
        for draft in drafts where !existingKeys.contains(draft.dedupeKey) {
            let insight = InsightMO(context: context)
            insight.kind = draft.kind
            insight.severity = draft.severity
            insight.message = draft.message
            insight.plantID = draft.plantID
            insight.dedupeKey = draft.dedupeKey
            added.append(draft)
        }
        save()
        return added
    }

    /// Recalcule toutes les analyses à partir de l'état courant, notifie les nouvelles alertes.
    public func refreshInsights() async {
        let input = makeInsightInput()
        let drafts = InsightEngine.generate(input)
        let added = storeInsights(drafts)
        for draft in added where draft.severity == .alerte {
            await NotificationScheduler.shared.notifyInsight(draft)
        }
    }

    public func makeInsightInput() -> InsightEngine.Input {
        InsightEngine.Input(
            plants: fetchAllPlants().map(PlantSnapshot.init),
            harvests: fetchAllHarvests().compactMap(HarvestSnapshot.init),
            observations: fetchAllObservations().compactMap(ObservationSnapshot.init),
            year: Calendar.current.component(.year, from: Date())
        )
    }

    // MARK: Notifications

    public func refreshNotificationSchedules(rainProbabilityTomorrow: Double? = nil) async {
        let plants = fetchAllPlants().filter { !$0.archived }.map(PlantSnapshot.init)
        var lastCare: [UUID: Date] = [:]
        for plant in fetchAllPlants() {
            if let id = plant.id {
                lastCare[id] = plant.lastObservation?.date ?? plant.plantedDate
            }
        }
        let enabled = UserDefaults.standard.object(forKey: "notificationsGloballyEnabled") as? Bool ?? true
        await NotificationScheduler.shared.refreshSchedules(for: plants,
                                                            lastCareDates: lastCare,
                                                            rainProbabilityTomorrow: rainProbabilityTomorrow,
                                                            globallyEnabled: enabled)
    }

    // MARK: Fetch utilitaires

    public func fetchAllPlants() -> [PlantMO] {
        let request = NSFetchRequest<PlantMO>(entityName: "Plant")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    public func fetchAllHarvests() -> [HarvestMO] {
        let request = NSFetchRequest<HarvestMO>(entityName: "Harvest")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    public func fetchAllObservations() -> [ObservationMO] {
        let request = NSFetchRequest<ObservationMO>(entityName: "Observation")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    public func plant(withID id: UUID) -> PlantMO? {
        let request = NSFetchRequest<PlantMO>(entityName: "Plant")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}
