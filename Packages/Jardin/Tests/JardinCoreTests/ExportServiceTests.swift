import CoreData
import XCTest
@testable import JardinCore

final class ExportServiceTests: XCTestCase {
    func testCSVEscaping() {
        XCTAssertEqual(ExportService.csvEscape("simple"), "simple")
        XCTAssertEqual(ExportService.csvEscape("avec, virgule"), "\"avec, virgule\"")
        XCTAssertEqual(ExportService.csvEscape("avec \"guillemets\""), "\"avec \"\"guillemets\"\"\"")
        XCTAssertEqual(ExportService.csvEscape("avec\nretour"), "\"avec\nretour\"")
    }

    func testHarvestsCSVStructure() {
        let dto = HarvestExportDTO(id: UUID(), plant: "Tomate, cerise", species: "Tomate",
                                   zone: "Potager", date: Date(timeIntervalSince1970: 0),
                                   quantityKg: 1.25, quality: 4,
                                   conservationMethod: "Congélation", notes: nil)
        let csv = ExportService.harvestsCSV([dto])
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].hasPrefix("id,plante,espece,zone,date"))
        XCTAssertTrue(lines[1].contains("\"Tomate, cerise\""))
        XCTAssertTrue(lines[1].contains("1.250"))
        XCTAssertTrue(lines[1].contains("1970-01-01"))
    }

    func testJSONEncodingIsISO8601() throws {
        let dto = PlantExportDTO(id: UUID(), name: "Basilic", species: "Basilic",
                                 scientificName: "Ocimum basilicum", category: "Aromatique",
                                 zone: nil, plantedDate: Date(timeIntervalSince1970: 86400),
                                 waterNeed: "Élevé", sunNeed: "Plein soleil",
                                 soil: "Riche", notes: nil)
        let data = try ExportService.json([dto])
        let text = String(data: data, encoding: .utf8)!
        XCTAssertTrue(text.contains("1970-01-02T00:00:00Z"))
        XCTAssertTrue(text.contains("Ocimum basilicum"))
    }

    func testLearningDatasetExportImportRoundTrip() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let example = LearningExampleMO(context: context)
        example.label = "Basilic"
        example.tags = ["jaunissement"]
        example.source = .correction
        example.featurePrintData = Data([1, 2, 3, 4])
        example.photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        try context.save()

        let baseDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jardin-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: baseDir) }

        let folder = try ExportService.exportLearningDataset(in: context, to: baseDir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("manifest.json").path))

        // Import dans une base vierge.
        let freshController = PersistenceController(inMemory: true)
        let freshContext = freshController.container.viewContext
        let imported = try ExportService.importLearningDataset(from: folder, in: freshContext)
        XCTAssertEqual(imported, 1)

        let request = NSFetchRequest<LearningExampleMO>(entityName: "LearningExample")
        let examples = try freshContext.fetch(request)
        XCTAssertEqual(examples.first?.label, "Basilic")
        XCTAssertEqual(examples.first?.tags, ["jaunissement"])
        XCTAssertEqual(examples.first?.featurePrintData, Data([1, 2, 3, 4]))
        XCTAssertEqual(examples.first?.source, .correction)

        // Réimport : idempotent.
        XCTAssertEqual(try ExportService.importLearningDataset(from: folder, in: freshContext), 0)
    }
}
