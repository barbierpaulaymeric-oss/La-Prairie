import CoreData
import CoreGraphics
import Foundation

@objc(PlantMO)
public final class PlantMO: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var categoryRaw: String?
    @NSManaged public var plantedDate: Date?
    @NSManaged public var posX: Double
    @NSManaged public var posY: Double
    @NSManaged public var notes: String?
    @NSManaged public var iconName: String?
    @NSManaged public var archived: Bool
    @NSManaged public var notificationsEnabled: Bool
    @NSManaged public var wateringIntervalOverride: Int16
    @NSManaged public var customWaterNeedRaw: String?
    @NSManaged public var customSunNeedRaw: String?
    @NSManaged public var customSoil: String?
    @NSManaged public var customSpreadM: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var species: PlantSpeciesMO?
    /// Nom modélisé `inZone` : « zone » écraserait le sélecteur système
    /// `-[NSObject zone]` (NSZone) — crash garanti dans la machinerie Core Data.
    @NSManaged public var inZone: GardenZoneMO?
    @NSManaged public var observations: NSSet?
    @NSManaged public var harvests: NSSet?

    /// Façade Swift (sans @objc, donc sans collision de sélecteur) pour l'API naturelle.
    public var zone: GardenZoneMO? {
        get { inZone }
        set { inZone = newValue }
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        updatedAt = Date()
        posX = 0.5
        posY = 0.5
        notificationsEnabled = true
    }

    public var displayName: String {
        let n = name ?? ""
        return n.isEmpty ? (species?.commonName ?? "Plante") : n
    }

    public var category: PlantCategory {
        get { PlantCategory(rawValue: categoryRaw ?? "") ?? species?.category ?? .autre }
        set { categoryRaw = newValue.rawValue }
    }

    /// Besoin en eau effectif : la personnalisation utilisateur prime sur la fiche.
    public var effectiveWaterNeed: WaterNeed {
        if let raw = customWaterNeedRaw, let need = WaterNeed(rawValue: raw) { return need }
        return species?.waterNeed ?? .moyen
    }

    public var effectiveSunNeed: SunNeed {
        if let raw = customSunNeedRaw, let need = SunNeed(rawValue: raw) { return need }
        return species?.sunNeed ?? .soleil
    }

    public var effectiveSoil: String {
        if let soil = customSoil, !soil.isEmpty { return soil }
        return species?.soil ?? ""
    }

    public var wateringIntervalDays: Int {
        wateringIntervalOverride > 0 ? Int(wateringIntervalOverride) : effectiveWaterNeed.baseWateringIntervalDays
    }

    /// Emprise au sol (diamètre en mètres) : personnalisation > fiche > défaut de catégorie.
    public var effectiveSpreadM: Double {
        if customSpreadM > 0 { return customSpreadM }
        if let spread = species?.spreadM, spread > 0 { return spread }
        return category.defaultSpreadM
    }

    public var observationList: [ObservationMO] {
        (observations as? Set<ObservationMO> ?? []).sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    public var harvestList: [HarvestMO] {
        (harvests as? Set<HarvestMO> ?? []).sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    public var lastObservation: ObservationMO? { observationList.first }

    public func totalYieldKg(year: Int? = nil) -> Double {
        harvestList
            .filter { harvest in
                guard let year else { return true }
                guard let date = harvest.date else { return false }
                return Calendar.current.component(.year, from: date) == year
            }
            .reduce(0) { $0 + $1.quantityKg }
    }

    public var ageDescription: String? {
        guard let plantedDate else { return nil }
        let components = Calendar.current.dateComponents([.year, .month, .day], from: plantedDate, to: Date())
        if let years = components.year, years > 0 { return years == 1 ? "1 an" : "\(years) ans" }
        if let months = components.month, months > 0 { return "\(months) mois" }
        return "\(max(components.day ?? 0, 0)) jours"
    }
}

@objc(PlantSpeciesMO)
public final class PlantSpeciesMO: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var commonName: String?
    @NSManaged public var scientificName: String?
    @NSManaged public var categoryRaw: String?
    @NSManaged public var waterNeedRaw: String?
    @NSManaged public var sunNeedRaw: String?
    @NSManaged public var soil: String?
    @NSManaged public var propagation: String?
    @NSManaged public var conservation: String?
    @NSManaged public var sowingMonthsRaw: String?
    @NSManaged public var harvestMonthsRaw: String?
    @NSManaged public var lifespanYears: Double
    @NSManaged public var spreadM: Double
    @NSManaged public var companionsRaw: String?
    @NSManaged public var antagonistsRaw: String?
    @NSManaged public var averageYieldKg: Double
    @NSManaged public var infoNotes: String?
    @NSManaged public var isBuiltIn: Bool
    @NSManaged public var isUserModified: Bool
    @NSManaged public var plants: NSSet?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        isBuiltIn = false
        lifespanYears = 1
    }

    public var category: PlantCategory {
        get { PlantCategory(rawValue: categoryRaw ?? "") ?? .autre }
        set { categoryRaw = newValue.rawValue }
    }

    public var waterNeed: WaterNeed {
        get { WaterNeed(rawValue: waterNeedRaw ?? "") ?? .moyen }
        set { waterNeedRaw = newValue.rawValue }
    }

    public var sunNeed: SunNeed {
        get { SunNeed(rawValue: sunNeedRaw ?? "") ?? .soleil }
        set { sunNeedRaw = newValue.rawValue }
    }

    public var sowingMonths: [Int] {
        get { Months.decode(sowingMonthsRaw) }
        set { sowingMonthsRaw = Months.encode(newValue) }
    }

    public var harvestMonths: [Int] {
        get { Months.decode(harvestMonthsRaw) }
        set { harvestMonthsRaw = Months.encode(newValue) }
    }

    public var companions: [String] {
        get { StringList.decode(companionsRaw) }
        set { companionsRaw = StringList.encode(newValue) }
    }

    public var antagonists: [String] {
        get { StringList.decode(antagonistsRaw) }
        set { antagonistsRaw = StringList.encode(newValue) }
    }
}

@objc(ObservationMO)
public final class ObservationMO: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var note: String?
    @NSManaged public var tagsRaw: String?
    @NSManaged public var photoData: Data?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var healthScore: Double
    @NSManaged public var detectedIssuesRaw: String?
    @NSManaged public var mlLabel: String?
    @NSManaged public var mlConfidence: Double
    @NSManaged public var correctedLabel: String?
    @NSManaged public var foregroundAreaRatio: Double
    @NSManaged public var plant: PlantMO?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        date = Date()
        healthScore = -1
    }

    public var tags: [String] {
        get { StringList.decode(tagsRaw) }
        set { tagsRaw = StringList.encode(newValue) }
    }

    public var detectedIssues: [String] {
        get { StringList.decode(detectedIssuesRaw) }
        set { detectedIssuesRaw = StringList.encode(newValue) }
    }

    public var hasHealthScore: Bool { healthScore >= 0 }
}

@objc(HarvestMO)
public final class HarvestMO: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var quantityKg: Double
    @NSManaged public var quality: Int16
    @NSManaged public var conservationMethod: String?
    @NSManaged public var notes: String?
    @NSManaged public var photoData: Data?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var plant: PlantMO?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        date = Date()
    }
}

@objc(GardenZoneMO)
public final class GardenZoneMO: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var kindRaw: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var pointsData: Data?
    @NSManaged public var soilType: String?
    @NSManaged public var sunExposureRaw: String?
    @NSManaged public var notes: String?
    @NSManaged public var plants: NSSet?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }

    public var kind: ZoneKind {
        get { ZoneKind(rawValue: kindRaw ?? "") ?? .autre }
        set {
            kindRaw = newValue.rawValue
            if colorHex == nil { colorHex = newValue.defaultColorHex }
        }
    }

    public var sunExposure: SunNeed? {
        get { sunExposureRaw.flatMap(SunNeed.init(rawValue:)) }
        set { sunExposureRaw = newValue?.rawValue }
    }

    /// Sommets du polygone, en coordonnées normalisées (0…1) sur la carte.
    public var points: [CGPoint] {
        get {
            guard let pointsData,
                  let pairs = try? JSONDecoder().decode([[Double]].self, from: pointsData) else { return [] }
            return pairs.compactMap { $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil }
        }
        set {
            pointsData = try? JSONEncoder().encode(newValue.map { [Double($0.x), Double($0.y)] })
        }
    }

    public var plantList: [PlantMO] {
        (plants as? Set<PlantMO> ?? []).sorted { $0.displayName < $1.displayName }
    }

    public func contains(_ point: CGPoint) -> Bool {
        GeometryMath.polygon(points, contains: point)
    }
}

@objc(LearningExampleMO)
public final class LearningExampleMO: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var label: String?
    @NSManaged public var tagsRaw: String?
    @NSManaged public var featurePrintData: Data?
    @NSManaged public var photoData: Data?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var sourceRaw: String?
    @NSManaged public var plantID: UUID?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
    }

    public var source: LearningSource {
        get { LearningSource(rawValue: sourceRaw ?? "") ?? .manuelle }
        set { sourceRaw = newValue.rawValue }
    }

    public var tags: [String] {
        get { StringList.decode(tagsRaw) }
        set { tagsRaw = StringList.encode(newValue) }
    }
}

@objc(InsightMO)
public final class InsightMO: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var kindRaw: String?
    @NSManaged public var message: String?
    @NSManaged public var severityRaw: Int16
    @NSManaged public var plantID: UUID?
    @NSManaged public var dedupeKey: String?
    @NSManaged public var acknowledged: Bool

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        date = Date()
    }

    public var kind: InsightKind {
        get { InsightKind(rawValue: kindRaw ?? "") ?? .info }
        set { kindRaw = newValue.rawValue }
    }

    public var severity: InsightSeverity {
        get { InsightSeverity(rawValue: severityRaw) ?? .info }
        set { severityRaw = newValue.rawValue }
    }
}

/// Encodage compact de listes de chaînes dans un attribut texte (séparateur non ambigu).
public enum StringList {
    static let separator = "|"

    public static func encode(_ values: [String]) -> String? {
        let cleaned = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return cleaned.isEmpty ? nil : cleaned.joined(separator: separator)
    }

    public static func decode(_ raw: String?) -> [String] {
        guard let raw, !raw.isEmpty else { return [] }
        return raw.components(separatedBy: separator).filter { !$0.isEmpty }
    }
}

public enum GeometryMath {
    /// Test point-dans-polygone (ray casting), en coordonnées normalisées.
    public static func polygon(_ vertices: [CGPoint], contains point: CGPoint) -> Bool {
        guard vertices.count >= 3 else { return false }
        var inside = false
        var j = vertices.count - 1
        for i in 0..<vertices.count {
            let a = vertices[i], b = vertices[j]
            if (a.y > point.y) != (b.y > point.y),
               point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
}
