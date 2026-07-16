import Foundation

public struct SpeciesSeed: Sendable {
    public let commonName: String
    public let scientificName: String
    public let category: PlantCategory
    public let water: WaterNeed
    public let sun: SunNeed
    public let soil: String
    public let propagation: String
    public let conservation: String
    public let sowingMonths: [Int]
    public let harvestMonths: [Int]
    public let lifespanYears: Double
    public let companions: [String]
    public let antagonists: [String]
    public let averageYieldKg: Double
    public let notes: String
}

/// Base de fiches plantes livrée avec l'application.
/// Les valeurs sont des moyennes pour un climat tempéré ; chaque champ est
/// personnalisable par l'utilisateur (le champ personnalisé prime sur la fiche).
public enum SpeciesCatalog {
    public static let all: [SpeciesSeed] = [
        SpeciesSeed(
            commonName: "Basilic", scientificName: "Ocimum basilicum", category: .aromatique,
            water: .eleve, sun: .soleil, soil: "Riche, frais, bien drainé",
            propagation: "Bouture de tige dans l'eau (racines en 7–10 jours), semis au chaud dès mars.",
            conservation: "Congélation (ciselé ou en glaçons d'huile), pesto ; le séchage fait perdre l'arôme.",
            sowingMonths: [3, 4, 5], harvestMonths: [6, 7, 8, 9], lifespanYears: 1,
            companions: ["Tomate", "Poivron", "Concombre"], antagonists: ["Rue"],
            averageYieldKg: 0.3,
            notes: "Pincer les fleurs pour prolonger la production de feuilles."
        ),
        SpeciesSeed(
            commonName: "Menthe", scientificName: "Mentha spicata", category: .aromatique,
            water: .eleve, sun: .miOmbre, soil: "Frais, humifère",
            propagation: "Division de stolons ou bouture de tige dans l'eau, très facile toute la saison.",
            conservation: "Séchage, congélation, sirop.",
            sowingMonths: [4, 5], harvestMonths: [5, 6, 7, 8, 9, 10], lifespanYears: 5,
            companions: ["Chou", "Tomate"], antagonists: [],
            averageYieldKg: 0.4,
            notes: "Envahissante : à planter en pot ou avec une barrière anti-rhizomes."
        ),
        SpeciesSeed(
            commonName: "Romarin", scientificName: "Salvia rosmarinus", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Pauvre, calcaire, très drainé",
            propagation: "Bouture à talon en été (août), marcottage.",
            conservation: "Séchage en bouquets, excellent toute l'année.",
            sowingMonths: [3, 4], harvestMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], lifespanYears: 12,
            companions: ["Carotte", "Chou", "Sauge"], antagonists: ["Courge"],
            averageYieldKg: 0.5,
            notes: "Craint surtout l'excès d'eau en hiver."
        ),
        SpeciesSeed(
            commonName: "Thym", scientificName: "Thymus vulgaris", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Sec, caillouteux, calcaire",
            propagation: "Division de touffe au printemps, marcottage, bouture.",
            conservation: "Séchage (garde très bien son arôme).",
            sowingMonths: [3, 4, 5], harvestMonths: [4, 5, 6, 7, 8, 9, 10], lifespanYears: 6,
            companions: ["Chou", "Fraisier", "Aubergine"], antagonists: [],
            averageYieldKg: 0.2,
            notes: "Tailler après floraison pour garder un port compact."
        ),
        SpeciesSeed(
            commonName: "Persil", scientificName: "Petroselinum crispum", category: .aromatique,
            water: .moyen, sun: .miOmbre, soil: "Riche, frais, profond",
            propagation: "Semis (levée lente, 2–3 semaines) ; tremper les graines 24 h.",
            conservation: "Congélation ciselé, séchage doux.",
            sowingMonths: [3, 4, 5, 6, 7, 8], harvestMonths: [5, 6, 7, 8, 9, 10, 11], lifespanYears: 2,
            companions: ["Tomate", "Asperge", "Radis"], antagonists: ["Laitue"],
            averageYieldKg: 0.3,
            notes: "Bisannuel : monte en graines la deuxième année."
        ),
        SpeciesSeed(
            commonName: "Ciboulette", scientificName: "Allium schoenoprasum", category: .aromatique,
            water: .moyen, sun: .soleil, soil: "Ordinaire, frais",
            propagation: "Division de touffe au printemps ou à l'automne.",
            conservation: "Congélation ciselée ; le séchage lui fait perdre son goût.",
            sowingMonths: [3, 4, 5], harvestMonths: [3, 4, 5, 6, 7, 8, 9, 10, 11], lifespanYears: 8,
            companions: ["Carotte", "Fraisier", "Rosier"], antagonists: ["Haricot", "Pois"],
            averageYieldKg: 0.2,
            notes: "Couper au ras pour stimuler la repousse."
        ),
        SpeciesSeed(
            commonName: "Tomate", scientificName: "Solanum lycopersicum", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, profond, bien amendé",
            propagation: "Bouture de gourmands dans l'eau (racines en 10 jours), semis au chaud en février-mars.",
            conservation: "Coulis et bocaux stérilisés, séchage (tomates séchées), congélation.",
            sowingMonths: [2, 3, 4], harvestMonths: [7, 8, 9, 10], lifespanYears: 1,
            companions: ["Basilic", "Œillet d'Inde", "Carotte", "Persil"],
            antagonists: ["Pomme de terre", "Fenouil", "Chou"],
            averageYieldKg: 4.0,
            notes: "Arroser au pied sans mouiller le feuillage (mildiou). Tuteurer."
        ),
        SpeciesSeed(
            commonName: "Courgette", scientificName: "Cucurbita pepo", category: .potager,
            water: .eleve, sun: .soleil, soil: "Très riche en compost, frais",
            propagation: "Semis direct en mai ou en godet en avril.",
            conservation: "Lacto-fermentation, congélation en dés, pickles.",
            sowingMonths: [4, 5, 6], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Haricot", "Capucine", "Maïs"], antagonists: ["Pomme de terre"],
            averageYieldKg: 6.0,
            notes: "Récolter jeune (20 cm) pour stimuler la production. Oïdium fréquent en fin d'été."
        ),
        SpeciesSeed(
            commonName: "Carotte", scientificName: "Daucus carota", category: .potager,
            water: .moyen, sun: .soleil, soil: "Sableux, profond, sans cailloux ni fumier frais",
            propagation: "Semis direct clair, éclaircir à 5 cm.",
            conservation: "Silo de sable en cave, congélation blanchie.",
            sowingMonths: [3, 4, 5, 6, 7], harvestMonths: [5, 6, 7, 8, 9, 10, 11], lifespanYears: 1,
            companions: ["Poireau", "Oignon", "Romarin", "Radis"], antagonists: ["Aneth"],
            averageYieldKg: 2.5,
            notes: "L'association avec le poireau éloigne la mouche de la carotte."
        ),
        SpeciesSeed(
            commonName: "Laitue", scientificName: "Lactuca sativa", category: .potager,
            water: .moyen, sun: .miOmbre, soil: "Frais, humifère",
            propagation: "Semis échelonné toutes les 3 semaines, repiquage à 4 feuilles.",
            conservation: "Consommation rapide ; quelques jours au réfrigérateur.",
            sowingMonths: [2, 3, 4, 5, 6, 7, 8, 9], harvestMonths: [4, 5, 6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Radis", "Carotte", "Fraisier", "Concombre"], antagonists: ["Persil", "Tournesol"],
            averageYieldKg: 1.0,
            notes: "Ombrer en plein été pour éviter la montée en graines."
        ),
        SpeciesSeed(
            commonName: "Radis", scientificName: "Raphanus sativus", category: .potager,
            water: .moyen, sun: .soleil, soil: "Léger, frais",
            propagation: "Semis direct, récolte en 18–30 jours.",
            conservation: "Réfrigérateur ; les fanes se cuisinent en soupe.",
            sowingMonths: [3, 4, 5, 6, 7, 8, 9], harvestMonths: [3, 4, 5, 6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Carotte", "Épinard", "Laitue"], antagonists: ["Hysope"],
            averageYieldKg: 0.8,
            notes: "Arrosage régulier sinon les radis piquent et se creusent."
        ),
        SpeciesSeed(
            commonName: "Épinard", scientificName: "Spinacia oleracea", category: .potager,
            water: .eleve, sun: .miOmbre, soil: "Riche, frais, consistant",
            propagation: "Semis direct au printemps et à la fin de l'été.",
            conservation: "Congélation après blanchiment.",
            sowingMonths: [2, 3, 4, 8, 9], harvestMonths: [3, 4, 5, 9, 10, 11], lifespanYears: 1,
            companions: ["Fraisier", "Haricot", "Radis"], antagonists: ["Betterave"],
            averageYieldKg: 1.5,
            notes: "Monte en graines par temps chaud et sec."
        ),
        SpeciesSeed(
            commonName: "Fraisier", scientificName: "Fragaria × ananassa", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Humifère, légèrement acide, drainé",
            propagation: "Repiquage des stolons en été, division.",
            conservation: "Confiture, congélation, séchage.",
            sowingMonths: [3, 8, 9], harvestMonths: [5, 6, 7, 8, 9], lifespanYears: 4,
            companions: ["Ail", "Épinard", "Laitue", "Thym"], antagonists: ["Chou"],
            averageYieldKg: 0.8,
            notes: "Renouveler les pieds tous les 3–4 ans. Pailler pour garder les fruits propres."
        ),
        SpeciesSeed(
            commonName: "Framboisier", scientificName: "Rubus idaeus", category: .fruitier,
            water: .moyen, sun: .miOmbre, soil: "Humifère, frais, drainé",
            propagation: "Drageons prélevés en automne, bouture de racine.",
            conservation: "Congélation à plat, confiture, coulis.",
            sowingMonths: [11, 2, 3], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 10,
            companions: ["Myosotis", "Ail"], antagonists: ["Pomme de terre"],
            averageYieldKg: 1.5,
            notes: "Tailler les cannes ayant fructifié. Le myosotis éloigne le ver des framboises."
        ),
        SpeciesSeed(
            commonName: "Haricot vert", scientificName: "Phaseolus vulgaris", category: .potager,
            water: .moyen, sun: .soleil, soil: "Léger, réchauffé (> 12 °C)",
            propagation: "Semis direct en poquets de mai à juillet.",
            conservation: "Congélation, stérilisation en bocaux, lacto-fermentation.",
            sowingMonths: [5, 6, 7], harvestMonths: [6, 7, 8, 9], lifespanYears: 1,
            companions: ["Carotte", "Courge", "Maïs", "Fraisier"], antagonists: ["Ail", "Oignon", "Ciboulette"],
            averageYieldKg: 1.2,
            notes: "Récolter tous les 2–3 jours pour prolonger la production."
        ),
        SpeciesSeed(
            commonName: "Concombre", scientificName: "Cucumis sativus", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, frais, meuble",
            propagation: "Semis en godet en avril, en place en mai.",
            conservation: "Pickles, lacto-fermentation (cornichons).",
            sowingMonths: [4, 5, 6], harvestMonths: [6, 7, 8, 9], lifespanYears: 1,
            companions: ["Haricot", "Laitue", "Aneth", "Basilic"], antagonists: ["Pomme de terre", "Sauge"],
            averageYieldKg: 3.0,
            notes: "Palisser pour des fruits droits et sains."
        ),
        SpeciesSeed(
            commonName: "Poivron", scientificName: "Capsicum annuum", category: .potager,
            water: .moyen, sun: .soleil, soil: "Riche, drainé, chaud",
            propagation: "Semis au chaud (20–25 °C) en février-mars.",
            conservation: "Congélation grillé et pelé, séchage, huile.",
            sowingMonths: [2, 3], harvestMonths: [7, 8, 9, 10], lifespanYears: 1,
            companions: ["Basilic", "Tomate", "Carotte"], antagonists: ["Fenouil", "Haricot"],
            averageYieldKg: 1.5,
            notes: "A besoin de chaleur : serre ou emplacement abrité au nord de la Loire."
        ),
        SpeciesSeed(
            commonName: "Aubergine", scientificName: "Solanum melongena", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, profond, chaud",
            propagation: "Semis au chaud en février, plantation après les gelées.",
            conservation: "Bocaux (caponata), congélation cuite, séchage.",
            sowingMonths: [2, 3], harvestMonths: [7, 8, 9, 10], lifespanYears: 1,
            companions: ["Haricot", "Estragon", "Thym"], antagonists: ["Pomme de terre"],
            averageYieldKg: 2.0,
            notes: "Surveiller les doryphores, comme pour la pomme de terre."
        ),
        SpeciesSeed(
            commonName: "Pommier", scientificName: "Malus domestica", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Profond, argilo-limoneux, frais",
            propagation: "Greffage sur porte-greffe (écussonnage en été, fente en hiver).",
            conservation: "Cave à fruits (0–4 °C), compote stérilisée, jus, séchage en lamelles.",
            sowingMonths: [11, 12, 1, 2], harvestMonths: [8, 9, 10, 11], lifespanYears: 50,
            companions: ["Capucine", "Ciboulette", "Lavande"], antagonists: ["Noyer"],
            averageYieldKg: 25.0,
            notes: "Éclaircir les fruits en juin pour éviter l'alternance."
        ),
        SpeciesSeed(
            commonName: "Lavande", scientificName: "Lavandula angustifolia", category: .fleur,
            water: .faible, sun: .soleil, soil: "Calcaire, sec, très drainé",
            propagation: "Bouture semi-ligneuse en août-septembre.",
            conservation: "Séchage en bouquets suspendus, sachets parfumés.",
            sowingMonths: [3, 4], harvestMonths: [6, 7, 8], lifespanYears: 15,
            companions: ["Rosier", "Thym", "Pommier"], antagonists: [],
            averageYieldKg: 0.3,
            notes: "Tailler chaque année sans toucher au vieux bois."
        ),
        SpeciesSeed(
            commonName: "Sauge officinale", scientificName: "Salvia officinalis", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Drainé, calcaire",
            propagation: "Bouture de tige au printemps ou en fin d'été.",
            conservation: "Séchage.",
            sowingMonths: [3, 4, 5], harvestMonths: [4, 5, 6, 7, 8, 9, 10], lifespanYears: 6,
            companions: ["Chou", "Carotte", "Romarin"], antagonists: ["Concombre"],
            averageYieldKg: 0.3,
            notes: "Rabattre au printemps pour éviter qu'elle ne se dégarnisse."
        ),
        SpeciesSeed(
            commonName: "Origan", scientificName: "Origanum vulgare", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Sec, ordinaire, drainé",
            propagation: "Division de touffe au printemps, semis.",
            conservation: "Séchage (plus parfumé sec que frais).",
            sowingMonths: [3, 4, 5], harvestMonths: [6, 7, 8, 9], lifespanYears: 8,
            companions: ["Chou", "Vigne"], antagonists: [],
            averageYieldKg: 0.25,
            notes: "Récolter juste avant floraison pour un parfum maximal."
        ),
        SpeciesSeed(
            commonName: "Œillet d'Inde", scientificName: "Tagetes patula", category: .fleur,
            water: .moyen, sun: .soleil, soil: "Ordinaire",
            propagation: "Semis en godet en mars-avril, en place en mai.",
            conservation: "Fleurs séchées (infusions), graines récoltées à l'automne.",
            sowingMonths: [3, 4, 5], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Tomate", "Courgette", "Chou"], antagonists: [],
            averageYieldKg: 0.1,
            notes: "Répulsif nématodes et aleurodes : à intercaler partout au potager."
        ),
    ]

    public static func seed(named name: String) -> SpeciesSeed? {
        all.first { $0.commonName.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }
}
