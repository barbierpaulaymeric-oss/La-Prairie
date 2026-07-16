import CoreData
import CoreGraphics
import Foundation

/// Génère un jardin de démonstration complet : zones, plantes, deux saisons de récoltes,
/// observations taguées et photos procédurales — pour explorer l'app sans données réelles.
public enum DemoDataService {
    public static func seedDemoGarden(in context: NSManagedObjectContext) {
        SeedService.seedSpeciesIfNeeded(in: context)

        func species(_ name: String) -> PlantSpeciesMO? {
            let request = NSFetchRequest<PlantSpeciesMO>(entityName: "PlantSpecies")
            request.predicate = NSPredicate(format: "commonName ==[cd] %@", name)
            request.fetchLimit = 1
            return try? context.fetch(request).first
        }

        let potager = GardenZoneMO(context: context)
        potager.name = "Potager sud"
        potager.kind = .potager
        potager.soilType = "Limono-argileux, riche"
        potager.sunExposure = .soleil
        potager.points = [CGPoint(x: 0.08, y: 0.45), CGPoint(x: 0.55, y: 0.45),
                          CGPoint(x: 0.55, y: 0.92), CGPoint(x: 0.08, y: 0.92)]

        let aromatiques = GardenZoneMO(context: context)
        aromatiques.name = "Carré d'aromatiques"
        aromatiques.kind = .aromatiques
        aromatiques.soilType = "Sec, drainé"
        aromatiques.sunExposure = .soleil
        aromatiques.points = [CGPoint(x: 0.62, y: 0.55), CGPoint(x: 0.92, y: 0.55),
                              CGPoint(x: 0.92, y: 0.9), CGPoint(x: 0.62, y: 0.9)]

        let verger = GardenZoneMO(context: context)
        verger.name = "Verger"
        verger.kind = .verger
        verger.soilType = "Profond"
        verger.sunExposure = .miOmbre
        verger.points = [CGPoint(x: 0.1, y: 0.08), CGPoint(x: 0.9, y: 0.08),
                         CGPoint(x: 0.9, y: 0.35), CGPoint(x: 0.1, y: 0.35)]

        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)

        func date(_ y: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: y, month: month, day: day)) ?? now
        }

        struct DemoPlant {
            let species: String
            let name: String
            let zone: Int
            let pos: CGPoint
            let plantedYearsAgo: Double
            /// (année relative : 0 = cette année, -1 = an dernier, mois, jour, kg, qualité)
            let harvests: [(Int, Int, Int, Double, Int)]
            /// (année relative, mois, jour, tags, note, healthScore)
            let observations: [(Int, Int, Int, [String], String, Double)]
        }

        let demoPlants: [DemoPlant] = [
            DemoPlant(species: "Tomate", name: "Tomate 'Cœur de bœuf'", zone: 0,
                      pos: CGPoint(x: 0.15, y: 0.55), plantedYearsAgo: 0.3,
                      harvests: [(-1, 7, 20, 1.8, 4), (-1, 8, 12, 2.6, 5), (-1, 9, 5, 1.4, 3),
                                 (0, 7, 18, 1.1, 3), (0, 8, 10, 1.3, 3)],
                      observations: [(0, 6, 12, ["croissance rapide"], "Belle vigueur après plantation.", 0.92),
                                     (0, 7, 8, ["jaunissement", "sol sec"], "Feuilles basses jaunes, période très sèche.", 0.61),
                                     (0, 7, 25, ["jaunissement"], "Le jaunissement progresse malgré le paillage.", 0.55)]),
            DemoPlant(species: "Tomate", name: "Tomate cerise", zone: 0,
                      pos: CGPoint(x: 0.28, y: 0.55), plantedYearsAgo: 0.3,
                      harvests: [(-1, 7, 25, 1.2, 5), (-1, 8, 20, 1.6, 5),
                                 (0, 7, 22, 1.4, 5), (0, 8, 14, 1.7, 4)],
                      observations: [(0, 7, 10, ["fructification"], "Grappes bien formées.", 0.9)]),
            DemoPlant(species: "Courgette", name: "Courgette verte", zone: 0,
                      pos: CGPoint(x: 0.42, y: 0.6), plantedYearsAgo: 0.25,
                      harvests: [(-1, 7, 5, 2.4, 4), (-1, 8, 2, 3.1, 4),
                                 (0, 7, 8, 1.2, 3), (0, 8, 4, 1.5, 3)],
                      observations: [(0, 6, 25, ["excès d'eau"], "Sol détrempé après les orages.", 0.75),
                                     (0, 7, 20, ["taches", "maladie"], "Poudre blanche sur les feuilles — oïdium ?", 0.5)]),
            DemoPlant(species: "Laitue", name: "Laitue batavia", zone: 0,
                      pos: CGPoint(x: 0.2, y: 0.8), plantedYearsAgo: 0.15,
                      harvests: [(0, 5, 20, 0.4, 4), (0, 6, 15, 0.5, 4)],
                      observations: [(0, 5, 2, ["croissance rapide"], "Pommes bien serrées.", 0.95)]),
            DemoPlant(species: "Carotte", name: "Carottes de Colmar", zone: 0,
                      pos: CGPoint(x: 0.34, y: 0.82), plantedYearsAgo: 0.35,
                      harvests: [(-1, 9, 15, 2.1, 4), (0, 9, 10, 2.3, 4)],
                      observations: []),
            DemoPlant(species: "Basilic", name: "Basilic grand vert", zone: 1,
                      pos: CGPoint(x: 0.68, y: 0.62), plantedYearsAgo: 0.2,
                      harvests: [(0, 6, 28, 0.1, 5), (0, 7, 15, 0.15, 5)],
                      observations: [(0, 7, 2, ["croissance rapide"], "Repousse vite après chaque cueillette.", 0.93)]),
            DemoPlant(species: "Menthe", name: "Menthe marocaine", zone: 1,
                      pos: CGPoint(x: 0.8, y: 0.62), plantedYearsAgo: 2.1,
                      harvests: [(-1, 6, 10, 0.2, 5), (0, 6, 8, 0.25, 5)],
                      observations: []),
            DemoPlant(species: "Romarin", name: "Romarin", zone: 1,
                      pos: CGPoint(x: 0.87, y: 0.75), plantedYearsAgo: 3.4,
                      harvests: [(0, 5, 5, 0.1, 5)],
                      observations: []),
            DemoPlant(species: "Thym", name: "Thym de Provence", zone: 1,
                      pos: CGPoint(x: 0.7, y: 0.8), plantedYearsAgo: 2.6,
                      harvests: [(0, 6, 20, 0.08, 5)],
                      observations: []),
            DemoPlant(species: "Fraisier", name: "Fraisiers 'Mara des bois'", zone: 2,
                      pos: CGPoint(x: 0.2, y: 0.25), plantedYearsAgo: 1.8,
                      harvests: [(-1, 6, 5, 0.6, 5), (0, 5, 28, 0.7, 5), (0, 6, 20, 0.5, 4)],
                      observations: [(0, 6, 1, ["fructification", "récolte record"], "Très belle saison.", 0.9)]),
            DemoPlant(species: "Pommier", name: "Pommier 'Reine des reinettes'", zone: 2,
                      pos: CGPoint(x: 0.55, y: 0.2), plantedYearsAgo: 6.5,
                      harvests: [(-1, 9, 25, 18.0, 4), (0, 9, 20, 24.0, 5)],
                      observations: [(0, 4, 15, ["floraison"], "Floraison abondante.", 0.95)]),
            DemoPlant(species: "Framboisier", name: "Framboisiers remontants", zone: 2,
                      pos: CGPoint(x: 0.78, y: 0.28), plantedYearsAgo: 3.2,
                      harvests: [(-1, 7, 10, 0.9, 4), (0, 7, 8, 1.1, 5)],
                      observations: []),
        ]

        let zones = [potager, aromatiques, verger]

        for demo in demoPlants {
            guard let speciesMO = species(demo.species) else { continue }
            let plant = PlantMO(context: context)
            plant.name = demo.name
            plant.species = speciesMO
            plant.category = speciesMO.category
            plant.zone = zones[demo.zone]
            plant.posX = demo.pos.x
            plant.posY = demo.pos.y
            plant.plantedDate = now.addingTimeInterval(-demo.plantedYearsAgo * 365.25 * 86400)

            for (relativeYear, month, day, kg, quality) in demo.harvests {
                let harvest = HarvestMO(context: context)
                harvest.plant = plant
                harvest.date = date(year + relativeYear, month, day)
                harvest.quantityKg = kg
                harvest.quality = Int16(quality)
                harvest.conservationMethod = ConservationMethods.presets.randomElement()
            }

            for (relativeYear, month, day, tags, note, health) in demo.observations {
                let observation = ObservationMO(context: context)
                observation.plant = plant
                observation.date = date(year + relativeYear, month, day)
                observation.tags = tags
                observation.note = note
                observation.healthScore = health
                if health < 0.7 { observation.detectedIssues = ["Jaunissement du feuillage"] }
                if let photo = DemoImageFactory.leafPhoto(healthScore: health) {
                    observation.photoData = photo.photo
                    observation.thumbnailData = photo.thumbnail
                }
            }
        }

        try? context.save()
    }
}

/// Dessine des photos de feuillage synthétiques (CoreGraphics pur, multiplateforme)
/// dont la teinte varie avec le score de santé — utile pour la démo et les previews.
public enum DemoImageFactory {
    public static func leafPhoto(healthScore: Double, size: Int = 512) -> (photo: Data, thumbnail: Data)? {
        guard let context = CGContext(
            data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let s = CGFloat(size)
        context.setFillColor(CGColor(red: 0.93, green: 0.92, blue: 0.85, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: s, height: s))

        // Santé 1 → vert franc ; santé 0 → jaune-brun.
        let health = max(0, min(1, healthScore))
        var generator = SeededGenerator(seed: UInt64(health * 1000) + 7)
        for _ in 0..<26 {
            let cx = CGFloat.random(in: s * 0.1...(s * 0.9), using: &generator)
            let cy = CGFloat.random(in: s * 0.1...(s * 0.9), using: &generator)
            let radius = CGFloat.random(in: s * 0.06...(s * 0.16), using: &generator)
            let sick = Double.random(in: 0...1, using: &generator) > health
            let red = sick ? CGFloat.random(in: 0.68...0.82, using: &generator) : CGFloat.random(in: 0.1...0.25, using: &generator)
            let green = sick ? CGFloat.random(in: 0.6...0.75, using: &generator) : CGFloat.random(in: 0.45...0.65, using: &generator)
            let blue = sick ? CGFloat.random(in: 0.1...0.2, using: &generator) : CGFloat.random(in: 0.15...0.3, using: &generator)
            context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 0.9))
            context.fillEllipse(in: CGRect(x: cx - radius, y: cy - radius * 0.6, width: radius * 2, height: radius * 1.2))
        }

        guard let image = context.makeImage() else { return nil }
        return ImageUtils.makeStoredPhoto(fromCGImage: image)
    }
}

/// Générateur pseudo-aléatoire déterministe (SplitMix64) pour des données de démo stables.
public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    public init(seed: UInt64) { state = seed }
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
