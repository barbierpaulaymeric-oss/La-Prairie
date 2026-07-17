import CoreData
import Foundation

public enum ExportError: LocalizedError {
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Échec de l'export : \(detail)"
        }
    }
}

public struct PlantExportDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let species: String?
    public let scientificName: String?
    public let category: String
    public let zone: String?
    public let plantedDate: Date?
    public let waterNeed: String
    public let sunNeed: String
    public let soil: String
    public let notes: String?
}

public struct HarvestExportDTO: Codable, Sendable {
    public let id: UUID
    public let plant: String
    public let species: String?
    public let zone: String?
    public let date: Date
    public let quantityKg: Double
    public let quality: Int
    public let conservationMethod: String?
    public let notes: String?
}

/// Manifeste du dataset d'apprentissage exporté ; consommé par
/// `MLTraining/retrain_from_export.py` pour réentraîner un modèle ailleurs.
public struct LearningManifest: Codable, Sendable {
    public struct Example: Codable, Sendable {
        public let id: UUID
        public let label: String
        public let tags: [String]
        public let source: String
        public let createdAt: Date
        public let imageFile: String?
        public let featurePrintBase64: String?
    }

    public let version: Int
    public let exportDate: Date
    public let appIdentifier: String
    public let examples: [Example]
}

public enum ExportService {
    // MARK: CSV

    public static func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    static func csvLine(_ fields: [String]) -> String {
        fields.map(csvEscape).joined(separator: ",")
    }

    static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    public static func plantsCSV(_ plants: [PlantExportDTO]) -> String {
        var lines = [csvLine(["id", "nom", "espece", "nom_scientifique", "categorie", "zone",
                              "date_plantation", "besoin_eau", "besoin_lumiere", "sol", "notes"])]
        for plant in plants {
            lines.append(csvLine([
                plant.id.uuidString, plant.name, plant.species ?? "", plant.scientificName ?? "",
                plant.category, plant.zone ?? "",
                plant.plantedDate.map(isoFormatter.string(from:)) ?? "",
                plant.waterNeed, plant.sunNeed, plant.soil, plant.notes ?? "",
            ]))
        }
        return lines.joined(separator: "\n")
    }

    public static func harvestsCSV(_ harvests: [HarvestExportDTO]) -> String {
        var lines = [csvLine(["id", "plante", "espece", "zone", "date", "quantite_kg",
                              "qualite", "conservation", "notes"])]
        for harvest in harvests {
            lines.append(csvLine([
                harvest.id.uuidString, harvest.plant, harvest.species ?? "", harvest.zone ?? "",
                isoFormatter.string(from: harvest.date),
                String(format: "%.3f", harvest.quantityKg),
                harvest.quality > 0 ? String(harvest.quality) : "",
                harvest.conservationMethod ?? "", harvest.notes ?? "",
            ]))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: JSON

    static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    public static func json<T: Encodable>(_ value: T) throws -> Data {
        try jsonEncoder.encode(value)
    }

    // MARK: Construction des DTO depuis Core Data

    public static func plantDTOs(in context: NSManagedObjectContext) -> [PlantExportDTO] {
        let request = NSFetchRequest<PlantMO>(entityName: "Plant")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let plants = (try? context.fetch(request)) ?? []
        return plants.map { plant in
            PlantExportDTO(id: plant.id ?? UUID(),
                           name: plant.displayName,
                           species: plant.species?.commonName,
                           scientificName: plant.species?.scientificName,
                           category: plant.category.label,
                           zone: plant.zone?.name,
                           plantedDate: plant.plantedDate,
                           waterNeed: plant.effectiveWaterNeed.label,
                           sunNeed: plant.effectiveSunNeed.label,
                           soil: plant.effectiveSoil,
                           notes: plant.notes)
        }
    }

    public static func harvestDTOs(in context: NSManagedObjectContext) -> [HarvestExportDTO] {
        let request = NSFetchRequest<HarvestMO>(entityName: "Harvest")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let harvests = (try? context.fetch(request)) ?? []
        return harvests.compactMap { harvest in
            guard let date = harvest.date else { return nil }
            return HarvestExportDTO(id: harvest.id ?? UUID(),
                                    plant: harvest.plant?.displayName ?? "",
                                    species: harvest.plant?.species?.commonName,
                                    zone: harvest.plant?.zone?.name,
                                    date: date,
                                    quantityKg: harvest.quantityKg,
                                    quality: Int(harvest.quality),
                                    conservationMethod: harvest.conservationMethod,
                                    notes: harvest.notes)
        }
    }

    // MARK: Dataset d'apprentissage

    public static func makeLearningManifest(examples: [LearningExampleMO],
                                            includeImages: Bool) -> LearningManifest {
        LearningManifest(
            version: 1,
            exportDate: Date(),
            appIdentifier: "jardin-intelligent",
            examples: examples.map { example in
                LearningManifest.Example(
                    id: example.id ?? UUID(),
                    label: example.label ?? "inconnu",
                    tags: example.tags,
                    source: example.source.rawValue,
                    createdAt: example.createdAt ?? Date(),
                    imageFile: includeImages && example.photoData != nil
                        ? "images/\((example.id ?? UUID()).uuidString).jpg" : nil,
                    featurePrintBase64: example.featurePrintData?.base64EncodedString()
                )
            }
        )
    }

    /// Écrit le dataset complet (manifest.json + images/) dans un dossier daté et
    /// retourne son URL, prête à être partagée.
    public static func exportLearningDataset(in context: NSManagedObjectContext,
                                             to baseDirectory: URL) throws -> URL {
        let request = NSFetchRequest<LearningExampleMO>(entityName: "LearningExample")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let examples = (try? context.fetch(request)) ?? []

        let dateStamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let folder = baseDirectory.appendingPathComponent("JardinApprentissage-\(dateStamp)")
        let imagesFolder = folder.appendingPathComponent("images")
        do {
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        } catch {
            throw ExportError.writeFailed(error.localizedDescription)
        }

        let manifest = makeLearningManifest(examples: examples, includeImages: true)
        try json(manifest).write(to: folder.appendingPathComponent("manifest.json"))

        for example in examples {
            guard let data = example.photoData, let id = example.id else { continue }
            try data.write(to: imagesFolder.appendingPathComponent("\(id.uuidString).jpg"))
        }
        return folder
    }

    /// Importe un dataset exporté (fusion par identifiant, idempotent).
    @discardableResult
    public static func importLearningDataset(from folder: URL,
                                             in context: NSManagedObjectContext) throws -> Int {
        let manifestURL = folder.appendingPathComponent("manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(LearningManifest.self, from: data)

        let existingRequest = NSFetchRequest<LearningExampleMO>(entityName: "LearningExample")
        let existingIDs = Set(((try? context.fetch(existingRequest)) ?? []).compactMap(\.id))

        var imported = 0
        for entry in manifest.examples where !existingIDs.contains(entry.id) {
            let example = LearningExampleMO(context: context)
            example.id = entry.id
            example.createdAt = entry.createdAt
            example.label = entry.label
            example.tags = entry.tags
            example.sourceRaw = entry.source
            example.featurePrintData = entry.featurePrintBase64.flatMap { Data(base64Encoded: $0) }
            if let imageFile = entry.imageFile {
                let imageURL = folder.appendingPathComponent(imageFile)
                if let imageData = try? Data(contentsOf: imageURL) {
                    example.photoData = imageData
                    if let cg = ImageUtils.cgImage(fromJPEGData: imageData),
                       let stored = ImageUtils.makeStoredPhoto(fromCGImage: cg) {
                        example.thumbnailData = stored.thumbnail
                    }
                }
            }
            imported += 1
        }
        if context.hasChanges { try context.save() }
        return imported
    }
}
