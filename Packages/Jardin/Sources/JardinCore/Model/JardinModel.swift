import CoreData

/// Modèle Core Data défini par code : versionnable en revue, sans bundle `.xcdatamodeld`.
/// Contraintes CloudKit respectées : tous les attributs sont optionnels ou ont une valeur
/// par défaut, toutes les relations ont un inverse, aucune contrainte d'unicité.
///
/// Ordre de construction important : `NSEntityDescription.properties` peut copier les
/// descriptions à l'assignation — les inverses sont donc câblés **après** installation,
/// sur les instances effectivement installées (`relationshipsByName`), sinon la
/// propagation des suppressions laisse des références pendantes (crash).
public enum JardinModel {
    public static let shared: NSManagedObjectModel = build()

    static func build() -> NSManagedObjectModel {
        let plant = entity("Plant", class: PlantMO.self)
        let species = entity("PlantSpecies", class: PlantSpeciesMO.self)
        let observation = entity("Observation", class: ObservationMO.self)
        let harvest = entity("Harvest", class: HarvestMO.self)
        let zone = entity("GardenZone", class: GardenZoneMO.self)
        let example = entity("LearningExample", class: LearningExampleMO.self)
        let insight = entity("Insight", class: InsightMO.self)

        plant.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType),
            attr("categoryRaw", .stringAttributeType),
            attr("plantedDate", .dateAttributeType),
            attr("posX", .doubleAttributeType, default: 0.5),
            attr("posY", .doubleAttributeType, default: 0.5),
            attr("notes", .stringAttributeType),
            attr("iconName", .stringAttributeType),
            attr("archived", .booleanAttributeType, default: false),
            attr("notificationsEnabled", .booleanAttributeType, default: true),
            attr("wateringIntervalOverride", .integer16AttributeType, default: 0),
            attr("customWaterNeedRaw", .stringAttributeType),
            attr("customSunNeedRaw", .stringAttributeType),
            attr("customSoil", .stringAttributeType),
            attr("customSpreadM", .doubleAttributeType, default: 0.0),
            attr("createdAt", .dateAttributeType),
            attr("updatedAt", .dateAttributeType),
            rel("species", to: species, toMany: false, deleteRule: .nullifyDeleteRule),
            // « zone » est interdit : collision avec -[NSObject zone] (voir PlantMO).
            rel("inZone", to: zone, toMany: false, deleteRule: .nullifyDeleteRule,
                renamedFrom: "zone"),
            rel("observations", to: observation, toMany: true, deleteRule: .cascadeDeleteRule),
            rel("harvests", to: harvest, toMany: true, deleteRule: .cascadeDeleteRule),
        ]

        species.properties = [
            attr("id", .UUIDAttributeType),
            attr("commonName", .stringAttributeType),
            attr("scientificName", .stringAttributeType),
            attr("categoryRaw", .stringAttributeType),
            attr("waterNeedRaw", .stringAttributeType),
            attr("sunNeedRaw", .stringAttributeType),
            attr("soil", .stringAttributeType),
            attr("propagation", .stringAttributeType),
            attr("conservation", .stringAttributeType),
            attr("sowingMonthsRaw", .stringAttributeType),
            attr("harvestMonthsRaw", .stringAttributeType),
            attr("lifespanYears", .doubleAttributeType, default: 1.0),
            attr("spreadM", .doubleAttributeType, default: 0.0),
            attr("companionsRaw", .stringAttributeType),
            attr("antagonistsRaw", .stringAttributeType),
            attr("averageYieldKg", .doubleAttributeType, default: 0.0),
            attr("infoNotes", .stringAttributeType),
            attr("isBuiltIn", .booleanAttributeType, default: true),
            attr("isUserModified", .booleanAttributeType, default: false),
            rel("plants", to: plant, toMany: true, deleteRule: .nullifyDeleteRule),
        ]

        observation.properties = [
            attr("id", .UUIDAttributeType),
            attr("date", .dateAttributeType),
            attr("note", .stringAttributeType),
            attr("tagsRaw", .stringAttributeType),
            attr("photoData", .binaryDataAttributeType, external: true),
            attr("thumbnailData", .binaryDataAttributeType),
            attr("healthScore", .doubleAttributeType, default: -1.0),
            attr("detectedIssuesRaw", .stringAttributeType),
            attr("mlLabel", .stringAttributeType),
            attr("mlConfidence", .doubleAttributeType, default: 0.0),
            attr("correctedLabel", .stringAttributeType),
            attr("foregroundAreaRatio", .doubleAttributeType, default: 0.0),
            rel("plant", to: plant, toMany: false, deleteRule: .nullifyDeleteRule),
        ]

        harvest.properties = [
            attr("id", .UUIDAttributeType),
            attr("date", .dateAttributeType),
            attr("quantityKg", .doubleAttributeType, default: 0.0),
            attr("quality", .integer16AttributeType, default: 0),
            attr("conservationMethod", .stringAttributeType),
            attr("notes", .stringAttributeType),
            attr("photoData", .binaryDataAttributeType, external: true),
            attr("thumbnailData", .binaryDataAttributeType),
            rel("plant", to: plant, toMany: false, deleteRule: .nullifyDeleteRule),
        ]

        zone.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType),
            attr("kindRaw", .stringAttributeType),
            attr("colorHex", .stringAttributeType),
            attr("pointsData", .binaryDataAttributeType),
            attr("soilType", .stringAttributeType),
            attr("sunExposureRaw", .stringAttributeType),
            attr("notes", .stringAttributeType),
            rel("plants", to: plant, toMany: true, deleteRule: .nullifyDeleteRule),
        ]

        example.properties = [
            attr("id", .UUIDAttributeType),
            attr("createdAt", .dateAttributeType),
            attr("label", .stringAttributeType),
            attr("tagsRaw", .stringAttributeType),
            attr("featurePrintData", .binaryDataAttributeType),
            attr("photoData", .binaryDataAttributeType, external: true),
            attr("thumbnailData", .binaryDataAttributeType),
            attr("sourceRaw", .stringAttributeType),
            attr("plantID", .UUIDAttributeType),
        ]

        insight.properties = [
            attr("id", .UUIDAttributeType),
            attr("date", .dateAttributeType),
            attr("kindRaw", .stringAttributeType),
            attr("message", .stringAttributeType),
            attr("severityRaw", .integer16AttributeType, default: 0),
            attr("plantID", .UUIDAttributeType),
            attr("dedupeKey", .stringAttributeType),
            attr("acknowledged", .booleanAttributeType, default: false),
        ]

        // Inverses : câblés sur les descriptions installées dans les entités.
        wireInverse(plant, "species", species, "plants")
        wireInverse(plant, "inZone", zone, "plants")
        wireInverse(plant, "observations", observation, "plant")
        wireInverse(plant, "harvests", harvest, "plant")

        let model = NSManagedObjectModel()
        model.entities = [plant, species, observation, harvest, zone, example, insight]
        return model
    }

    private static func entity(_ name: String, class cls: NSManagedObject.Type) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = NSStringFromClass(cls)
        return entity
    }

    private static func attr(_ name: String,
                             _ type: NSAttributeType,
                             default defaultValue: Any? = nil,
                             external: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = true
        attribute.defaultValue = defaultValue
        attribute.allowsExternalBinaryDataStorage = external
        return attribute
    }

    private static func rel(_ name: String,
                            to destination: NSEntityDescription,
                            toMany: Bool,
                            deleteRule: NSDeleteRule,
                            renamedFrom: String? = nil) -> NSRelationshipDescription {
        let relationship = NSRelationshipDescription()
        relationship.name = name
        relationship.destinationEntity = destination
        relationship.minCount = 0
        relationship.maxCount = toMany ? 0 : 1
        relationship.isOptional = true
        relationship.deleteRule = deleteRule
        relationship.renamingIdentifier = renamedFrom
        return relationship
    }

    private static func wireInverse(_ entityA: NSEntityDescription, _ nameA: String,
                                    _ entityB: NSEntityDescription, _ nameB: String) {
        guard let relA = entityA.relationshipsByName[nameA],
              let relB = entityB.relationshipsByName[nameB] else {
            preconditionFailure("Relation \(nameA)/\(nameB) absente du modèle")
        }
        relA.inverseRelationship = relB
        relB.inverseRelationship = relA
    }
}
