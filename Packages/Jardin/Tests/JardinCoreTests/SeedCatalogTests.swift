import CoreData
import XCTest
@testable import JardinCore

final class SeedCatalogTests: XCTestCase {
    func testCatalogEntriesAreComplete() {
        XCTAssertGreaterThanOrEqual(SpeciesCatalog.all.count, 60,
                                    "Le catalogue livré doit couvrir large")
        for seed in SpeciesCatalog.all {
            XCTAssertFalse(seed.commonName.isEmpty)
            XCTAssertFalse(seed.scientificName.isEmpty)
            XCTAssertFalse(seed.soil.isEmpty, "\(seed.commonName) : sol manquant")
            XCTAssertFalse(seed.propagation.isEmpty, "\(seed.commonName) : bouturage manquant")
            XCTAssertFalse(seed.conservation.isEmpty, "\(seed.commonName) : conservation manquante")
            XCTAssertFalse(seed.harvestMonths.isEmpty, "\(seed.commonName) : période de récolte manquante")
            XCTAssertTrue(seed.harvestMonths.allSatisfy { (1...12).contains($0) })
            XCTAssertTrue(seed.sowingMonths.allSatisfy { (1...12).contains($0) })
            XCTAssertGreaterThan(seed.lifespanYears, 0)
            XCTAssertGreaterThan(seed.spreadM, 0, "\(seed.commonName) : emprise au sol manquante")
        }
    }

    func testCatalogUpdateAddsMissingSpeciesWithoutTouchingUserData() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let defaults = UserDefaults(suiteName: "seed-tests-\(UUID().uuidString)")!

        // Base « ancienne » : deux espèces livrées sans emprise, dont une personnalisée.
        let untouched = SeedService.insert(SpeciesCatalog.all[0], in: context)
        untouched.spreadM = 0
        let customized = SeedService.insert(SpeciesCatalog.all[1], in: context)
        customized.spreadM = 0
        customized.isUserModified = true
        try context.save()

        let inserted = SeedService.updateBuiltInCatalog(in: context, defaults: defaults)
        XCTAssertEqual(inserted, SpeciesCatalog.all.count - 2)
        XCTAssertGreaterThan(untouched.spreadM, 0, "Fiche livrée non modifiée : emprise complétée")
        XCTAssertEqual(customized.spreadM, 0, "Fiche personnalisée : jamais touchée")

        XCTAssertEqual(SeedService.updateBuiltInCatalog(in: context, defaults: defaults), 0,
                       "Une fois la version enregistrée, plus aucune écriture")
    }

    func testCatalogNamesAreUnique() {
        let names = SpeciesCatalog.all.map { $0.commonName.lowercased() }
        XCTAssertEqual(names.count, Set(names).count)
    }

    func testSeedingIsIdempotent() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        XCTAssertEqual(SeedService.seedSpeciesIfNeeded(in: context), SpeciesCatalog.all.count)
        XCTAssertEqual(SeedService.seedSpeciesIfNeeded(in: context), 0)

        let count = try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "PlantSpecies"))
        XCTAssertEqual(count, SpeciesCatalog.all.count)
    }

    func testMonthsEncodingRoundTrip() {
        XCTAssertEqual(Months.decode(Months.encode([8, 6, 7])), [6, 7, 8])
        XCTAssertEqual(Months.decode(nil), [])
        XCTAssertEqual(Months.decode("13,0,5"), [5])
    }

    func testStringListRoundTrip() {
        XCTAssertEqual(StringList.decode(StringList.encode(["a", " b ", ""])), ["a", "b"])
        XCTAssertNil(StringList.encode([]))
    }

    func testDemoGardenSeedsPlantsHarvestsAndObservations() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        DemoDataService.seedDemoGarden(in: context)

        let plantCount = try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Plant"))
        let zoneCount = try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "GardenZone"))
        let harvestCount = try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Harvest"))
        let observationCount = try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Observation"))

        XCTAssertGreaterThanOrEqual(plantCount, 10)
        XCTAssertEqual(zoneCount, 3)
        XCTAssertGreaterThanOrEqual(harvestCount, 20)
        XCTAssertGreaterThanOrEqual(observationCount, 8)
    }
}
