import JardinCore
import SwiftUI

/// Icônes de plantes dessinées paramétriquement (Canvas) : ~30 familles de
/// silhouettes, déclinées par couleurs et formes pour que **chaque espèce du
/// catalogue ait sa propre icône** (pommier ≠ cerisier ≠ citronnier…).
/// Toute nouvelle plante obtient une icône à la volée, sans asset.

public enum IconFamily: Sendable {
    case sprout, basil, mint, sprig, lavender
    case tomato, zucchini, cucumber, pepper, eggplant
    case carrot, radish, tuber, lettuce, leafyGreens
    case parsley, chives, leek, bulb
    case cabbage, corn, beans, pumpkin, melon
    case stalks, fennel, artichoke, asparagus
    case strawberry, berryBush, tree, grape, fig, flower
}

public struct PlantIconStyle: Sendable {
    public var leaf: Color = Theme.leaf
    public var leafLight: Color = Theme.lightGreen
    public var fruit: Color = Theme.tomatoRed
    public var accent: Color = Theme.olive
    public var fruitShape: FruitShape = .round

    public enum FruitShape: Sendable { case round, pear, oval, cherryPair, none }

    public init() {}

    static func with(leaf: Color? = nil, leafLight: Color? = nil,
                     fruit: Color? = nil, accent: Color? = nil,
                     fruitShape: FruitShape = .round) -> PlantIconStyle {
        var style = PlantIconStyle()
        if let leaf { style.leaf = leaf }
        if let leafLight { style.leafLight = leafLight }
        if let fruit { style.fruit = fruit }
        if let accent { style.accent = accent }
        style.fruitShape = fruitShape
        return style
    }
}

/// Associe chaque espèce (par mots-clés du nom) à sa famille + son style.
public enum IconCatalog {
    public static func descriptor(name: String?, category: PlantCategory) -> (family: IconFamily, style: PlantIconStyle) {
        let n = (name ?? "").folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        func has(_ needles: String...) -> Bool { needles.contains { n.contains($0) } }

        // Aromatiques
        if has("basilic") { return (.basil, .init()) }
        if has("sauge") { return (.basil, .with(leaf: Color(hex: "#7A8B6F"), leafLight: Color(hex: "#A9B7A0"))) }
        if has("menthe") { return (.mint, .init()) }
        if has("melisse") { return (.mint, .with(leaf: Color(hex: "#6FA86A"), leafLight: Color(hex: "#A9D8A2"))) }
        if has("origan", "marjolaine") { return (.mint, .with(accent: Theme.berryRose)) }
        if has("verveine") { return (.mint, .with(leaf: Color(hex: "#7FA84F"))) }
        if has("romarin") { return (.sprig, .with(leaf: Theme.olive)) }
        if has("thym", "sarriette") { return (.sprig, .init()) }
        if has("estragon") { return (.sprig, .with(leaf: Color(hex: "#8FB86A"))) }
        if has("lavande") { return (.lavender, .init()) }
        if has("persil", "cerfeuil") { return (.parsley, .init()) }
        if has("coriandre") { return (.parsley, .with(leaf: Color(hex: "#5FA35C"))) }
        if has("aneth") { return (.parsley, .with(leaf: Color(hex: "#A9B84A"))) }
        if has("ciboulette") { return (.chives, .init()) }
        if has("laurier") { return (.tree, .with(leaf: Color(hex: "#3E5A3C"), fruitShape: .none)) }

        // Choux et feuilles
        if has("chou-fleur", "chou fleur") { return (.cabbage, .with(fruit: Theme.beige, accent: Color(hex: "#EFEADB"))) }
        if has("brocoli") { return (.cabbage, .with(leaf: Color(hex: "#3E6B44"), fruit: Color(hex: "#2F5237"), accent: Color(hex: "#3E6B44"))) }
        if has("kale") { return (.cabbage, .with(leaf: Color(hex: "#41604A"), fruit: Color(hex: "#557D5B"), accent: Color(hex: "#41604A"))) }
        if has("chou") { return (.cabbage, .with(fruit: Theme.lightGreen, accent: Theme.leaf)) }
        if has("laitue", "salade", "batavia") { return (.lettuce, .init()) }
        if has("mache") { return (.lettuce, .with(leaf: Color(hex: "#3E6B44"), leafLight: Color(hex: "#5E8A62"))) }
        if has("epinard") { return (.leafyGreens, .init()) }
        if has("roquette") { return (.leafyGreens, .with(leaf: Color(hex: "#5F8A4A"))) }

        // Alliums, racines, tubercules
        if has("poireau") { return (.leek, .init()) }
        if has("oignon") { return (.bulb, .with(fruit: Color(hex: "#D9A05B"))) }
        if has("ail ") || n == "ail" { return (.bulb, .with(fruit: Color(hex: "#EFE8D5"))) }
        if has("echalote") { return (.bulb, .with(fruit: Color(hex: "#C98B5F"))) }
        if has("carotte") { return (.carrot, .with(fruit: Theme.carrotOrange)) }
        if has("panais") { return (.carrot, .with(fruit: Color(hex: "#EDE3C8"))) }
        if has("radis") { return (.radish, .with(fruit: Theme.berryRose)) }
        if has("navet") { return (.radish, .with(fruit: Color(hex: "#EDE8DC"), accent: Theme.aubergineViolet)) }
        if has("betterave") { return (.radish, .with(fruit: Color(hex: "#8E3B52"))) }
        if has("pomme de terre", "patate") { return (.tuber, .init()) }

        // Fruits du potager
        if has("tomate") { return (.tomato, .init()) }
        if has("poivron") { return (.pepper, .init()) }
        if has("piment") { return (.pepper, .with(fruit: Color(hex: "#C0392B"))) }
        if has("aubergine") { return (.eggplant, .init()) }
        if has("courgette") { return (.zucchini, .init()) }
        if has("butternut") { return (.zucchini, .with(leaf: Color(hex: "#E4C99A"), accent: Color(hex: "#C9A96E"))) }
        if has("concombre", "cornichon") { return (.cucumber, .init()) }
        if has("potiron", "citrouille", "courge") { return (.pumpkin, .init()) }
        if has("pasteque") { return (.melon, .with(fruit: Color(hex: "#4A7B4F"), accent: Color(hex: "#2F5237"))) }
        if has("melon") { return (.melon, .with(fruit: Color(hex: "#CDBE8A"), accent: Color(hex: "#A89B6A"))) }
        if has("mais") { return (.corn, .init()) }
        if has("petit pois", "pois ") || n == "pois" { return (.beans, .with(fruit: Color(hex: "#8FBF6A"), accent: Theme.leaf)) }
        if has("feve") { return (.beans, .with(fruit: Color(hex: "#5F7D4A"))) }
        if has("haricot") { return (.beans, .init()) }

        // Tiges, vivaces potagères
        if has("blette", "bette") { return (.stalks, .with(fruit: Color(hex: "#EFEADB"))) }
        if has("celeri") { return (.stalks, .with(fruit: Color(hex: "#9FBF7A"))) }
        if has("rhubarbe") { return (.stalks, .with(fruit: Color(hex: "#C25B5B"))) }
        if has("fenouil") { return (.fennel, .init()) }
        if has("artichaut") { return (.artichoke, .init()) }
        if has("asperge") { return (.asparagus, .init()) }

        // Petits fruits
        if has("fraise") { return (.strawberry, .init()) }
        if has("framboise") { return (.berryBush, .with(fruit: Theme.berryRose)) }
        if has("cassis") { return (.berryBush, .with(fruit: Color(hex: "#4A3B5C"))) }
        if has("groseille") { return (.berryBush, .with(fruit: Color(hex: "#D35D5D"))) }
        if has("myrtille") { return (.berryBush, .with(fruit: Color(hex: "#5A6FA8"))) }
        if has("mure", "murier") { return (.berryBush, .with(fruit: Color(hex: "#3E3450"))) }

        // Arbres et lianes
        if has("pommier") { return (.tree, .init()) }
        if has("poirier") { return (.tree, .with(fruit: Color(hex: "#A8B84A"), fruitShape: .pear)) }
        if has("cerisier") { return (.tree, .with(fruit: Color(hex: "#B23A48"), fruitShape: .cherryPair)) }
        if has("prunier") { return (.tree, .with(fruit: Theme.aubergineViolet, fruitShape: .oval)) }
        if has("abricotier") { return (.tree, .with(fruit: Color(hex: "#E8A85C"))) }
        if has("pecher") { return (.tree, .with(fruit: Color(hex: "#E88C6A"))) }
        if has("citron", "orange", "agrume", "mandarine") {
            return (.tree, .with(leaf: Color(hex: "#3E6B44"), fruit: Color(hex: "#E7D766"), fruitShape: .oval))
        }
        if has("olivier") { return (.tree, .with(leaf: Color(hex: "#7A8B6F"), fruit: Color(hex: "#4C5A44"), fruitShape: .oval)) }
        if has("noisetier", "amandier", "noyer") { return (.tree, .with(fruit: Color(hex: "#A97B4F"))) }
        if has("figuier") { return (.fig, .init()) }
        if has("vigne", "raisin") { return (.grape, .with(fruit: Theme.aubergineViolet)) }
        if has("kiwi") { return (.grape, .with(fruit: Color(hex: "#9A7B52"))) }

        // Fleurs
        if has("tournesol") { return (.flower, .with(fruit: Color(hex: "#E5C54B"), accent: Color(hex: "#7A5230"))) }
        if has("capucine") { return (.flower, .with(fruit: Color(hex: "#E08A3C"), accent: Color(hex: "#E5C54B"))) }
        if has("bourrache") { return (.flower, .with(fruit: Color(hex: "#6F86C8"), accent: Color(hex: "#3E4A6B"))) }
        if has("souci", "calendula") { return (.flower, .with(fruit: Color(hex: "#E5A13C"), accent: Theme.carrotOrange)) }
        if has("oeillet") { return (.flower, .with(fruit: Theme.carrotOrange, accent: Color(hex: "#7A5230"))) }
        if has("rose", "tulipe", "fleur") { return (.flower, .init()) }

        switch category {
        case .fruitier: return (.tree, .init())
        case .fleur: return (.flower, .init())
        case .aromatique: return (.basil, .init())
        case .potager, .autre: return (.sprout, .init())
        }
    }
}

public struct PlantIconView: View {
    let family: IconFamily
    let style: PlantIconStyle
    let size: CGFloat

    public init(name: String?, category: PlantCategory, size: CGFloat = 44) {
        let descriptor = IconCatalog.descriptor(name: name, category: category)
        self.family = descriptor.family
        self.style = descriptor.style
        self.size = size
    }

    public init(plant: PlantMO, size: CGFloat = 44) {
        self.init(name: plant.species?.commonName ?? plant.name, category: plant.category, size: size)
    }

    public init(species: PlantSpeciesMO, size: CGFloat = 44) {
        self.init(name: species.commonName, category: species.category, size: size)
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
                .insetBy(dx: canvasSize.width * 0.08, dy: canvasSize.height * 0.08)
            IconPainter.draw(family, style: style, in: rect, context: &context)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Primitives de dessin partagées par toutes les familles.
enum IconPainter {
    static func draw(_ family: IconFamily, style: PlantIconStyle, in rect: CGRect, context: inout GraphicsContext) {
        switch family {
        case .sprout: sprout(rect, style, &context)
        case .basil: basil(rect, style, &context)
        case .mint: mint(rect, style, &context)
        case .sprig: sprig(rect, style, &context)
        case .lavender: lavender(rect, style, &context)
        case .tomato: tomato(rect, style, &context)
        case .zucchini: zucchini(rect, style, &context)
        case .cucumber: cucumber(rect, style, &context)
        case .pepper: pepper(rect, style, &context)
        case .eggplant: eggplant(rect, style, &context)
        case .carrot: carrot(rect, style, &context)
        case .radish: radish(rect, style, &context)
        case .tuber: tuber(rect, style, &context)
        case .lettuce: lettuce(rect, style, &context)
        case .leafyGreens: leafyGreens(rect, style, &context)
        case .parsley: parsley(rect, style, &context)
        case .chives: chives(rect, style, &context)
        case .leek: leek(rect, style, &context)
        case .bulb: bulb(rect, style, &context)
        case .cabbage: cabbage(rect, style, &context)
        case .corn: corn(rect, style, &context)
        case .beans: beans(rect, style, &context)
        case .pumpkin: pumpkin(rect, style, &context)
        case .melon: melon(rect, style, &context)
        case .stalks: stalks(rect, style, &context)
        case .fennel: fennel(rect, style, &context)
        case .artichoke: artichoke(rect, style, &context)
        case .asparagus: asparagus(rect, style, &context)
        case .strawberry: strawberry(rect, style, &context)
        case .berryBush: berryBush(rect, style, &context)
        case .tree: tree(rect, style, &context)
        case .grape: grape(rect, style, &context)
        case .fig: fig(rect, style, &context)
        case .flower: flower(rect, style, &context)
        }
    }

    static func point(_ rect: CGRect, _ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
    }

    static func leaf(_ rect: CGRect, from base: CGPoint, to tip: CGPoint, width: CGFloat) -> Path {
        var path = Path()
        let dx = tip.x - base.x, dy = tip.y - base.y
        let mid = CGPoint(x: (base.x + tip.x) / 2, y: (base.y + tip.y) / 2)
        let length = max(sqrt(dx * dx + dy * dy), 0.001)
        let offset = CGPoint(x: -dy / length * width, y: dx / length * width)
        path.move(to: base)
        path.addQuadCurve(to: tip, control: CGPoint(x: mid.x + offset.x, y: mid.y + offset.y))
        path.addQuadCurve(to: base, control: CGPoint(x: mid.x - offset.x, y: mid.y - offset.y))
        path.closeSubpath()
        return path
    }

    static func stem(_ rect: CGRect, from: CGPoint, to: CGPoint, _ context: inout GraphicsContext,
                     color: Color = Theme.olive, width: CGFloat = 0.045) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: rect.width * width, lineCap: .round))
    }

    static func circle(_ rect: CGRect, cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
        let center = point(rect, cx, cy)
        return Path(ellipseIn: CGRect(x: center.x - rect.width * r, y: center.y - rect.height * r,
                                      width: rect.width * r * 2, height: rect.height * r * 2))
    }

    // MARK: Familles historiques

    static func sprout(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.45), &c, color: s.accent)
        c.fill(leaf(r, from: point(r, 0.5, 0.55), to: point(r, 0.18, 0.25), width: r.width * 0.16), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.5), to: point(r, 0.85, 0.15), width: r.width * 0.18), with: .color(s.leafLight))
    }

    static func basil(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.35), &c, color: s.accent)
        c.fill(leaf(r, from: point(r, 0.5, 0.75), to: point(r, 0.14, 0.55), width: r.width * 0.17), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.75), to: point(r, 0.86, 0.55), width: r.width * 0.17), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.45), to: point(r, 0.22, 0.18), width: r.width * 0.16), with: .color(s.leafLight))
        c.fill(leaf(r, from: point(r, 0.5, 0.45), to: point(r, 0.78, 0.18), width: r.width * 0.16), with: .color(s.leafLight))
        c.fill(leaf(r, from: point(r, 0.5, 0.4), to: point(r, 0.5, 0.05), width: r.width * 0.14), with: .color(s.leaf))
    }

    static func mint(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.2), &c, color: s.accent)
        for (index, y) in [0.72, 0.52, 0.32].enumerated() {
            let spread = 0.36 - CGFloat(index) * 0.06
            let (c1, c2) = index % 2 == 0 ? (s.leaf, s.accent) : (s.accent, s.leaf)
            c.fill(leaf(r, from: point(r, 0.5, y), to: point(r, 0.5 - spread, y - 0.16), width: r.width * 0.13), with: .color(c1))
            c.fill(leaf(r, from: point(r, 0.5, y), to: point(r, 0.5 + spread, y - 0.16), width: r.width * 0.13), with: .color(c2))
        }
        c.fill(leaf(r, from: point(r, 0.5, 0.24), to: point(r, 0.5, 0.02), width: r.width * 0.11), with: .color(s.leafLight))
    }

    static func sprig(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.35, 0.95), to: point(r, 0.62, 0.08), &c, color: Theme.olive, width: 0.04)
        for step in 0..<7 {
            let t = 0.15 + CGFloat(step) * 0.11
            let baseX = 0.35 + (0.62 - 0.35) * (1 - t)
            let base = point(r, baseX, 0.95 - t * 0.87 + 0.05)
            c.fill(leaf(r, from: base, to: CGPoint(x: base.x - r.width * 0.2, y: base.y - r.height * 0.1),
                        width: r.width * 0.045), with: .color(s.leaf))
            c.fill(leaf(r, from: base, to: CGPoint(x: base.x + r.width * 0.16, y: base.y - r.height * 0.14),
                        width: r.width * 0.045), with: .color(s.leaf.opacity(0.8)))
        }
    }

    static func lavender(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.45), &c, color: s.leaf)
        c.fill(leaf(r, from: point(r, 0.5, 0.85), to: point(r, 0.28, 0.62), width: r.width * 0.06), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.8), to: point(r, 0.72, 0.58), width: r.width * 0.06), with: .color(s.leaf))
        for row in 0..<4 {
            let y = 0.42 - CGFloat(row) * 0.1
            let width = 0.16 - CGFloat(row) * 0.03
            let color = row % 2 == 0 ? Theme.flowerLilac : Theme.aubergineViolet.opacity(0.85)
            var capsule = Path()
            capsule.addEllipse(in: CGRect(x: point(r, 0.5 - width, y).x, y: point(r, 0, y - 0.045).y,
                                          width: r.width * width * 2, height: r.height * 0.095))
            c.fill(capsule, with: .color(color))
        }
    }

    static func tomato(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        let body = CGRect(x: point(r, 0.14, 0).x, y: point(r, 0, 0.3).y,
                          width: r.width * 0.72, height: r.height * 0.62)
        c.fill(Path(ellipseIn: body), with: .color(s.fruit))
        c.fill(Path(ellipseIn: body.insetBy(dx: body.width * 0.16, dy: body.height * 0.16)
                .offsetBy(dx: -body.width * 0.1, dy: -body.height * 0.1)),
               with: .color(.white.opacity(0.12)))
        for angle in [-0.9, -0.3, 0.3, 0.9] {
            let tip = CGPoint(x: point(r, 0.5, 0.33).x + CGFloat(cos(angle - .pi / 2)) * r.width * 0.2,
                              y: point(r, 0.5, 0.33).y + CGFloat(sin(angle - .pi / 2)) * r.height * 0.16 + r.height * 0.12)
            c.fill(leaf(r, from: point(r, 0.5, 0.34), to: tip, width: r.width * 0.05), with: .color(s.accent))
        }
        stem(r, from: point(r, 0.5, 0.3), to: point(r, 0.5, 0.12), &c, color: s.accent, width: 0.05)
    }

    static func zucchini(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var body = Path()
        body.move(to: point(r, 0.16, 0.82))
        body.addQuadCurve(to: point(r, 0.82, 0.3), control: point(r, 0.2, 0.25))
        body.addQuadCurve(to: point(r, 0.3, 0.92), control: point(r, 0.95, 0.85))
        body.closeSubpath()
        c.fill(body, with: .color(s.leaf))
        stem(r, from: point(r, 0.82, 0.3), to: point(r, 0.92, 0.16), &c, width: 0.05)
        var stripe = Path()
        stripe.move(to: point(r, 0.26, 0.78))
        stripe.addQuadCurve(to: point(r, 0.74, 0.4), control: point(r, 0.35, 0.42))
        c.stroke(stripe, with: .color(s.leafLight.opacity(0.7)), lineWidth: r.width * 0.035)
    }

    static func cucumber(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var body = Path()
        body.addRoundedRect(in: CGRect(x: point(r, 0.2, 0).x, y: point(r, 0, 0.18).y,
                                       width: r.width * 0.26, height: r.height * 0.72),
                            cornerSize: CGSize(width: r.width * 0.13, height: r.width * 0.13))
        c.fill(body, with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.42, 0.3), to: point(r, 0.82, 0.12), width: r.width * 0.16), with: .color(s.leafLight))
        var tendril = Path()
        tendril.move(to: point(r, 0.46, 0.5))
        tendril.addQuadCurve(to: point(r, 0.8, 0.55), control: point(r, 0.72, 0.38))
        c.stroke(tendril, with: .color(s.accent), style: StrokeStyle(lineWidth: r.width * 0.03, lineCap: .round))
    }

    static func pepper(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var body = Path()
        body.addRoundedRect(in: CGRect(x: point(r, 0.28, 0).x, y: point(r, 0, 0.28).y,
                                       width: r.width * 0.44, height: r.height * 0.62),
                            cornerSize: CGSize(width: r.width * 0.18, height: r.height * 0.2))
        c.fill(body, with: .color(s.fruit))
        c.fill(leaf(r, from: point(r, 0.5, 0.3), to: point(r, 0.66, 0.14), width: r.width * 0.07), with: .color(s.leaf))
        stem(r, from: point(r, 0.5, 0.28), to: point(r, 0.48, 0.1), &c, width: 0.05)
        var groove = Path()
        groove.move(to: point(r, 0.44, 0.34))
        groove.addQuadCurve(to: point(r, 0.44, 0.84), control: point(r, 0.4, 0.6))
        c.stroke(groove, with: .color(.white.opacity(0.15)), lineWidth: r.width * 0.03)
    }

    static func eggplant(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var body = Path()
        body.move(to: point(r, 0.58, 0.22))
        body.addQuadCurve(to: point(r, 0.72, 0.75), control: point(r, 0.85, 0.4))
        body.addQuadCurve(to: point(r, 0.35, 0.9), control: point(r, 0.6, 1.0))
        body.addQuadCurve(to: point(r, 0.58, 0.22), control: point(r, 0.2, 0.45))
        c.fill(body, with: .color(Theme.aubergineViolet))
        c.fill(leaf(r, from: point(r, 0.58, 0.24), to: point(r, 0.4, 0.12), width: r.width * 0.08), with: .color(s.leaf))
        stem(r, from: point(r, 0.6, 0.22), to: point(r, 0.66, 0.08), &c, width: 0.045)
    }

    static func carrot(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var root = Path()
        root.move(to: point(r, 0.34, 0.35))
        root.addQuadCurve(to: point(r, 0.5, 0.95), control: point(r, 0.36, 0.75))
        root.addQuadCurve(to: point(r, 0.66, 0.35), control: point(r, 0.64, 0.75))
        root.closeSubpath()
        c.fill(root, with: .color(s.fruit))
        c.fill(leaf(r, from: point(r, 0.5, 0.36), to: point(r, 0.26, 0.06), width: r.width * 0.1), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.36), to: point(r, 0.5, 0.02), width: r.width * 0.09), with: .color(s.leafLight))
        c.fill(leaf(r, from: point(r, 0.5, 0.36), to: point(r, 0.74, 0.06), width: r.width * 0.1), with: .color(s.leaf))
    }

    static func radish(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        c.fill(circle(r, cx: 0.5, cy: 0.63, r: 0.21), with: .color(s.fruit))
        stem(r, from: point(r, 0.5, 0.84), to: point(r, 0.5, 0.95), &c, color: s.fruit, width: 0.03)
        c.fill(leaf(r, from: point(r, 0.5, 0.45), to: point(r, 0.32, 0.08), width: r.width * 0.11), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.45), to: point(r, 0.68, 0.08), width: r.width * 0.11), with: .color(s.leafLight))
    }

    static func lettuce(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        let base = point(r, 0.5, 0.9)
        for (index, angle) in [-1.2, -0.6, 0.0, 0.6, 1.2].enumerated() {
            let tip = CGPoint(x: base.x + CGFloat(sin(angle)) * r.width * 0.4,
                              y: base.y - r.height * (0.75 - abs(CGFloat(angle)) * 0.12))
            c.fill(leaf(r, from: base, to: tip, width: r.width * 0.16),
                   with: .color(index % 2 == 0 ? s.leafLight : s.leaf))
        }
        c.fill(leaf(r, from: base, to: point(r, 0.5, 0.3), width: r.width * 0.14), with: .color(Theme.beige))
    }

    static func leafyGreens(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        let base = point(r, 0.5, 0.92)
        for (index, angle) in [-0.8, 0.0, 0.8].enumerated() {
            let tip = CGPoint(x: base.x + CGFloat(sin(angle)) * r.width * 0.32, y: base.y - r.height * 0.8)
            c.fill(leaf(r, from: base, to: tip, width: r.width * 0.18),
                   with: .color(index == 1 ? s.leaf : s.accent))
        }
    }

    static func parsley(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        for angle in [-0.5, 0.0, 0.5] {
            let base = point(r, 0.5, 0.95)
            let top = CGPoint(x: base.x + CGFloat(sin(angle)) * r.width * 0.3, y: base.y - r.height * 0.6)
            stem(r, from: base, to: top, &c, color: s.leaf, width: 0.03)
            for cluster in [(-0.12, -0.1), (0.12, -0.1), (0.0, -0.18)] {
                c.fill(Path(ellipseIn: CGRect(x: top.x + r.width * cluster.0 - r.width * 0.09,
                                              y: top.y + r.height * cluster.1 - r.height * 0.09,
                                              width: r.width * 0.18, height: r.height * 0.18)),
                       with: .color(s.leaf.opacity(0.9)))
            }
        }
    }

    static func chives(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        for (index, x) in [0.3, 0.42, 0.54, 0.66].enumerated() {
            let bend = CGFloat(index % 2 == 0 ? -0.06 : 0.06)
            var blade = Path()
            blade.move(to: point(r, x, 0.95))
            blade.addQuadCurve(to: point(r, x + bend, 0.1 + CGFloat(index) * 0.04),
                               control: point(r, x + bend * 2, 0.5))
            c.stroke(blade, with: .color(index % 2 == 0 ? s.leaf : s.accent),
                     style: StrokeStyle(lineWidth: r.width * 0.05, lineCap: .round))
        }
        c.fill(circle(r, cx: 0.3, cy: 0.1, r: 0.06), with: .color(Theme.flowerLilac))
    }

    static func strawberry(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var berry = Path()
        berry.move(to: point(r, 0.2, 0.4))
        berry.addQuadCurve(to: point(r, 0.5, 0.95), control: point(r, 0.22, 0.85))
        berry.addQuadCurve(to: point(r, 0.8, 0.4), control: point(r, 0.78, 0.85))
        berry.addQuadCurve(to: point(r, 0.2, 0.4), control: point(r, 0.5, 0.28))
        c.fill(berry, with: .color(s.fruit))
        for seed in [(0.38, 0.55), (0.55, 0.62), (0.45, 0.75), (0.62, 0.5)] {
            c.fill(Path(ellipseIn: CGRect(x: point(r, seed.0, 0).x, y: point(r, 0, seed.1).y,
                                          width: r.width * 0.04, height: r.height * 0.055)),
                   with: .color(Theme.beige))
        }
        c.fill(leaf(r, from: point(r, 0.5, 0.38), to: point(r, 0.3, 0.22), width: r.width * 0.08), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.38), to: point(r, 0.7, 0.22), width: r.width * 0.08), with: .color(s.leaf))
        stem(r, from: point(r, 0.5, 0.36), to: point(r, 0.5, 0.14), &c, width: 0.04)
    }

    static func berryBush(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.5), &c, color: s.accent, width: 0.04)
        c.fill(leaf(r, from: point(r, 0.5, 0.7), to: point(r, 0.24, 0.5), width: r.width * 0.12), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.62), to: point(r, 0.76, 0.42), width: r.width * 0.12), with: .color(s.leaf))
        let centers: [(CGFloat, CGFloat)] = [(0.42, 0.3), (0.58, 0.3), (0.36, 0.42), (0.5, 0.4), (0.64, 0.42), (0.44, 0.52), (0.58, 0.52)]
        for (cx, cy) in centers {
            c.fill(circle(r, cx: cx, cy: cy, r: 0.075), with: .color(s.fruit))
        }
    }

    static func tree(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var trunk = Path()
        trunk.move(to: point(r, 0.44, 0.95))
        trunk.addLine(to: point(r, 0.47, 0.5))
        trunk.addLine(to: point(r, 0.53, 0.5))
        trunk.addLine(to: point(r, 0.56, 0.95))
        trunk.closeSubpath()
        c.fill(trunk, with: .color(Theme.wood))
        c.fill(Path(ellipseIn: CGRect(x: point(r, 0.15, 0).x, y: point(r, 0, 0.08).y,
                                      width: r.width * 0.7, height: r.height * 0.52)),
               with: .color(s.leaf))
        c.fill(Path(ellipseIn: CGRect(x: point(r, 0.28, 0).x, y: point(r, 0, 0.02).y,
                                      width: r.width * 0.36, height: r.height * 0.28)),
               with: .color(s.leafLight.opacity(0.65)))

        switch s.fruitShape {
        case .round:
            c.fill(circle(r, cx: 0.63, cy: 0.34, r: 0.05), with: .color(s.fruit))
            c.fill(circle(r, cx: 0.36, cy: 0.26, r: 0.05), with: .color(s.fruit))
        case .oval:
            for (cx, cy) in [(0.62, 0.33), (0.35, 0.25)] {
                let center = point(r, CGFloat(cx), CGFloat(cy))
                c.fill(Path(ellipseIn: CGRect(x: center.x - r.width * 0.04, y: center.y - r.height * 0.06,
                                              width: r.width * 0.08, height: r.height * 0.12)),
                       with: .color(s.fruit))
            }
        case .pear:
            for (cx, cy) in [(0.62, 0.33), (0.35, 0.25)] {
                var pear = Path()
                let p = point(r, CGFloat(cx), CGFloat(cy))
                pear.move(to: CGPoint(x: p.x, y: p.y - r.height * 0.07))
                pear.addQuadCurve(to: CGPoint(x: p.x + r.width * 0.045, y: p.y + r.height * 0.05),
                                  control: CGPoint(x: p.x + r.width * 0.055, y: p.y - r.height * 0.01))
                pear.addQuadCurve(to: CGPoint(x: p.x - r.width * 0.045, y: p.y + r.height * 0.05),
                                  control: CGPoint(x: p.x, y: p.y + r.height * 0.09))
                pear.addQuadCurve(to: CGPoint(x: p.x, y: p.y - r.height * 0.07),
                                  control: CGPoint(x: p.x - r.width * 0.055, y: p.y - r.height * 0.01))
                c.fill(pear, with: .color(s.fruit))
            }
        case .cherryPair:
            c.fill(circle(r, cx: 0.56, cy: 0.4, r: 0.045), with: .color(s.fruit))
            c.fill(circle(r, cx: 0.64, cy: 0.37, r: 0.045), with: .color(s.fruit))
            stem(r, from: point(r, 0.56, 0.36), to: point(r, 0.6, 0.24), &c, color: s.accent, width: 0.018)
            stem(r, from: point(r, 0.64, 0.33), to: point(r, 0.6, 0.24), &c, color: s.accent, width: 0.018)
        case .none:
            break
        }
    }

    static func flower(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.5), &c, color: s.leaf)
        c.fill(leaf(r, from: point(r, 0.5, 0.8), to: point(r, 0.3, 0.66), width: r.width * 0.08), with: .color(s.leaf))
        let center = point(r, 0.5, 0.32)
        let petalColor = s.fruit == Theme.tomatoRed ? Theme.flowerLilac : s.fruit
        for petalIndex in 0..<8 {
            let angle = Double(petalIndex) / 8 * 2 * .pi
            let tip = CGPoint(x: center.x + CGFloat(cos(angle)) * r.width * 0.22,
                              y: center.y + CGFloat(sin(angle)) * r.height * 0.22)
            c.fill(leaf(r, from: center, to: tip, width: r.width * 0.08), with: .color(petalColor))
        }
        c.fill(circle(r, cx: 0.5, cy: 0.32, r: 0.09), with: .color(s.accent))
    }

    // MARK: Nouvelles familles

    static func cabbage(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        for angle in [-1.1, -0.55, 0.55, 1.1] {
            let base = point(r, 0.5, 0.85)
            let tip = CGPoint(x: base.x + CGFloat(sin(angle)) * r.width * 0.42,
                              y: base.y - r.height * 0.55)
            c.fill(leaf(r, from: base, to: tip, width: r.width * 0.2), with: .color(s.leaf))
        }
        c.fill(circle(r, cx: 0.5, cy: 0.52, r: 0.3), with: .color(s.fruit))
        var vein = Path()
        vein.move(to: point(r, 0.5, 0.78))
        vein.addQuadCurve(to: point(r, 0.5, 0.3), control: point(r, 0.38, 0.5))
        c.stroke(vein, with: .color(s.accent.opacity(0.5)), lineWidth: r.width * 0.03)
    }

    static func leek(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var white = Path()
        white.addRoundedRect(in: CGRect(x: point(r, 0.42, 0).x, y: point(r, 0, 0.55).y,
                                        width: r.width * 0.16, height: r.height * 0.4),
                             cornerSize: CGSize(width: r.width * 0.05, height: r.width * 0.05))
        c.fill(white, with: .color(Theme.beige))
        c.fill(leaf(r, from: point(r, 0.47, 0.58), to: point(r, 0.2, 0.08), width: r.width * 0.09), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.56), to: point(r, 0.5, 0.04), width: r.width * 0.09), with: .color(s.accent))
        c.fill(leaf(r, from: point(r, 0.53, 0.58), to: point(r, 0.8, 0.08), width: r.width * 0.09), with: .color(s.leaf))
    }

    static func bulb(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var body = Path()
        body.move(to: point(r, 0.5, 0.3))
        body.addQuadCurve(to: point(r, 0.5, 0.9), control: point(r, 0.9, 0.55))
        body.addQuadCurve(to: point(r, 0.5, 0.3), control: point(r, 0.1, 0.55))
        c.fill(body, with: .color(s.fruit))
        var lines = Path()
        lines.move(to: point(r, 0.42, 0.4))
        lines.addQuadCurve(to: point(r, 0.44, 0.82), control: point(r, 0.34, 0.6))
        lines.move(to: point(r, 0.58, 0.4))
        lines.addQuadCurve(to: point(r, 0.56, 0.82), control: point(r, 0.66, 0.6))
        c.stroke(lines, with: .color(.black.opacity(0.1)), lineWidth: r.width * 0.02)
        c.fill(leaf(r, from: point(r, 0.5, 0.32), to: point(r, 0.36, 0.05), width: r.width * 0.06), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.32), to: point(r, 0.62, 0.05), width: r.width * 0.06), with: .color(s.leafLight))
        stem(r, from: point(r, 0.5, 0.9), to: point(r, 0.5, 0.96), &c, color: Theme.wood, width: 0.02)
    }

    static func tuber(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.55), to: point(r, 0.5, 0.25), &c, color: s.leaf, width: 0.035)
        c.fill(leaf(r, from: point(r, 0.5, 0.4), to: point(r, 0.3, 0.15), width: r.width * 0.1), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.35), to: point(r, 0.7, 0.1), width: r.width * 0.1), with: .color(s.leafLight))
        var soil = Path()
        soil.move(to: point(r, 0.1, 0.58))
        soil.addLine(to: point(r, 0.9, 0.58))
        c.stroke(soil, with: .color(Theme.wood.opacity(0.7)),
                 style: StrokeStyle(lineWidth: r.width * 0.025, dash: [4, 3]))
        for (cx, cy, rr) in [(0.35, 0.75, 0.13), (0.62, 0.72, 0.11), (0.5, 0.88, 0.1)] {
            let center = point(r, CGFloat(cx), CGFloat(cy))
            c.fill(Path(ellipseIn: CGRect(x: center.x - r.width * CGFloat(rr) * 1.2,
                                          y: center.y - r.height * CGFloat(rr) * 0.85,
                                          width: r.width * CGFloat(rr) * 2.4,
                                          height: r.height * CGFloat(rr) * 1.7)),
                   with: .color(Color(hex: "#C9A876")))
        }
    }

    static func corn(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.42, 0.95), to: point(r, 0.42, 0.1), &c, color: s.leaf, width: 0.04)
        c.fill(leaf(r, from: point(r, 0.42, 0.75), to: point(r, 0.12, 0.5), width: r.width * 0.09), with: .color(s.leaf))
        c.fill(leaf(r, from: point(r, 0.42, 0.55), to: point(r, 0.72, 0.32), width: r.width * 0.09), with: .color(s.leafLight))
        var cob = Path()
        cob.addRoundedRect(in: CGRect(x: point(r, 0.52, 0).x, y: point(r, 0, 0.34).y,
                                      width: r.width * 0.17, height: r.height * 0.36),
                           cornerSize: CGSize(width: r.width * 0.085, height: r.width * 0.085))
        c.fill(cob, with: .color(Color(hex: "#E5C54B")))
        for row in 0..<3 {
            var grains = Path()
            let x = 0.555 + CGFloat(row) * 0.05
            grains.move(to: point(r, x, 0.38))
            grains.addLine(to: point(r, x, 0.66))
            c.stroke(grains, with: .color(.black.opacity(0.1)), lineWidth: r.width * 0.012)
        }
        c.fill(leaf(r, from: point(r, 0.52, 0.68), to: point(r, 0.72, 0.3), width: r.width * 0.05),
               with: .color(s.leaf.opacity(0.8)))
    }

    static func beans(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        for (index, offset) in [-0.14, 0.0, 0.14].enumerated() {
            var pod = Path()
            pod.move(to: point(r, 0.3 + offset, 0.2))
            pod.addQuadCurve(to: point(r, 0.55 + offset, 0.9), control: point(r, 0.28 + offset, 0.65))
            pod.addQuadCurve(to: point(r, 0.36 + offset, 0.22), control: point(r, 0.5 + offset, 0.6))
            pod.closeSubpath()
            c.fill(pod, with: .color(index == 1 ? s.fruit : s.accent))
        }
        stem(r, from: point(r, 0.32, 0.18), to: point(r, 0.62, 0.12), &c, width: 0.035)
    }

    static func pumpkin(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        let body = CGRect(x: point(r, 0.12, 0).x, y: point(r, 0, 0.32).y,
                          width: r.width * 0.76, height: r.height * 0.58)
        c.fill(Path(ellipseIn: body), with: .color(Theme.carrotOrange))
        for inset in [0.18, 0.32] {
            c.fill(Path(ellipseIn: body.insetBy(dx: body.width * CGFloat(inset), dy: 0)),
                   with: .color(.black.opacity(0.06)))
        }
        stem(r, from: point(r, 0.5, 0.32), to: point(r, 0.54, 0.14), &c, width: 0.05)
        c.fill(leaf(r, from: point(r, 0.52, 0.24), to: point(r, 0.72, 0.1), width: r.width * 0.07), with: .color(s.leaf))
    }

    static func melon(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        c.fill(circle(r, cx: 0.5, cy: 0.58, r: 0.34), with: .color(s.fruit))
        for x in [0.36, 0.5, 0.64] {
            var stripe = Path()
            stripe.move(to: point(r, x, 0.26))
            stripe.addQuadCurve(to: point(r, x, 0.9), control: point(r, x < 0.5 ? x - 0.1 : (x > 0.5 ? x + 0.1 : x), 0.58))
            c.stroke(stripe, with: .color(s.accent.opacity(0.8)), lineWidth: r.width * 0.03)
        }
        stem(r, from: point(r, 0.5, 0.24), to: point(r, 0.44, 0.1), &c, width: 0.04)
        c.fill(leaf(r, from: point(r, 0.5, 0.2), to: point(r, 0.68, 0.08), width: r.width * 0.07), with: .color(s.leaf))
    }

    static func stalks(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        for (index, x) in [0.36, 0.5, 0.64].enumerated() {
            var stalk = Path()
            stalk.addRoundedRect(in: CGRect(x: point(r, x - 0.05, 0).x, y: point(r, 0, 0.42).y,
                                            width: r.width * 0.1, height: r.height * 0.52),
                                 cornerSize: CGSize(width: r.width * 0.04, height: r.width * 0.04))
            c.fill(stalk, with: .color(s.fruit.opacity(index == 1 ? 1 : 0.85)))
            let tip = point(r, x, 0.42)
            c.fill(leaf(r, from: tip, to: CGPoint(x: tip.x + CGFloat(index - 1) * r.width * 0.14,
                                                  y: tip.y - r.height * 0.32),
                        width: r.width * 0.11), with: .color(index % 2 == 0 ? s.leaf : s.leafLight))
        }
    }

    static func fennel(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        var bulbShape = Path()
        bulbShape.move(to: point(r, 0.32, 0.55))
        bulbShape.addQuadCurve(to: point(r, 0.68, 0.55), control: point(r, 0.5, 0.42))
        bulbShape.addQuadCurve(to: point(r, 0.5, 0.95), control: point(r, 0.74, 0.9))
        bulbShape.addQuadCurve(to: point(r, 0.32, 0.55), control: point(r, 0.26, 0.9))
        c.fill(bulbShape, with: .color(Theme.beige))
        var layers = Path()
        layers.move(to: point(r, 0.44, 0.55))
        layers.addQuadCurve(to: point(r, 0.46, 0.88), control: point(r, 0.38, 0.72))
        layers.move(to: point(r, 0.56, 0.55))
        layers.addQuadCurve(to: point(r, 0.54, 0.88), control: point(r, 0.62, 0.72))
        c.stroke(layers, with: .color(s.leaf.opacity(0.25)), lineWidth: r.width * 0.02)
        for angle in [-0.5, -0.15, 0.15, 0.5] {
            let base = point(r, 0.5, 0.52)
            let top = CGPoint(x: base.x + CGFloat(angle) * r.width * 0.55, y: base.y - r.height * 0.42)
            stem(r, from: base, to: top, &c, color: s.leaf, width: 0.022)
            c.fill(circle(r, cx: 0.5 + CGFloat(angle) * 0.55, cy: 0.1, r: 0.045), with: .color(s.leafLight.opacity(0.8)))
        }
    }

    static func artichoke(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.72), &c, color: s.leaf, width: 0.05)
        let rows: [(CGFloat, CGFloat, Int)] = [(0.68, 0.24, 4), (0.52, 0.2, 3), (0.38, 0.15, 2)]
        for (rowIndex, row) in rows.enumerated() {
            let (y, spread, count) = row
            for i in 0..<count {
                let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
                let x = 0.5 + (t - 0.5) * spread * 2
                let base = point(r, x, y)
                let tip = CGPoint(x: base.x + (x - 0.5) * r.width * 0.3, y: base.y - r.height * 0.18)
                c.fill(leaf(r, from: base, to: tip, width: r.width * 0.08),
                       with: .color(rowIndex % 2 == 0 ? s.leaf : Color(hex: "#6E8B5E")))
            }
        }
        c.fill(circle(r, cx: 0.5, cy: 0.3, r: 0.08), with: .color(Theme.aubergineViolet.opacity(0.7)))
    }

    static func asparagus(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        for (index, x) in [0.36, 0.5, 0.64].enumerated() {
            let topY = 0.12 + CGFloat(index % 2) * 0.08
            var spear = Path()
            spear.move(to: point(r, x - 0.05, 0.95))
            spear.addLine(to: point(r, x - 0.025, topY + 0.08))
            spear.addQuadCurve(to: point(r, x + 0.025, topY + 0.08), control: point(r, x, topY - 0.04))
            spear.addLine(to: point(r, x + 0.05, 0.95))
            spear.closeSubpath()
            c.fill(spear, with: .color(index == 1 ? s.leaf : Color(hex: "#7FA86A")))
            c.fill(leaf(r, from: point(r, x, topY + 0.16), to: point(r, x - 0.06, topY + 0.08), width: r.width * 0.025),
                   with: .color(Theme.aubergineViolet.opacity(0.5)))
            c.fill(leaf(r, from: point(r, x, topY + 0.26), to: point(r, x + 0.06, topY + 0.18), width: r.width * 0.025),
                   with: .color(Theme.aubergineViolet.opacity(0.5)))
        }
    }

    static func grape(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.14), to: point(r, 0.5, 0.04), &c, color: Theme.wood, width: 0.035)
        c.fill(leaf(r, from: point(r, 0.5, 0.14), to: point(r, 0.78, 0.06), width: r.width * 0.12), with: .color(s.leaf))
        let rows: [[CGFloat]] = [[0.38, 0.52, 0.66], [0.45, 0.59], [0.52]]
        for (rowIndex, xs) in rows.enumerated() {
            for x in xs {
                c.fill(circle(r, cx: x - 0.02, cy: 0.32 + CGFloat(rowIndex) * 0.17, r: 0.09),
                       with: .color(s.fruit.opacity(rowIndex == 0 ? 1 : 0.92)))
            }
        }
    }

    static func fig(_ r: CGRect, _ s: PlantIconStyle, _ c: inout GraphicsContext) {
        // Feuille lobée caractéristique + figue.
        let base = point(r, 0.42, 0.9)
        for angle in [-0.9, -0.45, 0.0, 0.45, 0.9] {
            let tip = CGPoint(x: base.x + CGFloat(sin(angle)) * r.width * 0.34,
                              y: base.y - r.height * (0.72 - abs(CGFloat(angle)) * 0.14))
            c.fill(leaf(r, from: base, to: tip, width: r.width * 0.1), with: .color(s.leaf))
        }
        var figShape = Path()
        figShape.move(to: point(r, 0.78, 0.42))
        figShape.addQuadCurve(to: point(r, 0.9, 0.72), control: point(r, 0.95, 0.5))
        figShape.addQuadCurve(to: point(r, 0.66, 0.72), control: point(r, 0.78, 0.92))
        figShape.addQuadCurve(to: point(r, 0.78, 0.42), control: point(r, 0.61, 0.5))
        c.fill(figShape, with: .color(Theme.aubergineViolet))
        stem(r, from: point(r, 0.78, 0.44), to: point(r, 0.78, 0.34), &c, width: 0.025)
    }
}

#Preview("Icônes du catalogue") {
    let samples: [(String, PlantCategory)] = [
        ("Tomate", .potager), ("Chou pommé", .potager), ("Poireau", .potager),
        ("Oignon", .potager), ("Betterave", .potager), ("Pomme de terre", .potager),
        ("Maïs doux", .potager), ("Potiron", .potager), ("Melon", .potager),
        ("Artichaut", .potager), ("Asperge", .potager), ("Fenouil bulbeux", .potager),
        ("Rhubarbe", .potager), ("Basilic", .aromatique), ("Cerisier", .fruitier),
        ("Poirier", .fruitier), ("Citronnier", .fruitier), ("Figuier", .fruitier),
        ("Vigne", .fruitier), ("Cassissier", .fruitier), ("Tournesol", .fleur),
        ("Bourrache", .fleur),
    ]
    return ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
            ForEach(samples, id: \.0) { sample in
                VStack {
                    PlantIconView(name: sample.0, category: sample.1, size: 48)
                    Text(sample.0).font(.caption2).lineLimit(1)
                }
            }
        }
        .padding()
    }
}
