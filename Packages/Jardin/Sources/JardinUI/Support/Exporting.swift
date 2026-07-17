import CoreData
import JardinCore
import SwiftUI
import UniformTypeIdentifiers

/// Document générique pour `fileExporter` (CSV, JSON, PDF).
public struct ExportDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.commaSeparatedText, .json, .pdf, .data] }

    public let data: Data
    public let contentType: UTType

    public init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    public init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        contentType = .data
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Rendu statique de la carte (sans gestes) pour l'export PDF/image.
public struct GardenMapSnapshotView: View {
    let zones: [GardenZoneMO]
    let plants: [PlantMO]
    let side: CGFloat

    public init(zones: [GardenZoneMO], plants: [PlantMO], side: CGFloat = 1024) {
        self.zones = zones
        self.plants = plants
        self.side = side
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#F1EEDC"))
            ForEach(zones) { zone in
                ZoneShape(points: zone.points)
                    .fill(Theme.zoneColor(zone.kind).opacity(0.22))
                ZoneShape(points: zone.points)
                    .stroke(Theme.zoneColor(zone.kind).opacity(0.8), lineWidth: 2)
                if let first = zone.points.first {
                    Text(zone.name ?? "Zone")
                        .font(.system(size: side * 0.018, weight: .semibold))
                        .foregroundStyle(Color(hex: "#556B2F"))
                        .position(x: first.x * side, y: max(first.y * side - side * 0.02, 10))
                }
            }
            ForEach(plants) { plant in
                VStack(spacing: 2) {
                    PlantIconView(plant: plant, size: side * 0.05)
                        .padding(side * 0.006)
                        .background(.white.opacity(0.9), in: Circle())
                    Text(plant.displayName)
                        .font(.system(size: side * 0.014))
                        .lineLimit(1)
                }
                .position(x: plant.posX * side, y: plant.posY * side)
            }
            VStack {
                Spacer()
                HStack {
                    Text("Jardin Intelligent — \(Date().formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: side * 0.014))
                        .foregroundStyle(.secondary)
                        .padding(8)
                    Spacer()
                }
            }
        }
        .frame(width: side, height: side)
    }
}

public enum MapPDFExporter {
    /// Rend la carte en PDF vectoriel via `ImageRenderer`.
    @MainActor
    public static func pdfData(zones: [GardenZoneMO], plants: [PlantMO], side: CGFloat = 1024) -> Data? {
        let renderer = ImageRenderer(content: GardenMapSnapshotView(zones: zones, plants: plants, side: side))
        renderer.proposedSize = ProposedViewSize(width: side, height: side)

        let pdfData = NSMutableData()
        renderer.render { size, renderInContext in
            var mediaBox = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }
            context.beginPDFPage(nil)
            renderInContext(context)
            context.endPDFPage()
            context.closePDF()
        }
        return pdfData.length > 0 ? pdfData as Data : nil
    }
}
