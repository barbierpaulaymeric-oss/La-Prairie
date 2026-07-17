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
    /// Emprise au sol adulte (diamètre en mètres) — pilote la taille sur la carte.
    public let spreadM: Double
    public let notes: String
}

/// Base de fiches plantes livrée avec l'application (73 espèces).
/// Valeurs moyennes pour un climat tempéré ; chaque champ est personnalisable
/// par l'utilisateur (la personnalisation prime sur la fiche).
public enum SpeciesCatalog {
    public static let all: [SpeciesSeed] =
        aromatiques + potager + fruitiers + fleurs

    public static func seed(named name: String) -> SpeciesSeed? {
        all.first { $0.commonName.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }

    // MARK: - Aromatiques

    static let aromatiques: [SpeciesSeed] = [
        SpeciesSeed(
            commonName: "Basilic", scientificName: "Ocimum basilicum", category: .aromatique,
            water: .eleve, sun: .soleil, soil: "Riche, frais, bien drainé",
            propagation: "Bouture de tige dans l'eau (racines en 7–10 jours), semis au chaud dès mars.",
            conservation: "Congélation (ciselé ou en glaçons d'huile), pesto ; le séchage fait perdre l'arôme.",
            sowingMonths: [3, 4, 5], harvestMonths: [6, 7, 8, 9], lifespanYears: 1,
            companions: ["Tomate", "Poivron", "Concombre"], antagonists: ["Rue"],
            averageYieldKg: 0.3, spreadM: 0.3,
            notes: "Pincer les fleurs pour prolonger la production de feuilles."
        ),
        SpeciesSeed(
            commonName: "Menthe", scientificName: "Mentha spicata", category: .aromatique,
            water: .eleve, sun: .miOmbre, soil: "Frais, humifère",
            propagation: "Division de stolons ou bouture de tige dans l'eau, très facile toute la saison.",
            conservation: "Séchage, congélation, sirop.",
            sowingMonths: [4, 5], harvestMonths: [5, 6, 7, 8, 9, 10], lifespanYears: 5,
            companions: ["Chou pommé", "Tomate"], antagonists: [],
            averageYieldKg: 0.4, spreadM: 0.4,
            notes: "Envahissante : à planter en pot ou avec une barrière anti-rhizomes."
        ),
        SpeciesSeed(
            commonName: "Romarin", scientificName: "Salvia rosmarinus", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Pauvre, calcaire, très drainé",
            propagation: "Bouture à talon en été (août), marcottage.",
            conservation: "Séchage en bouquets, excellent toute l'année.",
            sowingMonths: [3, 4], harvestMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], lifespanYears: 12,
            companions: ["Carotte", "Chou pommé", "Sauge officinale"], antagonists: ["Courgette"],
            averageYieldKg: 0.5, spreadM: 0.9,
            notes: "Craint surtout l'excès d'eau en hiver."
        ),
        SpeciesSeed(
            commonName: "Thym", scientificName: "Thymus vulgaris", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Sec, caillouteux, calcaire",
            propagation: "Division de touffe au printemps, marcottage, bouture.",
            conservation: "Séchage (garde très bien son arôme).",
            sowingMonths: [3, 4, 5], harvestMonths: [4, 5, 6, 7, 8, 9, 10], lifespanYears: 6,
            companions: ["Chou pommé", "Fraisier", "Aubergine"], antagonists: [],
            averageYieldKg: 0.2, spreadM: 0.3,
            notes: "Tailler après floraison pour garder un port compact."
        ),
        SpeciesSeed(
            commonName: "Persil", scientificName: "Petroselinum crispum", category: .aromatique,
            water: .moyen, sun: .miOmbre, soil: "Riche, frais, profond",
            propagation: "Semis (levée lente, 2–3 semaines) ; tremper les graines 24 h.",
            conservation: "Congélation ciselé, séchage doux.",
            sowingMonths: [3, 4, 5, 6, 7, 8], harvestMonths: [5, 6, 7, 8, 9, 10, 11], lifespanYears: 2,
            companions: ["Tomate", "Asperge", "Radis"], antagonists: ["Laitue"],
            averageYieldKg: 0.3, spreadM: 0.25,
            notes: "Bisannuel : monte en graines la deuxième année."
        ),
        SpeciesSeed(
            commonName: "Ciboulette", scientificName: "Allium schoenoprasum", category: .aromatique,
            water: .moyen, sun: .soleil, soil: "Ordinaire, frais",
            propagation: "Division de touffe au printemps ou à l'automne.",
            conservation: "Congélation ciselée ; le séchage lui fait perdre son goût.",
            sowingMonths: [3, 4, 5], harvestMonths: [3, 4, 5, 6, 7, 8, 9, 10, 11], lifespanYears: 8,
            companions: ["Carotte", "Fraisier", "Pommier"], antagonists: ["Haricot vert", "Petit pois"],
            averageYieldKg: 0.2, spreadM: 0.2,
            notes: "Couper au ras pour stimuler la repousse."
        ),
        SpeciesSeed(
            commonName: "Sauge officinale", scientificName: "Salvia officinalis", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Drainé, calcaire",
            propagation: "Bouture de tige au printemps ou en fin d'été.",
            conservation: "Séchage.",
            sowingMonths: [3, 4, 5], harvestMonths: [4, 5, 6, 7, 8, 9, 10], lifespanYears: 6,
            companions: ["Chou pommé", "Carotte", "Romarin"], antagonists: ["Concombre"],
            averageYieldKg: 0.3, spreadM: 0.6,
            notes: "Rabattre au printemps pour éviter qu'elle ne se dégarnisse."
        ),
        SpeciesSeed(
            commonName: "Origan", scientificName: "Origanum vulgare", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Sec, ordinaire, drainé",
            propagation: "Division de touffe au printemps, semis.",
            conservation: "Séchage (plus parfumé sec que frais).",
            sowingMonths: [3, 4, 5], harvestMonths: [6, 7, 8, 9], lifespanYears: 8,
            companions: ["Chou pommé", "Vigne"], antagonists: [],
            averageYieldKg: 0.25, spreadM: 0.45,
            notes: "Récolter juste avant floraison pour un parfum maximal."
        ),
        SpeciesSeed(
            commonName: "Aneth", scientificName: "Anethum graveolens", category: .aromatique,
            water: .moyen, sun: .soleil, soil: "Léger, drainé",
            propagation: "Semis direct d'avril à juillet (racine pivot : ne se repique pas).",
            conservation: "Graines séchées en ombelles, feuilles congelées.",
            sowingMonths: [4, 5, 6, 7], harvestMonths: [6, 7, 8, 9], lifespanYears: 1,
            companions: ["Concombre", "Chou pommé"], antagonists: ["Carotte", "Fenouil bulbeux"],
            averageYieldKg: 0.2, spreadM: 0.25,
            notes: "Se ressème spontanément si on laisse quelques ombelles."
        ),
        SpeciesSeed(
            commonName: "Coriandre", scientificName: "Coriandrum sativum", category: .aromatique,
            water: .moyen, sun: .miOmbre, soil: "Léger, frais",
            propagation: "Semis direct échelonné d'avril à septembre (monte vite au chaud).",
            conservation: "Graines séchées, feuilles congelées en glaçons.",
            sowingMonths: [4, 5, 6, 7, 8, 9], harvestMonths: [5, 6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Épinard", "Radis"], antagonists: ["Fenouil bulbeux"],
            averageYieldKg: 0.2, spreadM: 0.2,
            notes: "Semer à mi-ombre l'été pour retarder la montée en graines."
        ),
        SpeciesSeed(
            commonName: "Estragon", scientificName: "Artemisia dracunculus", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Léger, drainé",
            propagation: "Bouture ou division (l'estragon français, le plus parfumé, ne se sème pas).",
            conservation: "Congélation, vinaigre d'estragon ; séchage décevant.",
            sowingMonths: [4, 5], harvestMonths: [5, 6, 7, 8, 9, 10], lifespanYears: 5,
            companions: ["Aubergine"], antagonists: [],
            averageYieldKg: 0.3, spreadM: 0.4,
            notes: "Protéger la souche du gel avec un paillage épais."
        ),
        SpeciesSeed(
            commonName: "Laurier-sauce", scientificName: "Laurus nobilis", category: .aromatique,
            water: .faible, sun: .soleil, soil: "Drainé, même pauvre",
            propagation: "Bouture semi-ligneuse en août, marcottage.",
            conservation: "Séchage des feuilles (plusieurs années).",
            sowingMonths: [8, 9], harvestMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], lifespanYears: 30,
            companions: [], antagonists: [],
            averageYieldKg: 0.5, spreadM: 2.0,
            notes: "Se taille très bien ; protéger des gels sévères les premières années."
        ),
        SpeciesSeed(
            commonName: "Mélisse", scientificName: "Melissa officinalis", category: .aromatique,
            water: .moyen, sun: .miOmbre, soil: "Frais, ordinaire",
            propagation: "Division de touffe, semis spontané abondant.",
            conservation: "Séchage rapide à l'ombre (infusions).",
            sowingMonths: [3, 4, 5], harvestMonths: [5, 6, 7, 8, 9, 10], lifespanYears: 8,
            companions: ["Chou pommé"], antagonists: [],
            averageYieldKg: 0.4, spreadM: 0.45,
            notes: "Expansive comme la menthe : contenir la touffe."
        ),
        SpeciesSeed(
            commonName: "Verveine citronnelle", scientificName: "Aloysia citrodora", category: .aromatique,
            water: .moyen, sun: .soleil, soil: "Drainé, riche",
            propagation: "Bouture herbacée en été.",
            conservation: "Séchage des feuilles (infusions très parfumées).",
            sowingMonths: [5], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 6,
            companions: [], antagonists: [],
            averageYieldKg: 0.3, spreadM: 0.7,
            notes: "Gélive : cultiver en pot à hiverner hors gel, ou pailler très fort."
        ),
    ]

    // MARK: - Potager

    static let potager: [SpeciesSeed] = [
        SpeciesSeed(
            commonName: "Tomate", scientificName: "Solanum lycopersicum", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, profond, bien amendé",
            propagation: "Bouture de gourmands dans l'eau (racines en 10 jours), semis au chaud en février-mars.",
            conservation: "Coulis et bocaux stérilisés, séchage (tomates séchées), congélation.",
            sowingMonths: [2, 3, 4], harvestMonths: [7, 8, 9, 10], lifespanYears: 1,
            companions: ["Basilic", "Œillet d'Inde", "Carotte", "Persil"],
            antagonists: ["Pomme de terre", "Fenouil bulbeux", "Chou pommé"],
            averageYieldKg: 4.0, spreadM: 0.6,
            notes: "Arroser au pied sans mouiller le feuillage (mildiou). Tuteurer."
        ),
        SpeciesSeed(
            commonName: "Courgette", scientificName: "Cucurbita pepo", category: .potager,
            water: .eleve, sun: .soleil, soil: "Très riche en compost, frais",
            propagation: "Semis direct en mai ou en godet en avril.",
            conservation: "Lacto-fermentation, congélation en dés, pickles.",
            sowingMonths: [4, 5, 6], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Haricot vert", "Capucine", "Maïs doux"], antagonists: ["Pomme de terre"],
            averageYieldKg: 6.0, spreadM: 1.0,
            notes: "Récolter jeune (20 cm) pour stimuler la production. Oïdium fréquent en fin d'été."
        ),
        SpeciesSeed(
            commonName: "Carotte", scientificName: "Daucus carota", category: .potager,
            water: .moyen, sun: .soleil, soil: "Sableux, profond, sans cailloux ni fumier frais",
            propagation: "Semis direct clair, éclaircir à 5 cm.",
            conservation: "Silo de sable en cave, congélation blanchie.",
            sowingMonths: [3, 4, 5, 6, 7], harvestMonths: [5, 6, 7, 8, 9, 10, 11], lifespanYears: 1,
            companions: ["Poireau", "Oignon", "Romarin", "Radis"], antagonists: ["Aneth"],
            averageYieldKg: 2.5, spreadM: 0.1,
            notes: "L'association avec le poireau éloigne la mouche de la carotte."
        ),
        SpeciesSeed(
            commonName: "Laitue", scientificName: "Lactuca sativa", category: .potager,
            water: .moyen, sun: .miOmbre, soil: "Frais, humifère",
            propagation: "Semis échelonné toutes les 3 semaines, repiquage à 4 feuilles.",
            conservation: "Consommation rapide ; quelques jours au réfrigérateur.",
            sowingMonths: [2, 3, 4, 5, 6, 7, 8, 9], harvestMonths: [4, 5, 6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Radis", "Carotte", "Fraisier", "Concombre"], antagonists: ["Persil", "Tournesol"],
            averageYieldKg: 1.0, spreadM: 0.3,
            notes: "Ombrer en plein été pour éviter la montée en graines."
        ),
        SpeciesSeed(
            commonName: "Radis", scientificName: "Raphanus sativus", category: .potager,
            water: .moyen, sun: .soleil, soil: "Léger, frais",
            propagation: "Semis direct, récolte en 18–30 jours.",
            conservation: "Réfrigérateur ; les fanes se cuisinent en soupe.",
            sowingMonths: [3, 4, 5, 6, 7, 8, 9], harvestMonths: [3, 4, 5, 6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Carotte", "Épinard", "Laitue"], antagonists: ["Hysope"],
            averageYieldKg: 0.8, spreadM: 0.08,
            notes: "Arrosage régulier sinon les radis piquent et se creusent."
        ),
        SpeciesSeed(
            commonName: "Épinard", scientificName: "Spinacia oleracea", category: .potager,
            water: .eleve, sun: .miOmbre, soil: "Riche, frais, consistant",
            propagation: "Semis direct au printemps et à la fin de l'été.",
            conservation: "Congélation après blanchiment.",
            sowingMonths: [2, 3, 4, 8, 9], harvestMonths: [3, 4, 5, 9, 10, 11], lifespanYears: 1,
            companions: ["Fraisier", "Haricot vert", "Radis"], antagonists: ["Betterave"],
            averageYieldKg: 1.5, spreadM: 0.25,
            notes: "Monte en graines par temps chaud et sec."
        ),
        SpeciesSeed(
            commonName: "Haricot vert", scientificName: "Phaseolus vulgaris", category: .potager,
            water: .moyen, sun: .soleil, soil: "Léger, réchauffé (> 12 °C)",
            propagation: "Semis direct en poquets de mai à juillet.",
            conservation: "Congélation, stérilisation en bocaux, lacto-fermentation.",
            sowingMonths: [5, 6, 7], harvestMonths: [6, 7, 8, 9], lifespanYears: 1,
            companions: ["Carotte", "Potiron", "Maïs doux", "Fraisier"],
            antagonists: ["Ail", "Oignon", "Ciboulette"],
            averageYieldKg: 1.2, spreadM: 0.3,
            notes: "Récolter tous les 2–3 jours pour prolonger la production."
        ),
        SpeciesSeed(
            commonName: "Concombre", scientificName: "Cucumis sativus", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, frais, meuble",
            propagation: "Semis en godet en avril, en place en mai.",
            conservation: "Pickles, lacto-fermentation (cornichons).",
            sowingMonths: [4, 5, 6], harvestMonths: [6, 7, 8, 9], lifespanYears: 1,
            companions: ["Haricot vert", "Laitue", "Aneth", "Basilic"],
            antagonists: ["Pomme de terre", "Sauge officinale"],
            averageYieldKg: 3.0, spreadM: 0.8,
            notes: "Palisser pour des fruits droits et sains."
        ),
        SpeciesSeed(
            commonName: "Poivron", scientificName: "Capsicum annuum", category: .potager,
            water: .moyen, sun: .soleil, soil: "Riche, drainé, chaud",
            propagation: "Semis au chaud (20–25 °C) en février-mars.",
            conservation: "Congélation grillé et pelé, séchage, huile.",
            sowingMonths: [2, 3], harvestMonths: [7, 8, 9, 10], lifespanYears: 1,
            companions: ["Basilic", "Tomate", "Carotte"], antagonists: ["Fenouil bulbeux", "Haricot vert"],
            averageYieldKg: 1.5, spreadM: 0.45,
            notes: "A besoin de chaleur : serre ou emplacement abrité au nord de la Loire."
        ),
        SpeciesSeed(
            commonName: "Aubergine", scientificName: "Solanum melongena", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, profond, chaud",
            propagation: "Semis au chaud en février, plantation après les gelées.",
            conservation: "Bocaux (caponata), congélation cuite, séchage.",
            sowingMonths: [2, 3], harvestMonths: [7, 8, 9, 10], lifespanYears: 1,
            companions: ["Haricot vert", "Estragon", "Thym"], antagonists: ["Pomme de terre"],
            averageYieldKg: 2.0, spreadM: 0.6,
            notes: "Surveiller les doryphores, comme pour la pomme de terre."
        ),
        SpeciesSeed(
            commonName: "Chou pommé", scientificName: "Brassica oleracea var. capitata", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, frais, consistant",
            propagation: "Semis en pépinière puis repiquage à 5-6 feuilles.",
            conservation: "Choucroute (lacto-fermentation), cave fraîche plusieurs semaines.",
            sowingMonths: [3, 4, 5], harvestMonths: [6, 7, 8, 9, 10, 11], lifespanYears: 1,
            companions: ["Céleri-branche", "Betterave", "Romarin", "Menthe"],
            antagonists: ["Fraisier", "Tomate"],
            averageYieldKg: 2.0, spreadM: 0.5,
            notes: "Rotation de 3–4 ans pour éviter la hernie du chou. Filet anti-piéride utile."
        ),
        SpeciesSeed(
            commonName: "Chou-fleur", scientificName: "Brassica oleracea var. botrytis", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, profond, jamais sec",
            propagation: "Semis en pépinière, repiquage soigné (sans stress hydrique).",
            conservation: "Congélation en fleurettes blanchies, pickles.",
            sowingMonths: [2, 3, 4, 5, 6], harvestMonths: [6, 7, 8, 9, 10, 11], lifespanYears: 1,
            companions: ["Céleri-branche", "Betterave"], antagonists: ["Fraisier"],
            averageYieldKg: 1.2, spreadM: 0.55,
            notes: "Replier quelques feuilles sur la pomme pour la garder blanche."
        ),
        SpeciesSeed(
            commonName: "Brocoli", scientificName: "Brassica oleracea var. italica", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, frais",
            propagation: "Semis en pépinière puis repiquage.",
            conservation: "Congélation en fleurettes blanchies.",
            sowingMonths: [3, 4, 5, 6], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Betterave", "Céleri-branche"], antagonists: ["Fraisier"],
            averageYieldKg: 0.8, spreadM: 0.45,
            notes: "Après la pomme centrale, laisser venir les jets latéraux."
        ),
        SpeciesSeed(
            commonName: "Chou kale", scientificName: "Brassica oleracea var. sabellica", category: .potager,
            water: .moyen, sun: .soleil, soil: "Riche, frais",
            propagation: "Semis d'avril à juin, repiquage.",
            conservation: "Congélation, chips séchées au four doux.",
            sowingMonths: [4, 5, 6], harvestMonths: [9, 10, 11, 12, 1, 2], lifespanYears: 1,
            companions: ["Betterave"], antagonists: ["Tomate"],
            averageYieldKg: 0.9, spreadM: 0.45,
            notes: "Meilleur après les premières gelées, qui l'adoucissent."
        ),
        SpeciesSeed(
            commonName: "Poireau", scientificName: "Allium porrum", category: .potager,
            water: .moyen, sun: .soleil, soil: "Riche, profond, meuble",
            propagation: "Semis en pépinière février-avril, repiquage en été (habillage des racines).",
            conservation: "Reste en terre tout l'hiver ; congélation en tronçons.",
            sowingMonths: [2, 3, 4], harvestMonths: [9, 10, 11, 12, 1, 2, 3], lifespanYears: 1,
            companions: ["Carotte", "Fraisier", "Céleri-branche"], antagonists: ["Haricot vert", "Petit pois"],
            averageYieldKg: 1.5, spreadM: 0.1,
            notes: "L'association carotte/poireau perturbe la mouche de chacun."
        ),
        SpeciesSeed(
            commonName: "Oignon", scientificName: "Allium cepa", category: .potager,
            water: .faible, sun: .soleil, soil: "Léger, drainé, sans fumure fraîche",
            propagation: "Bulbilles au printemps (le plus simple) ou semis.",
            conservation: "Séchage au sol puis tressage, local sec et aéré (plusieurs mois).",
            sowingMonths: [2, 3, 4, 8, 9], harvestMonths: [6, 7, 8, 9], lifespanYears: 1,
            companions: ["Carotte", "Betterave", "Laitue"], antagonists: ["Haricot vert", "Petit pois"],
            averageYieldKg: 1.0, spreadM: 0.1,
            notes: "Stopper l'arrosage quand les fanes se couchent."
        ),
        SpeciesSeed(
            commonName: "Ail", scientificName: "Allium sativum", category: .potager,
            water: .faible, sun: .soleil, soil: "Drainé, léger (pourrit en sol humide)",
            propagation: "Caïeux plantés pointe en haut, automne (violet) ou fin d'hiver (blanc).",
            conservation: "Séchage puis tressage, local sec (6–10 mois).",
            sowingMonths: [10, 11, 2, 3], harvestMonths: [6, 7, 8], lifespanYears: 1,
            companions: ["Fraisier", "Tomate", "Framboisier"], antagonists: ["Haricot vert", "Petit pois"],
            averageYieldKg: 0.5, spreadM: 0.08,
            notes: "Aucun arrosage dès la formation des bulbes."
        ),
        SpeciesSeed(
            commonName: "Échalote", scientificName: "Allium ascalonicum", category: .potager,
            water: .faible, sun: .soleil, soil: "Léger, drainé",
            propagation: "Caïeux plantés en février-mars (ou automne en climat doux).",
            conservation: "Séchage, local sec et aéré (6 mois et plus).",
            sowingMonths: [2, 3, 10, 11], harvestMonths: [6, 7, 8], lifespanYears: 1,
            companions: ["Carotte", "Laitue"], antagonists: ["Haricot vert", "Petit pois"],
            averageYieldKg: 0.6, spreadM: 0.08,
            notes: "Chaque caïeu donne une touffe de 5 à 10 échalotes."
        ),
        SpeciesSeed(
            commonName: "Betterave", scientificName: "Beta vulgaris", category: .potager,
            water: .moyen, sun: .soleil, soil: "Profond, meuble, frais",
            propagation: "Semis direct en avril-juin, éclaircir (chaque graine est un glomérule).",
            conservation: "Silo de sable en cave, lacto-fermentation, bocaux au vinaigre.",
            sowingMonths: [4, 5, 6], harvestMonths: [7, 8, 9, 10], lifespanYears: 1,
            companions: ["Oignon", "Laitue", "Chou pommé"], antagonists: ["Épinard"],
            averageYieldKg: 2.0, spreadM: 0.15,
            notes: "Récolter avant les grosses gelées."
        ),
        SpeciesSeed(
            commonName: "Pomme de terre", scientificName: "Solanum tuberosum", category: .potager,
            water: .moyen, sun: .soleil, soil: "Profond, meuble, bien ameubli",
            propagation: "Plants germés (6 semaines de germination en clayettes à la lumière).",
            conservation: "Cave obscure, fraîche et aérée (plusieurs mois).",
            sowingMonths: [3, 4, 5], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Haricot vert", "Œillet d'Inde", "Fève"],
            antagonists: ["Tomate", "Courgette", "Framboisier"],
            averageYieldKg: 3.0, spreadM: 0.4,
            notes: "Butter deux fois pendant la pousse. Surveiller les doryphores."
        ),
        SpeciesSeed(
            commonName: "Maïs doux", scientificName: "Zea mays", category: .potager,
            water: .eleve, sun: .soleil, soil: "Riche, profond",
            propagation: "Semis direct en poquets, en carré plutôt qu'en ligne (pollinisation).",
            conservation: "Congélation en grains ou épis, bocaux.",
            sowingMonths: [5, 6], harvestMonths: [8, 9, 10], lifespanYears: 1,
            companions: ["Haricot vert", "Potiron", "Concombre"], antagonists: ["Tomate"],
            averageYieldKg: 1.0, spreadM: 0.3,
            notes: "Récolter quand les soies brunissent et que le grain est laiteux."
        ),
        SpeciesSeed(
            commonName: "Petit pois", scientificName: "Pisum sativum", category: .potager,
            water: .moyen, sun: .soleil, soil: "Frais, léger, sans excès d'azote",
            propagation: "Semis direct de février à mai (et octobre-novembre en climat doux).",
            conservation: "Congélation aussitôt écossés, bocaux stérilisés.",
            sowingMonths: [2, 3, 4, 5, 10, 11], harvestMonths: [5, 6, 7], lifespanYears: 1,
            companions: ["Carotte", "Radis", "Maïs doux"], antagonists: ["Ail", "Oignon", "Échalote"],
            averageYieldKg: 0.8, spreadM: 0.2,
            notes: "Ramer les variétés à rames dès 10 cm."
        ),
        SpeciesSeed(
            commonName: "Fève", scientificName: "Vicia faba", category: .potager,
            water: .moyen, sun: .soleil, soil: "Profond, consistant",
            propagation: "Semis direct en février-avril, ou octobre-novembre en climat doux.",
            conservation: "Congélation écossée, séchage en grains.",
            sowingMonths: [2, 3, 4, 10, 11], harvestMonths: [5, 6, 7], lifespanYears: 1,
            companions: ["Maïs doux", "Pomme de terre"], antagonists: ["Ail", "Oignon"],
            averageYieldKg: 1.0, spreadM: 0.25,
            notes: "Pincer les têtes à la floraison contre les pucerons noirs."
        ),
        SpeciesSeed(
            commonName: "Potiron", scientificName: "Cucurbita maxima", category: .potager,
            water: .eleve, sun: .soleil, soil: "Très riche (planter sur compost), frais",
            propagation: "Semis en godet en avril ou direct en mai.",
            conservation: "Entier, local frais et sec : 3 à 6 mois.",
            sowingMonths: [4, 5], harvestMonths: [9, 10, 11], lifespanYears: 1,
            companions: ["Maïs doux", "Haricot vert"], antagonists: ["Pomme de terre"],
            averageYieldKg: 8.0, spreadM: 2.0,
            notes: "Récolter pédoncule liégeux, avant les gelées. Laisser les fruits mûrir au soleil."
        ),
        SpeciesSeed(
            commonName: "Courge butternut", scientificName: "Cucurbita moschata", category: .potager,
            water: .eleve, sun: .soleil, soil: "Très riche, frais",
            propagation: "Semis en godet en avril-mai, en place fin mai.",
            conservation: "Entière, local frais et sec : jusqu'à 6 mois.",
            sowingMonths: [4, 5], harvestMonths: [9, 10, 11], lifespanYears: 1,
            companions: ["Maïs doux", "Haricot vert"], antagonists: ["Pomme de terre"],
            averageYieldKg: 6.0, spreadM: 1.8,
            notes: "Limiter à 3–4 fruits par pied pour de belles courges."
        ),
        SpeciesSeed(
            commonName: "Melon", scientificName: "Cucumis melo", category: .potager,
            water: .moyen, sun: .soleil, soil: "Riche, chaud, drainé",
            propagation: "Semis au chaud en mars-avril, plantation sur butte en mai.",
            conservation: "Consommation rapide ; sorbet, congélation en billes.",
            sowingMonths: [3, 4, 5], harvestMonths: [7, 8, 9], lifespanYears: 1,
            companions: ["Maïs doux"], antagonists: ["Concombre", "Pomme de terre"],
            averageYieldKg: 3.0, spreadM: 1.0,
            notes: "Tailler après 2 feuilles puis après 4 pour hâter la fructification."
        ),
        SpeciesSeed(
            commonName: "Pastèque", scientificName: "Citrullus lanatus", category: .potager,
            water: .eleve, sun: .soleil, soil: "Sableux, riche, très chaud",
            propagation: "Semis au chaud en avril, plantation fin mai.",
            conservation: "Consommation rapide après récolte.",
            sowingMonths: [4, 5], harvestMonths: [8, 9], lifespanYears: 1,
            companions: ["Maïs doux"], antagonists: ["Pomme de terre"],
            averageYieldKg: 4.0, spreadM: 1.5,
            notes: "Le fruit sonne creux et la vrille sèche à maturité."
        ),
        SpeciesSeed(
            commonName: "Blette", scientificName: "Beta vulgaris var. cicla", category: .potager,
            water: .moyen, sun: .soleil, soil: "Riche, frais",
            propagation: "Semis direct d'avril à juillet.",
            conservation: "Congélation blanchie (cardes et feuilles séparées).",
            sowingMonths: [4, 5, 6, 7], harvestMonths: [6, 7, 8, 9, 10, 11], lifespanYears: 1,
            companions: ["Carotte", "Radis"], antagonists: [],
            averageYieldKg: 2.5, spreadM: 0.4,
            notes: "Couper feuille à feuille : la touffe repousse tout l'été."
        ),
        SpeciesSeed(
            commonName: "Céleri-branche", scientificName: "Apium graveolens var. dulce", category: .potager,
            water: .eleve, sun: .miOmbre, soil: "Riche, frais, jamais sec",
            propagation: "Semis au chaud en février-avril, repiquage prudent.",
            conservation: "Congélation en tronçons, sel de céleri (feuilles séchées).",
            sowingMonths: [2, 3, 4], harvestMonths: [8, 9, 10, 11], lifespanYears: 1,
            companions: ["Chou pommé", "Poireau", "Tomate"], antagonists: [],
            averageYieldKg: 1.5, spreadM: 0.3,
            notes: "Blanchir les côtes en buttant ou en entourant de carton 15 jours avant récolte."
        ),
        SpeciesSeed(
            commonName: "Fenouil bulbeux", scientificName: "Foeniculum vulgare var. azoricum", category: .potager,
            water: .moyen, sun: .soleil, soil: "Frais, léger, riche",
            propagation: "Semis direct de mai à juillet (monte s'il a froid jeune).",
            conservation: "Réfrigérateur ; congélation blanchi.",
            sowingMonths: [5, 6, 7], harvestMonths: [8, 9, 10, 11], lifespanYears: 1,
            companions: ["Concombre", "Laitue"], antagonists: ["Tomate", "Haricot vert", "Aneth"],
            averageYieldKg: 1.0, spreadM: 0.25,
            notes: "Allélopathique : à tenir à l'écart de la plupart des légumes."
        ),
        SpeciesSeed(
            commonName: "Navet", scientificName: "Brassica rapa", category: .potager,
            water: .moyen, sun: .miOmbre, soil: "Frais, léger",
            propagation: "Semis direct mars-mai puis août-septembre.",
            conservation: "Silo de sable, cave fraîche.",
            sowingMonths: [3, 4, 5, 8, 9], harvestMonths: [5, 6, 7, 10, 11, 12], lifespanYears: 1,
            companions: ["Petit pois", "Laitue"], antagonists: [],
            averageYieldKg: 1.2, spreadM: 0.12,
            notes: "Croissance rapide : arroser régulièrement pour éviter le creusement."
        ),
        SpeciesSeed(
            commonName: "Panais", scientificName: "Pastinaca sativa", category: .potager,
            water: .moyen, sun: .soleil, soil: "Profond, meuble, frais",
            propagation: "Semis direct de février à mai (levée lente, graines fraîches indispensables).",
            conservation: "Reste en terre l'hiver (meilleur après gel), cave en sable.",
            sowingMonths: [2, 3, 4, 5], harvestMonths: [9, 10, 11, 12, 1, 2], lifespanYears: 1,
            companions: ["Oignon", "Radis"], antagonists: [],
            averageYieldKg: 2.0, spreadM: 0.15,
            notes: "Marquer les rangs avec des radis (levée en 20 jours et plus)."
        ),
        SpeciesSeed(
            commonName: "Artichaut", scientificName: "Cynara scolymus", category: .potager,
            water: .moyen, sun: .soleil, soil: "Riche, profond, drainé",
            propagation: "Œilletons prélevés au printemps sur les pieds vigoureux.",
            conservation: "Cœurs en bocaux ou congelés ; têtes fraîches quelques jours.",
            sowingMonths: [3, 4], harvestMonths: [5, 6, 7, 8, 9], lifespanYears: 4,
            companions: ["Fève", "Laitue"], antagonists: [],
            averageYieldKg: 1.0, spreadM: 1.0,
            notes: "Butter et pailler pour l'hiver ; renouveler les pieds tous les 3–4 ans."
        ),
        SpeciesSeed(
            commonName: "Rhubarbe", scientificName: "Rheum rhabarbarum", category: .potager,
            water: .moyen, sun: .miOmbre, soil: "Riche, profond, frais",
            propagation: "Division de souche (un œil par éclat) d'octobre à mars.",
            conservation: "Compote stérilisée, congélation en tronçons, confiture.",
            sowingMonths: [10, 11, 2, 3], harvestMonths: [4, 5, 6, 9], lifespanYears: 10,
            companions: ["Chou pommé"], antagonists: [],
            averageYieldKg: 3.0, spreadM: 1.2,
            notes: "Ne récolter que les pétioles : les feuilles sont toxiques (mais utiles en purin)."
        ),
        SpeciesSeed(
            commonName: "Asperge", scientificName: "Asparagus officinalis", category: .potager,
            water: .moyen, sun: .soleil, soil: "Sableux, profond, drainé",
            propagation: "Griffes plantées en mars-avril dans des tranchées enrichies.",
            conservation: "Bocaux, congélation blanchie.",
            sowingMonths: [3, 4], harvestMonths: [4, 5, 6], lifespanYears: 12,
            companions: ["Tomate", "Persil"], antagonists: ["Ail", "Oignon"],
            averageYieldKg: 0.5, spreadM: 0.4,
            notes: "Patience : première vraie récolte la 3ᵉ année, puis 10 ans de production."
        ),
        SpeciesSeed(
            commonName: "Mâche", scientificName: "Valerianella locusta", category: .potager,
            water: .moyen, sun: .miOmbre, soil: "Ordinaire, plutôt tassé",
            propagation: "Semis direct d'août à octobre, plombé (sol raffermi).",
            conservation: "Consommation fraîche tout l'hiver.",
            sowingMonths: [8, 9, 10], harvestMonths: [10, 11, 12, 1, 2, 3], lifespanYears: 1,
            companions: ["Poireau", "Oignon"], antagonists: [],
            averageYieldKg: 0.3, spreadM: 0.1,
            notes: "Résiste au gel : récolter au fur et à mesure des besoins."
        ),
        SpeciesSeed(
            commonName: "Roquette", scientificName: "Eruca vesicaria", category: .potager,
            water: .moyen, sun: .miOmbre, soil: "Ordinaire, frais",
            propagation: "Semis direct de mars à septembre.",
            conservation: "Consommation rapide ; pesto de roquette.",
            sowingMonths: [3, 4, 5, 6, 7, 8, 9], harvestMonths: [4, 5, 6, 7, 8, 9, 10, 11], lifespanYears: 1,
            companions: ["Laitue", "Carotte"], antagonists: [],
            averageYieldKg: 0.4, spreadM: 0.15,
            notes: "Monte vite en été : semer à mi-ombre et arroser."
        ),
    ]

    // MARK: - Fruitiers

    static let fruitiers: [SpeciesSeed] = [
        SpeciesSeed(
            commonName: "Fraisier", scientificName: "Fragaria × ananassa", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Humifère, légèrement acide, drainé",
            propagation: "Repiquage des stolons en été, division.",
            conservation: "Confiture, congélation, séchage.",
            sowingMonths: [3, 8, 9], harvestMonths: [5, 6, 7, 8, 9], lifespanYears: 4,
            companions: ["Ail", "Épinard", "Laitue", "Thym"], antagonists: ["Chou pommé"],
            averageYieldKg: 0.8, spreadM: 0.3,
            notes: "Renouveler les pieds tous les 3–4 ans. Pailler pour garder les fruits propres."
        ),
        SpeciesSeed(
            commonName: "Framboisier", scientificName: "Rubus idaeus", category: .fruitier,
            water: .moyen, sun: .miOmbre, soil: "Humifère, frais, drainé",
            propagation: "Drageons prélevés en automne, bouture de racine.",
            conservation: "Congélation à plat, confiture, coulis.",
            sowingMonths: [11, 2, 3], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 10,
            companions: ["Myosotis", "Ail"], antagonists: ["Pomme de terre"],
            averageYieldKg: 1.5, spreadM: 0.5,
            notes: "Tailler les cannes ayant fructifié. Le myosotis éloigne le ver des framboises."
        ),
        SpeciesSeed(
            commonName: "Pommier", scientificName: "Malus domestica", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Profond, argilo-limoneux, frais",
            propagation: "Greffage sur porte-greffe (écussonnage en été, fente en hiver).",
            conservation: "Cave à fruits (0–4 °C), compote stérilisée, jus, séchage en lamelles.",
            sowingMonths: [11, 12, 1, 2], harvestMonths: [8, 9, 10, 11], lifespanYears: 50,
            companions: ["Capucine", "Ciboulette", "Lavande"], antagonists: ["Noisetier"],
            averageYieldKg: 25.0, spreadM: 4.0,
            notes: "Éclaircir les fruits en juin pour éviter l'alternance."
        ),
        SpeciesSeed(
            commonName: "Poirier", scientificName: "Pyrus communis", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Profond, frais, non calcaire de préférence",
            propagation: "Greffage sur cognassier (sols riches) ou franc (sols pauvres).",
            conservation: "Cave à fruits, bocaux au sirop, séchage.",
            sowingMonths: [12, 1, 2], harvestMonths: [8, 9, 10], lifespanYears: 40,
            companions: ["Capucine", "Ciboulette"], antagonists: [],
            averageYieldKg: 20.0, spreadM: 4.0,
            notes: "Cueillir avant complète maturité : les poires finissent de mûrir en cave."
        ),
        SpeciesSeed(
            commonName: "Cerisier", scientificName: "Prunus avium", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Profond, drainé, supporte le calcaire",
            propagation: "Greffage (les tailles sévères lui déplaisent).",
            conservation: "Confiture, congélation dénoyautée, bocaux, clafoutis congelés.",
            sowingMonths: [12, 1, 2], harvestMonths: [5, 6, 7], lifespanYears: 50,
            companions: ["Capucine"], antagonists: [],
            averageYieldKg: 15.0, spreadM: 5.0,
            notes: "Filet contre les oiseaux indispensable. Tailler peu, en vert (août)."
        ),
        SpeciesSeed(
            commonName: "Prunier", scientificName: "Prunus domestica", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Tous sols drainés",
            propagation: "Greffage, récupération de drageons sur francs de pied.",
            conservation: "Pruneaux séchés, confiture, congélation dénoyautée, eau-de-vie.",
            sowingMonths: [12, 1, 2], harvestMonths: [7, 8, 9], lifespanYears: 40,
            companions: ["Ciboulette"], antagonists: [],
            averageYieldKg: 15.0, spreadM: 4.0,
            notes: "Éclaircir en juin si la charge est excessive (branches cassantes)."
        ),
        SpeciesSeed(
            commonName: "Abricotier", scientificName: "Prunus armeniaca", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Drainé, calcaire accepté, chaud",
            propagation: "Greffage en écusson sur franc ou prunier.",
            conservation: "Confiture, oreillons congelés ou séchés, bocaux au sirop.",
            sowingMonths: [12, 1, 2], harvestMonths: [6, 7, 8], lifespanYears: 35,
            companions: ["Lavande"], antagonists: [],
            averageYieldKg: 12.0, spreadM: 4.0,
            notes: "Floraison très précoce : éviter les creux gélifs, voiler si gel annoncé."
        ),
        SpeciesSeed(
            commonName: "Pêcher", scientificName: "Prunus persica", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Léger, drainé, chaud",
            propagation: "Greffage en écusson ; semis de noyau possible (variétés de vigne).",
            conservation: "Bocaux au sirop, confiture, congélation en oreillons.",
            sowingMonths: [12, 1, 2], harvestMonths: [7, 8, 9], lifespanYears: 20,
            companions: ["Ail", "Œillet d'Inde"], antagonists: [],
            averageYieldKg: 10.0, spreadM: 3.5,
            notes: "Cloque du pêcher : pulvériser décoction de prêle dès février, ou planter de l'ail au pied."
        ),
        SpeciesSeed(
            commonName: "Figuier", scientificName: "Ficus carica", category: .fruitier,
            water: .faible, sun: .soleil, soil: "Drainé, même pauvre et caillouteux",
            propagation: "Bouture ligneuse et marcottage très faciles.",
            conservation: "Séchage, confiture, congélation entières.",
            sowingMonths: [3, 4, 11], harvestMonths: [7, 8, 9, 10], lifespanYears: 60,
            companions: [], antagonists: [],
            averageYieldKg: 12.0, spreadM: 4.0,
            notes: "En climat frais, choisir une variété unifère et un mur exposé sud."
        ),
        SpeciesSeed(
            commonName: "Olivier", scientificName: "Olea europaea", category: .fruitier,
            water: .faible, sun: .soleil, soil: "Caillouteux, très drainé, calcaire",
            propagation: "Bouture semi-ligneuse, greffage.",
            conservation: "Saumure (olives de table), moulin pour l'huile.",
            sowingMonths: [3, 4], harvestMonths: [10, 11, 12], lifespanYears: 100,
            companions: ["Lavande", "Thym"], antagonists: [],
            averageYieldKg: 8.0, spreadM: 4.0,
            notes: "Les olives se récoltent vertes (septembre) ou noires (novembre-décembre)."
        ),
        SpeciesSeed(
            commonName: "Vigne", scientificName: "Vitis vinifera", category: .fruitier,
            water: .faible, sun: .soleil, soil: "Caillouteux, drainé, pauvre",
            propagation: "Bouture de sarment (novembre-février), greffage sur porte-greffe résistant.",
            conservation: "Jus pasteurisé, raisins secs, gelée.",
            sowingMonths: [11, 12, 1, 2], harvestMonths: [8, 9, 10], lifespanYears: 40,
            companions: ["Origan", "Rosier"], antagonists: [],
            averageYieldKg: 5.0, spreadM: 1.5,
            notes: "Taille d'hiver stricte (2–3 yeux par sarment) : la vigne pleure mais produit."
        ),
        SpeciesSeed(
            commonName: "Kiwi", scientificName: "Actinidia deliciosa", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Riche, frais, non calcaire",
            propagation: "Marcottage, bouture semi-ligneuse en été.",
            conservation: "Cave fraîche 2–3 mois (récoltés durs), confiture.",
            sowingMonths: [3, 4], harvestMonths: [10, 11], lifespanYears: 30,
            companions: [], antagonists: [],
            averageYieldKg: 20.0, spreadM: 3.0,
            notes: "Liane vigoureuse : pergola solide, un pied mâle pour 4–5 femelles (ou autofertile)."
        ),
        SpeciesSeed(
            commonName: "Cassissier", scientificName: "Ribes nigrum", category: .fruitier,
            water: .moyen, sun: .miOmbre, soil: "Frais, riche, profond",
            propagation: "Bouture de bois sec en automne, très facile.",
            conservation: "Gelée, congélation, sirop, crème de cassis.",
            sowingMonths: [10, 11, 2], harvestMonths: [6, 7, 8], lifespanYears: 15,
            companions: ["Ail"], antagonists: [],
            averageYieldKg: 2.0, spreadM: 1.2,
            notes: "Rajeunir en supprimant chaque hiver les branches de plus de 3 ans."
        ),
        SpeciesSeed(
            commonName: "Groseillier", scientificName: "Ribes rubrum", category: .fruitier,
            water: .moyen, sun: .miOmbre, soil: "Frais, humifère",
            propagation: "Bouture de bois sec en automne.",
            conservation: "Gelée, congélation en grappes.",
            sowingMonths: [10, 11, 2], harvestMonths: [6, 7, 8], lifespanYears: 15,
            companions: ["Ail"], antagonists: [],
            averageYieldKg: 2.5, spreadM: 1.2,
            notes: "Craint la sécheresse : pailler généreusement."
        ),
        SpeciesSeed(
            commonName: "Myrtillier", scientificName: "Vaccinium corymbosum", category: .fruitier,
            water: .eleve, sun: .miOmbre, soil: "Acide (terre de bruyère), frais, drainé",
            propagation: "Bouture semi-ligneuse, marcottage.",
            conservation: "Congélation à plat, confiture, muffins congelés.",
            sowingMonths: [10, 11, 3], harvestMonths: [6, 7, 8, 9], lifespanYears: 20,
            companions: [], antagonists: [],
            averageYieldKg: 2.0, spreadM: 1.2,
            notes: "Arroser à l'eau de pluie uniquement (le calcaire le fait dépérir)."
        ),
        SpeciesSeed(
            commonName: "Noisetier", scientificName: "Corylus avellana", category: .fruitier,
            water: .faible, sun: .miOmbre, soil: "Tous sols, même calcaires",
            propagation: "Drageons, marcottage en automne.",
            conservation: "Séchage en coque, local aéré (plusieurs mois).",
            sowingMonths: [11, 2], harvestMonths: [9, 10], lifespanYears: 60,
            companions: [], antagonists: ["Pommier"],
            averageYieldKg: 4.0, spreadM: 3.0,
            notes: "Planter deux variétés pour la pollinisation croisée. Balanin : ramasser vite."
        ),
        SpeciesSeed(
            commonName: "Citronnier", scientificName: "Citrus limon", category: .fruitier,
            water: .moyen, sun: .soleil, soil: "Riche, drainé (pot : mélange agrumes)",
            propagation: "Greffage sur Poncirus ou bigaradier.",
            conservation: "Citrons confits au sel, zestes congelés, confiture.",
            sowingMonths: [3, 4], harvestMonths: [11, 12, 1, 2, 3], lifespanYears: 40,
            companions: [], antagonists: [],
            averageYieldKg: 15.0, spreadM: 2.5,
            notes: "Hors climat doux : culture en pot, hivernage lumineux hors gel (3–10 °C)."
        ),
    ]

    // MARK: - Fleurs

    static let fleurs: [SpeciesSeed] = [
        SpeciesSeed(
            commonName: "Lavande", scientificName: "Lavandula angustifolia", category: .fleur,
            water: .faible, sun: .soleil, soil: "Calcaire, sec, très drainé",
            propagation: "Bouture semi-ligneuse en août-septembre.",
            conservation: "Séchage en bouquets suspendus, sachets parfumés.",
            sowingMonths: [3, 4], harvestMonths: [6, 7, 8], lifespanYears: 15,
            companions: ["Rosier", "Thym", "Pommier"], antagonists: [],
            averageYieldKg: 0.3, spreadM: 0.8,
            notes: "Tailler chaque année sans toucher au vieux bois."
        ),
        SpeciesSeed(
            commonName: "Œillet d'Inde", scientificName: "Tagetes patula", category: .fleur,
            water: .moyen, sun: .soleil, soil: "Ordinaire",
            propagation: "Semis en godet en mars-avril, en place en mai.",
            conservation: "Fleurs séchées (infusions), graines récoltées à l'automne.",
            sowingMonths: [3, 4, 5], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Tomate", "Courgette", "Pomme de terre"], antagonists: [],
            averageYieldKg: 0.1, spreadM: 0.25,
            notes: "Répulsif nématodes et aleurodes : à intercaler partout au potager."
        ),
        SpeciesSeed(
            commonName: "Tournesol", scientificName: "Helianthus annuus", category: .fleur,
            water: .moyen, sun: .soleil, soil: "Profond, ordinaire",
            propagation: "Semis direct d'avril à juin.",
            conservation: "Capitules séchés tête en bas, graines grillées ou pour les oiseaux.",
            sowingMonths: [4, 5, 6], harvestMonths: [9, 10], lifespanYears: 1,
            companions: ["Maïs doux", "Concombre"], antagonists: ["Pomme de terre", "Laitue"],
            averageYieldKg: 0.5, spreadM: 0.4,
            notes: "Tuteurer les grandes variétés exposées au vent."
        ),
        SpeciesSeed(
            commonName: "Capucine", scientificName: "Tropaeolum majus", category: .fleur,
            water: .moyen, sun: .soleil, soil: "Pauvre (trop riche : que des feuilles)",
            propagation: "Semis direct en avril-juin.",
            conservation: "Boutons et graines en câpres lacto-fermentées ; fleurs fraîches en salade.",
            sowingMonths: [4, 5, 6], harvestMonths: [6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Courgette", "Pommier", "Tomate"], antagonists: [],
            averageYieldKg: 0.2, spreadM: 0.4,
            notes: "Aimant à pucerons : les concentre loin des légumes (plante-piège)."
        ),
        SpeciesSeed(
            commonName: "Bourrache", scientificName: "Borago officinalis", category: .fleur,
            water: .moyen, sun: .soleil, soil: "Ordinaire, frais",
            propagation: "Semis direct de mars à juin ; se ressème abondamment.",
            conservation: "Fleurs en glaçons décoratifs ; jeunes feuilles fraîches.",
            sowingMonths: [3, 4, 5, 6], harvestMonths: [5, 6, 7, 8, 9], lifespanYears: 1,
            companions: ["Fraisier", "Tomate", "Courgette"], antagonists: [],
            averageYieldKg: 0.2, spreadM: 0.4,
            notes: "Excellente plante mellifère : attire les pollinisateurs sur les cucurbitacées."
        ),
        SpeciesSeed(
            commonName: "Souci", scientificName: "Calendula officinalis", category: .fleur,
            water: .faible, sun: .soleil, soil: "Ordinaire",
            propagation: "Semis direct de mars à mai, ou septembre.",
            conservation: "Pétales séchés (infusions, macérât huileux).",
            sowingMonths: [3, 4, 5, 9], harvestMonths: [5, 6, 7, 8, 9, 10], lifespanYears: 1,
            companions: ["Tomate", "Chou pommé"], antagonists: [],
            averageYieldKg: 0.15, spreadM: 0.3,
            notes: "Se ressème seul ; fleurs comestibles et apaisantes en macérât."
        ),
    ]
}
