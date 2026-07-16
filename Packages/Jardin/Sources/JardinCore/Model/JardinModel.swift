import CoreData

/// Modèle Core Data défini par code : versionnable en revue, sans bundle `.xcdatamodeld`.
/// Contraintes CloudKit respectées : tous les attributs sont optionnels ou ont une valeur
/// par défaut, toutes les relations ont un inverse, aucune contrainte d'unicité.
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
            attr("createdAt", .dateAttributeType),
            attr("updatedAt", .dateAttributeType),
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
            attr("companionsRaw", .stringAttributeType),
            attr("antagonistsRaw", .stringAttributeType),
            attr("averageYieldKg", .doubleAttributeType, default: 0.0),
            attr("infoNotes", .stringAttributeType),
            attr("isBuiltIn", .booleanAttributeType, default: true),
            attr("isUserModified", .booleanAttributeType, default: false),
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

        relate(one: plant, "species", toMany: species, "plants", deleteRule: .nullifyDeleteRule)
        relate(one: plant, "zone", toMany: zone, "plants", deleteRule: .nullifyDeleteRule)
        relate(one: observation, "plant", toMany: plant, "observations", deleteRule: .nullifyDeleteRule, inverseDeleteRule: .cascadeDeleteRule)
        relate(one: harvest, "plant", toMany: plant, "harvests", deleteRule: .nullifyDeleteRule, inverseDeleteRule: .cascadeDeleteRule)

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

    /// Crée une paire de relations inverses : `one.<toOneName>` (vers `many`) et `many.<toManyName>` (vers `one`).
    private static func relate(one: NSEntityDescription,
                               _ toOneName: String,
                               toMany many: NSEntityDescription,
                               _ toManyName: String,
                               deleteRule: NSDeleteRule,
                               inverseDeleteRule: NSDeleteRule = .nullifyDeleteRule) {
        let toOne = NSRelationshipDescription()
        toOne.name = toOneName
        toOne.destinationEntity = many
        toOne.minCount = 0
        toOne.maxCount = 1
        toOne.isOptional = true
        toOne.deleteRule = deleteRule

        let toManyRel = NSRelationshipDescription()
        toManyRel.name = toManyName
        toManyRel.destinationEntity = one
        toManyRel.minCount = 0
        toManyRel.maxCount = 0
        toManyRel.isOptional = true
        toManyRel.deleteRule = inverseDeleteRule

        toOne.inverseRelationship = toManyRel
        toManyRel.inverseRelationship = toOne

        one.properties.append(toOne)
        many.properties.append(toManyRel)
    }
}
