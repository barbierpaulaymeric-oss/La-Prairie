import Foundation
import JardinCore

/// Critères de filtrage avancé de la liste des plantes.
/// Le filtrage s'applique en mémoire (jardin personnel = volumes faibles),
/// ce qui permet de croiser champs, relations et texte libre simplement.
public struct PlantFilter: Equatable {
    public var searchText = ""
    public var category: PlantCategory?
    public var waterNeed: WaterNeed?
    public var sunNeed: SunNeed?
    public var harvestMonth: Int?
    public var zoneName: String?
    public var tag: String?
    public var onlyWithIssues = false
    public var includeArchived = false

    public init() {}

    public var isActive: Bool {
        category != nil || waterNeed != nil || sunNeed != nil || harvestMonth != nil
            || zoneName != nil || tag != nil || onlyWithIssues || includeArchived
    }

    public func matches(_ plant: PlantMO) -> Bool {
        if !includeArchived, plant.archived { return false }
        if let category, plant.category != category { return false }
        if let waterNeed, plant.effectiveWaterNeed != waterNeed { return false }
        if let sunNeed, plant.effectiveSunNeed != sunNeed { return false }
        if let harvestMonth, !(plant.species?.harvestMonths.contains(harvestMonth) ?? false) { return false }
        if let zoneName, plant.zone?.name != zoneName { return false }
        if let tag {
            let allTags = plant.observationList.flatMap(\.tags)
            if !allTags.contains(where: { $0.compare(tag, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) {
                return false
            }
        }
        if onlyWithIssues, !hasRecentIssue(plant) { return false }
        if !searchText.isEmpty, !matchesText(plant) { return false }
        return true
    }

    /// Problème « récent » : santé < 70 % ou problème détecté sur les 60 derniers jours.
    func hasRecentIssue(_ plant: PlantMO) -> Bool {
        let cutoff = Date().addingTimeInterval(-60 * 86400)
        return plant.observationList.contains { observation in
            guard let date = observation.date, date >= cutoff else { return false }
            let unhealthy = observation.hasHealthScore && observation.healthScore < 0.7
            return unhealthy || !observation.detectedIssues.isEmpty
        }
    }

    func matchesText(_ plant: PlantMO) -> Bool {
        let haystacks: [String] = [
            plant.displayName,
            plant.species?.commonName ?? "",
            plant.species?.scientificName ?? "",
            plant.notes ?? "",
            plant.zone?.name ?? "",
        ] + plant.observationList.flatMap { [$0.note ?? ""] + $0.tags }

        return haystacks.contains {
            $0.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    /// Suggestions d'autocomplétion : espèces et tags connus commençant par le texte saisi.
    public static func suggestions(for text: String, plants: [PlantMO]) -> [String] {
        guard text.count >= 2 else { return [] }
        var candidates = Set<String>()
        for plant in plants {
            if let species = plant.species?.commonName { candidates.insert(species) }
            candidates.insert(plant.displayName)
            for tag in plant.observationList.flatMap(\.tags) { candidates.insert(tag) }
        }
        return candidates
            .filter { $0.range(of: text, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) != nil }
            .sorted()
            .prefix(6)
            .map { $0 }
    }
}
