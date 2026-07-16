import CoreData
import XCTest
@testable import JardinCore

final class PersistenceTests: XCTestCase {
    var controller: PersistenceController!
    var context: NSManagedObjectContext { controller.container.viewContext }

    override func setUp() {
        super.setUp()
        controller = PersistenceController(inMemory: true)
    }

    func testModelLoadsAndStoresRoundTrip() throws {
        let species = SeedService.insert(SpeciesCatalog.all[0], in: context)
        let plant = PlantMO(context: context)
        plant.name = "Mon basilic"
        plant.species = species
        plant.posX = 0.3
        plant.posY = 0.7
        try context.save()

        let request = NSFetchRequest<PlantMO>(entityName: "Plant")
        let fetched = try context.fetch(request)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.displayName, "Mon basilic")
        XCTAssertEqual(fetched.first?.species?.commonName, "Basilic")
        XCTAssertNotNil(fetched.first?.id)
        XCTAssertNotNil(fetched.first?.createdAt)
    }

    func testCloudKitCompatibilityAllAttributesOptionalOrDefaulted() {
        for entity in JardinModel.shared.entities {
            for property in entity.properties {
                if let attribute = property as? NSAttributeDescription {
                    XCTAssertTrue(attribute.isOptional || attribute.defaultValue != nil,
                                  "\(entity.name!).\(attribute.name) doit être optionnel ou avoir une valeur par défaut pour CloudKit")
                }
                if let relationship = property as? NSRelationshipDescription {
                    XCTAssertNotNil(relationship.inverseRelationship,
                                    "\(entity.name!).\(relationship.name) doit avoir un inverse pour CloudKit")
                    XCTAssertNotEqual(relationship.deleteRule, .denyDeleteRule,
                                      "CloudKit n'accepte pas la règle Deny")
                }
            }
        }
    }

    func testMergePolicyIsLastWriterWinsPerProperty() {
        XCTAssertTrue(context.mergePolicy as AnyObject === NSMergeByPropertyObjectTrumpMergePolicy as AnyObject)
        XCTAssertTrue(context.automaticallyMergesChangesFromParent)
    }

    func testCascadeDeletePlantRemovesObservationsAndHarvests() throws {
        let plant = PlantMO(context: context)
        plant.name = "Tomate"
        let observation = ObservationMO(context: context)
        observation.plant = plant
        let harvest = HarvestMO(context: context)
        harvest.plant = plant
        try context.save()

        context.delete(plant)
        try context.save()

        XCTAssertEqual(try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Observation")), 0)
        XCTAssertEqual(try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Harvest")), 0)
    }

    func testDeleteZoneKeepsPlants() throws {
        let zone = GardenZoneMO(context: context)
        zone.name = "Potager"
        let plant = PlantMO(context: context)
        plant.name = "Carotte"
        plant.zone = zone
        try context.save()

        context.delete(zone)
        try context.save()

        let plants = try context.fetch(NSFetchRequest<PlantMO>(entityName: "Plant"))
        XCTAssertEqual(plants.count, 1)
        XCTAssertNil(plants.first?.zone)
    }

    func testZonePointsRoundTripAndContainment() {
        let zone = GardenZoneMO(context: context)
        zone.points = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]
        XCTAssertEqual(zone.points.count, 4)
        XCTAssertTrue(zone.contains(CGPoint(x: 0.5, y: 0.5)))
        XCTAssertFalse(zone.contains(CGPoint(x: 1.5, y: 0.5)))
    }

    func testCustomFieldsOverrideSpeciesDefaults() {
        let species = SeedService.insert(SpeciesCatalog.seed(named: "Carotte")!, in: context)
        let plant = PlantMO(context: context)
        plant.species = species
        XCTAssertEqual(plant.effectiveWaterNeed, .moyen)

        plant.customWaterNeedRaw = WaterNeed.eleve.rawValue
        XCTAssertEqual(plant.effectiveWaterNeed, .eleve)
        XCTAssertEqual(plant.wateringIntervalDays, WaterNeed.eleve.baseWateringIntervalDays)

        plant.wateringIntervalOverride = 10
        XCTAssertEqual(plant.wateringIntervalDays, 10)
    }

    @MainActor
    func testGardenStoreInsightDeduplication() {
        let store = GardenStore(persistence: controller)
        let draft = InsightDraft(kind: .info, severity: .info, message: "Test",
                                 plantID: nil, dedupeKey: "clef-stable")
        XCTAssertEqual(store.storeInsights([draft]).count, 1)
        XCTAssertEqual(store.storeInsights([draft]).count, 0, "La même clé ne doit pas être réinsérée")
    }

    @MainActor
    func testGardenStoreAssignsZoneFromPosition() {
        let store = GardenStore(persistence: controller)
        let zone = store.createZone(name: "Potager", kind: .potager,
                                    points: [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0),
                                             CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0, y: 0.5)])
        let inside = store.createPlant(name: "Radis", species: nil, position: CGPoint(x: 0.2, y: 0.2))
        let outside = store.createPlant(name: "Menthe", species: nil, position: CGPoint(x: 0.9, y: 0.9))
        XCTAssertEqual(inside.zone, zone)
        XCTAssertNil(outside.zone)
    }
}
