import CoreData
import Foundation

public enum SeedService {
    /// Insère le catalogue d'espèces au premier lancement (idempotent).
    @discardableResult
    public static func seedSpeciesIfNeeded(in context: NSManagedObjectContext) -> Int {
        let countRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PlantSpecies")
        let existing = (try? context.count(for: countRequest)) ?? 0
        guard existing == 0 else { return 0 }

        for seed in SpeciesCatalog.all {
            insert(seed, in: context)
        }
        try? context.save()
        return SpeciesCatalog.all.count
    }

    @discardableResult
    public static func insert(_ seed: SpeciesSeed, in context: NSManagedObjectContext) -> PlantSpeciesMO {
        let species = PlantSpeciesMO(context: context)
        species.commonName = seed.commonName
        species.scientificName = seed.scientificName
        species.category = seed.category
        species.waterNeed = seed.water
        species.sunNeed = seed.sun
        species.soil = seed.soil
        species.propagation = seed.propagation
        species.conservation = seed.conservation
        species.sowingMonths = seed.sowingMonths
        species.harvestMonths = seed.harvestMonths
        species.lifespanYears = seed.lifespanYears
        species.companions = seed.companions
        species.antagonists = seed.antagonists
        species.averageYieldKg = seed.averageYieldKg
        species.infoNotes = seed.notes
        species.isBuiltIn = true
        species.isUserModified = false
        return species
    }
}
