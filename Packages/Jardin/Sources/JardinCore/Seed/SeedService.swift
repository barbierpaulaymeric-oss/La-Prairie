import CoreData
import Foundation

public enum SeedService {
    /// Version du catalogue livré : à incrémenter quand des fiches sont ajoutées,
    /// pour que les installations existantes reçoivent les nouveautés.
    public static let catalogVersion = 2
    static let catalogVersionKey = "seedCatalogVersion"

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

    /// Met à jour une base existante avec les fiches ajoutées au catalogue depuis
    /// l'installation : insère les espèces manquantes (par nom) et complète
    /// l'emprise au sol des fiches livrées non modifiées par l'utilisateur.
    /// Idempotent ; ne touche jamais aux fiches personnalisées ni créées par l'utilisateur.
    @discardableResult
    public static func updateBuiltInCatalog(in context: NSManagedObjectContext,
                                            defaults: UserDefaults = .standard) -> Int {
        guard defaults.integer(forKey: catalogVersionKey) < catalogVersion else { return 0 }

        let request = NSFetchRequest<PlantSpeciesMO>(entityName: "PlantSpecies")
        let existing = (try? context.fetch(request)) ?? []

        func find(_ name: String) -> PlantSpeciesMO? {
            existing.first {
                ($0.commonName ?? "").compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
        }

        var inserted = 0
        for seed in SpeciesCatalog.all {
            if let current = find(seed.commonName) {
                if current.isBuiltIn, !current.isUserModified, current.spreadM <= 0 {
                    current.spreadM = seed.spreadM
                }
            } else {
                insert(seed, in: context)
                inserted += 1
            }
        }
        if context.hasChanges { try? context.save() }
        defaults.set(catalogVersion, forKey: catalogVersionKey)
        return inserted
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
        species.spreadM = seed.spreadM
        species.companions = seed.companions
        species.antagonists = seed.antagonists
        species.averageYieldKg = seed.averageYieldKg
        species.infoNotes = seed.notes
        species.isBuiltIn = true
        species.isUserModified = false
        return species
    }
}
