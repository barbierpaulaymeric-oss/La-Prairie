import JardinCore
import SwiftUI

/// Icônes de plantes dessinées paramétriquement (Canvas) : style minimaliste,
/// palette naturelle, silhouette reconnaissable par famille. Toute nouvelle plante
/// obtient une icône « à la volée », sans asset à générer. Les SVG statiques de
/// `App/Resources/PlantIcons` (script `Scripts/generate_plant_icons.py`) partagent
/// le même langage visuel pour le marketing/App Store.
public enum PlantIconKind: String, CaseIterable, Sendable {
    case tomate, courgette, carotte, laitue, radis, epinard
    case basilic, menthe, romarin, thym, persil, ciboulette, sauge, origan, lavande
    case fraise, framboise, arbre, haricot, concombre, poivron, aubergine, fleur
    case pousse

    public static func detect(name: String?, category: PlantCategory) -> PlantIconKind {
        let n = (name ?? "").folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        func has(_ needles: String...) -> Bool { needles.contains { n.contains($0) } }

        if has("tomate") { return .tomate }
        if has("courgette", "courge", "citrouille", "potiron") { return .courgette }
        if has("carotte", "panais", "navet") { return .carotte }
        if has("laitue", "salade", "batavia", "mache", "roquette") { return .laitue }
        if has("radis") { return .radis }
        if has("epinard", "blette", "chou") { return .epinard }
        if has("basilic") { return .basilic }
        if has("menthe", "melisse") { return .menthe }
        if has("romarin") { return .romarin }
        if has("thym", "sarriette") { return .thym }
        if has("persil", "coriandre", "cerfeuil", "aneth") { return .persil }
        if has("ciboulette", "poireau", "oignon", "ail ", "echalote") { return .ciboulette }
        if has("sauge") { return .sauge }
        if has("origan", "marjolaine") { return .origan }
        if has("lavande") { return .lavande }
        if has("fraise") { return .fraise }
        if has("framboise", "mure", "cassis", "groseille", "myrtille") { return .framboise }
        if has("pommier", "poirier", "cerisier", "prunier", "abricotier", "pecher", "figuier", "noyer", "olivier") { return .arbre }
        if has("haricot", "pois", "feve") { return .haricot }
        if has("concombre", "cornichon") { return .concombre }
        if has("poivron", "piment") { return .poivron }
        if has("aubergine") { return .aubergine }
        if has("oeillet", "fleur", "rose", "tulipe", "capucine", "souci", "tournesol") { return .fleur }

        switch category {
        case .fruitier: return .arbre
        case .fleur: return .fleur
        case .aromatique: return .basilic
        case .potager: return .pousse
        case .autre: return .pousse
        }
    }
}

public struct PlantIconView: View {
    let kind: PlantIconKind
    let size: CGFloat

    public init(kind: PlantIconKind, size: CGFloat = 44) {
        self.kind = kind
        self.size = size
    }

    public init(plant: PlantMO, size: CGFloat = 44) {
        self.init(kind: PlantIconKind.detect(name: plant.species?.commonName ?? plant.name,
                                             category: plant.category),
                  size: size)
    }

    public init(species: PlantSpeciesMO, size: CGFloat = 44) {
        self.init(kind: PlantIconKind.detect(name: species.commonName, category: species.category),
                  size: size)
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize).insetBy(dx: canvasSize.width * 0.08,
                                                                       dy: canvasSize.height * 0.08)
            IconPainter.draw(kind, in: rect, context: &context)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Primitives de dessin partagées par toutes les icônes.
enum IconPainter {
    static func draw(_ kind: PlantIconKind, in rect: CGRect, context: inout GraphicsContext) {
        switch kind {
        case .tomate: tomato(rect, &context)
        case .courgette: zucchini(rect, &context)
        case .carotte: carrot(rect, &context)
        case .laitue: lettuce(rect, &context)
        case .radis: radish(rect, &context)
        case .epinard: leafyGreens(rect, &context)
        case .basilic: basil(rect, &context)
        case .menthe: mint(rect, &context)
        case .romarin: sprig(rect, &context, needleColor: Theme.olive)
        case .thym: sprig(rect, &context, needleColor: Theme.leaf)
        case .persil: parsley(rect, &context)
        case .ciboulette: chives(rect, &context)
        case .sauge: basil(rect, &context)
        case .origan: mint(rect, &context)
        case .lavande: lavender(rect, &context)
        case .fraise: strawberry(rect, &context)
        case .framboise: raspberry(rect, &context)
        case .arbre: tree(rect, &context)
        case .haricot: beans(rect, &context)
        case .concombre: cucumber(rect, &context)
        case .poivron: pepper(rect, &context)
        case .aubergine: eggplant(rect, &context)
        case .fleur: flower(rect, &context)
        case .pousse: sprout(rect, &context)
        }
    }

    static func point(_ rect: CGRect, _ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
    }

    /// Feuille : deux courbes quadratiques entre base et pointe.
    static func leaf(_ rect: CGRect, from base: CGPoint, to tip: CGPoint, width: CGFloat) -> Path {
        var path = Path()
        let dx = tip.x - base.x, dy = tip.y - base.y
        let mid = CGPoint(x: (base.x + tip.x) / 2, y: (base.y + tip.y) / 2)
        let normal = CGPoint(x: -dy, y: dx)
        let length = max(sqrt(normal.x * normal.x + normal.y * normal.y), 0.001)
        let offset = CGPoint(x: normal.x / length * width, y: normal.y / length * width)
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
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: rect.width * width,
                                                                     lineCap: .round))
    }

    // MARK: Icônes

    static func sprout(_ r: CGRect, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.45), &c)
        c.fill(leaf(r, from: point(r, 0.5, 0.55), to: point(r, 0.18, 0.25), width: r.width * 0.16), with: .color(Theme.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.5), to: point(r, 0.85, 0.15), width: r.width * 0.18), with: .color(Theme.lightGreen))
    }

    static func basil(_ r: CGRect, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.35), &c)
        c.fill(leaf(r, from: point(r, 0.5, 0.75), to: point(r, 0.14, 0.55), width: r.width * 0.17), with: .color(Theme.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.75), to: point(r, 0.86, 0.55), width: r.width * 0.17), with: .color(Theme.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.45), to: point(r, 0.22, 0.18), width: r.width * 0.16), with: .color(Theme.lightGreen))
        c.fill(leaf(r, from: point(r, 0.5, 0.45), to: point(r, 0.78, 0.18), width: r.width * 0.16), with: .color(Theme.lightGreen))
        c.fill(leaf(r, from: point(r, 0.5, 0.4), to: point(r, 0.5, 0.05), width: r.width * 0.14), with: .color(Theme.leaf))
    }

    static func mint(_ r: CGRect, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.2), &c)
        for (index, y) in [0.72, 0.52, 0.32].enumerated() {
            let spread = 0.36 - CGFloat(index) * 0.06
            c.fill(leaf(r, from: point(r, 0.5, y), to: point(r, 0.5 - spread, y - 0.16), width: r.width * 0.13),
                   with: .color(index % 2 == 0 ? Theme.leaf : Theme.olive))
            c.fill(leaf(r, from: point(r, 0.5, y), to: point(r, 0.5 + spread, y - 0.16), width: r.width * 0.13),
                   with: .color(index % 2 == 0 ? Theme.olive : Theme.leaf))
        }
        c.fill(leaf(r, from: point(r, 0.5, 0.24), to: point(r, 0.5, 0.02), width: r.width * 0.11), with: .color(Theme.lightGreen))
    }

    static func sprig(_ r: CGRect, _ c: inout GraphicsContext, needleColor: Color) {
        stem(r, from: point(r, 0.35, 0.95), to: point(r, 0.62, 0.08), &c, width: 0.04)
        for step in 0..<7 {
            let t = 0.15 + CGFloat(step) * 0.11
            let baseX = 0.35 + (0.62 - 0.35) * (1 - t)
            let base = point(r, baseX, 0.95 - t * 0.87 + 0.05)
            c.fill(leaf(r, from: base, to: CGPoint(x: base.x - r.width * 0.2, y: base.y - r.height * 0.1),
                        width: r.width * 0.045), with: .color(needleColor))
            c.fill(leaf(r, from: base, to: CGPoint(x: base.x + r.width * 0.16, y: base.y - r.height * 0.14),
                        width: r.width * 0.045), with: .color(needleColor.opacity(0.8)))
        }
    }

    static func lavender(_ r: CGRect, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.45), &c, color: Theme.leaf)
        c.fill(leaf(r, from: point(r, 0.5, 0.85), to: point(r, 0.28, 0.62), width: r.width * 0.06), with: .color(Theme.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.8), to: point(r, 0.72, 0.58), width: r.width * 0.06), with: .color(Theme.leaf))
        for row in 0..<4 {
            let y = 0.42 - Double(row) * 0.1
            let width = 0.16 - Double(row) * 0.03
            var capsule = Path()
            capsule.addEllipse(in: CGRect(x: point(r, 0.5 - width, y).x, y: point(r, 0, y - 0.045).y,
                                          width: r.width * width * 2, height: r.height * 0.095))
            c.fill(capsule, with: .color(row % 2 == 0 ? Theme.flowerLilac : Theme.aubergineViolet.opacity(0.85)))
        }
    }

    static func tomato(_ r: CGRect, _ c: inout GraphicsContext) {
        let body = CGRect(x: point(r, 0.14, 0).x, y: point(r, 0, 0.3).y,
                          width: r.width * 0.72, height: r.height * 0.62)
        c.fill(Path(ellipseIn: body), with: .color(Theme.tomatoRed))
        c.fill(Path(ellipseIn: body.insetBy(dx: body.width * 0.16, dy: body.height * 0.16)
                .offsetBy(dx: -body.width * 0.1, dy: -body.height * 0.1)),
               with: .color(.white.opacity(0.12)))
        for angle in [-0.9, -0.3, 0.3, 0.9] {
            let tip = CGPoint(x: point(r, 0.5, 0.33).x + CGFloat(cos(angle - .pi / 2)) * r.width * 0.2,
                              y: point(r, 0.5, 0.33).y + CGFloat(sin(angle - .pi / 2)) * r.height * 0.16 + r.height * 0.12)
            c.fill(leaf(r, from: point(r, 0.5, 0.34), to: tip, width: r.width * 0.05), with: .color(Theme.olive))
        }
        stem(r, from: point(r, 0.5, 0.3), to: point(r, 0.5, 0.12), &c, width: 0.05)
    }

    static func zucchini(_ r: CGRect, _ c: inout GraphicsContext) {
        var body = Path()
        body.move(to: point(r, 0.16, 0.82))
        body.addQuadCurve(to: point(r, 0.82, 0.3), control: point(r, 0.2, 0.25))
        body.addQuadCurve(to: point(r, 0.3, 0.92), control: point(r, 0.95, 0.85))
        body.closeSubpath()
        c.fill(body, with: .color(Theme.leaf))
        stem(r, from: point(r, 0.82, 0.3), to: point(r, 0.92, 0.16), &c, width: 0.05)
        var stripe = Path()
        stripe.move(to: point(r, 0.26, 0.78))
        stripe.addQuadCurve(to: point(r, 0.74, 0.4), control: point(r, 0.35, 0.42))
        c.stroke(stripe, with: .color(Theme.lightGreen.opacity(0.7)), lineWidth: r.width * 0.035)
    }

    static func cucumber(_ r: CGRect, _ c: inout GraphicsContext) {
        var body = Path()
        body.addRoundedRect(in: CGRect(x: point(r, 0.2, 0).x, y: point(r, 0, 0.18).y,
                                       width: r.width * 0.26, height: r.height * 0.72),
                            cornerSize: CGSize(width: r.width * 0.13, height: r.width * 0.13))
        c.fill(body, with: .color(Theme.leaf))
        c.fill(leaf(r, from: point(r, 0.42, 0.3), to: point(r, 0.82, 0.12), width: r.width * 0.16), with: .color(Theme.lightGreen))
        var tendril = Path()
        tendril.move(to: point(r, 0.46, 0.5))
        tendril.addQuadCurve(to: point(r, 0.8, 0.55), control: point(r, 0.72, 0.38))
        c.stroke(tendril, with: .color(Theme.olive), style: StrokeStyle(lineWidth: r.width * 0.03, lineCap: .round))
    }

    static func carrot(_ r: CGRect, _ c: inout GraphicsContext) {
        var root = Path()
        root.move(to: point(r, 0.34, 0.35))
        root.addQuadCurve(to: point(r, 0.5, 0.95), control: point(r, 0.36, 0.75))
        root.addQuadCurve(to: point(r, 0.66, 0.35), control: point(r, 0.64, 0.75))
        root.closeSubpath()
        c.fill(root, with: .color(Theme.carrotOrange))
        c.fill(leaf(r, from: point(r, 0.5, 0.36), to: point(r, 0.26, 0.06), width: r.width * 0.1), with: .color(Theme.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.36), to: point(r, 0.5, 0.02), width: r.width * 0.09), with: .color(Theme.lightGreen))
        c.fill(leaf(r, from: point(r, 0.5, 0.36), to: point(r, 0.74, 0.06), width: r.width * 0.1), with: .color(Theme.leaf))
    }

    static func radish(_ r: CGRect, _ c: inout GraphicsContext) {
        c.fill(Path(ellipseIn: CGRect(x: point(r, 0.28, 0).x, y: point(r, 0, 0.42).y,
                                      width: r.width * 0.44, height: r.height * 0.42)),
               with: .color(Theme.berryRose))
        stem(r, from: point(r, 0.5, 0.84), to: point(r, 0.5, 0.95), &c, color: Theme.berryRose, width: 0.03)
        c.fill(leaf(r, from: point(r, 0.5, 0.45), to: point(r, 0.32, 0.08), width: r.width * 0.11), with: .color(Theme.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.45), to: point(r, 0.68, 0.08), width: r.width * 0.11), with: .color(Theme.lightGreen))
    }

    static func lettuce(_ r: CGRect, _ c: inout GraphicsContext) {
        let base = point(r, 0.5, 0.9)
        for (index, angle) in [-1.2, -0.6, 0, 0.6, 1.2].enumerated() {
            let tip = CGPoint(x: base.x + CGFloat(sin(angle)) * r.width * 0.4,
                              y: base.y - r.height * (0.75 - abs(CGFloat(angle)) * 0.12))
            c.fill(leaf(r, from: base, to: tip, width: r.width * 0.16),
                   with: .color(index % 2 == 0 ? Theme.lightGreen : Theme.leaf))
        }
        c.fill(leaf(r, from: base, to: point(r, 0.5, 0.3), width: r.width * 0.14), with: .color(Theme.beige))
    }

    static func leafyGreens(_ r: CGRect, _ c: inout GraphicsContext) {
        let base = point(r, 0.5, 0.92)
        for (index, angle) in [-0.8, 0, 0.8].enumerated() {
            let tip = CGPoint(x: base.x + CGFloat(sin(angle)) * r.width * 0.32,
                              y: base.y - r.height * 0.8)
            c.fill(leaf(r, from: base, to: tip, width: r.width * 0.18),
                   with: .color(index == 1 ? Theme.leaf : Theme.olive))
        }
    }

    static func parsley(_ r: CGRect, _ c: inout GraphicsContext) {
        for angle in [-0.5, 0.0, 0.5] {
            let base = point(r, 0.5, 0.95)
            let top = CGPoint(x: base.x + CGFloat(sin(angle)) * r.width * 0.3,
                              y: base.y - r.height * 0.6)
            stem(r, from: base, to: top, &c, color: Theme.leaf, width: 0.03)
            for cluster in [(-0.12, -0.1), (0.12, -0.1), (0.0, -0.18)] {
                c.fill(Path(ellipseIn: CGRect(x: top.x + r.width * cluster.0 - r.width * 0.09,
                                              y: top.y + r.height * cluster.1 - r.height * 0.09,
                                              width: r.width * 0.18, height: r.height * 0.18)),
                       with: .color(Theme.leaf.opacity(0.9)))
            }
        }
    }

    static func chives(_ r: CGRect, _ c: inout GraphicsContext) {
        for (index, x) in [0.3, 0.42, 0.54, 0.66].enumerated() {
            let bend = CGFloat(index % 2 == 0 ? -0.06 : 0.06)
            var blade = Path()
            blade.move(to: point(r, x, 0.95))
            blade.addQuadCurve(to: point(r, x + bend, 0.1 + CGFloat(index) * 0.04),
                               control: point(r, x + bend * 2, 0.5))
            c.stroke(blade, with: .color(index % 2 == 0 ? Theme.leaf : Theme.olive),
                     style: StrokeStyle(lineWidth: r.width * 0.05, lineCap: .round))
        }
        c.fill(Path(ellipseIn: CGRect(x: point(r, 0.24, 0).x, y: point(r, 0, 0.04).y,
                                      width: r.width * 0.12, height: r.height * 0.12)),
               with: .color(Theme.flowerLilac))
    }

    static func strawberry(_ r: CGRect, _ c: inout GraphicsContext) {
        var berry = Path()
        berry.move(to: point(r, 0.2, 0.4))
        berry.addQuadCurve(to: point(r, 0.5, 0.95), control: point(r, 0.22, 0.85))
        berry.addQuadCurve(to: point(r, 0.8, 0.4), control: point(r, 0.78, 0.85))
        berry.addQuadCurve(to: point(r, 0.2, 0.4), control: point(r, 0.5, 0.28))
        c.fill(berry, with: .color(Theme.tomatoRed))
        for seed in [(0.38, 0.55), (0.55, 0.62), (0.45, 0.75), (0.62, 0.5)] {
            c.fill(Path(ellipseIn: CGRect(x: point(r, seed.0, 0).x, y: point(r, 0, seed.1).y,
                                          width: r.width * 0.04, height: r.height * 0.055)),
                   with: .color(Theme.beige))
        }
        c.fill(leaf(r, from: point(r, 0.5, 0.38), to: point(r, 0.3, 0.22), width: r.width * 0.08), with: .color(Theme.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.38), to: point(r, 0.7, 0.22), width: r.width * 0.08), with: .color(Theme.leaf))
        stem(r, from: point(r, 0.5, 0.36), to: point(r, 0.5, 0.14), &c, width: 0.04)
    }

    static func raspberry(_ r: CGRect, _ c: inout GraphicsContext) {
        let centers = [(0.4, 0.5), (0.6, 0.5), (0.34, 0.66), (0.5, 0.62), (0.66, 0.66), (0.42, 0.8), (0.58, 0.8), (0.5, 0.92)]
        for center in centers {
            c.fill(Path(ellipseIn: CGRect(x: point(r, center.0, 0).x - r.width * 0.09,
                                          y: point(r, 0, center.1).y - r.height * 0.09,
                                          width: r.width * 0.18, height: r.height * 0.18)),
                   with: .color(Theme.berryRose))
        }
        c.fill(leaf(r, from: point(r, 0.5, 0.42), to: point(r, 0.28, 0.16), width: r.width * 0.09), with: .color(Theme.leaf))
        c.fill(leaf(r, from: point(r, 0.5, 0.42), to: point(r, 0.72, 0.16), width: r.width * 0.09), with: .color(Theme.leaf))
    }

    static func tree(_ r: CGRect, _ c: inout GraphicsContext) {
        var trunk = Path()
        trunk.move(to: point(r, 0.44, 0.95))
        trunk.addLine(to: point(r, 0.47, 0.5))
        trunk.addLine(to: point(r, 0.53, 0.5))
        trunk.addLine(to: point(r, 0.56, 0.95))
        trunk.closeSubpath()
        c.fill(trunk, with: .color(Theme.wood))
        c.fill(Path(ellipseIn: CGRect(x: point(r, 0.15, 0).x, y: point(r, 0, 0.08).y,
                                      width: r.width * 0.7, height: r.height * 0.52)),
               with: .color(Theme.leaf))
        c.fill(Path(ellipseIn: CGRect(x: point(r, 0.28, 0).x, y: point(r, 0, 0.02).y,
                                      width: r.width * 0.36, height: r.height * 0.28)),
               with: .color(Theme.lightGreen.opacity(0.7)))
        c.fill(Path(ellipseIn: CGRect(x: point(r, 0.6, 0).x, y: point(r, 0, 0.3).y,
                                      width: r.width * 0.09, height: r.height * 0.09)),
               with: .color(Theme.tomatoRed))
    }

    static func beans(_ r: CGRect, _ c: inout GraphicsContext) {
        for (index, offset) in [-0.14, 0.0, 0.14].enumerated() {
            var pod = Path()
            pod.move(to: point(r, 0.3 + offset, 0.2))
            pod.addQuadCurve(to: point(r, 0.55 + offset, 0.9), control: point(r, 0.28 + offset, 0.65))
            pod.addQuadCurve(to: point(r, 0.36 + offset, 0.22), control: point(r, 0.5 + offset, 0.6))
            pod.closeSubpath()
            c.fill(pod, with: .color(index == 1 ? Theme.leaf : Theme.olive))
        }
        stem(r, from: point(r, 0.32, 0.18), to: point(r, 0.62, 0.12), &c, width: 0.035)
    }

    static func pepper(_ r: CGRect, _ c: inout GraphicsContext) {
        var body = Path()
        body.addRoundedRect(in: CGRect(x: point(r, 0.28, 0).x, y: point(r, 0, 0.28).y,
                                       width: r.width * 0.44, height: r.height * 0.62),
                            cornerSize: CGSize(width: r.width * 0.18, height: r.height * 0.2))
        c.fill(body, with: .color(Theme.tomatoRed))
        c.fill(leaf(r, from: point(r, 0.5, 0.3), to: point(r, 0.66, 0.14), width: r.width * 0.07), with: .color(Theme.leaf))
        stem(r, from: point(r, 0.5, 0.28), to: point(r, 0.48, 0.1), &c, width: 0.05)
        var groove = Path()
        groove.move(to: point(r, 0.44, 0.34))
        groove.addQuadCurve(to: point(r, 0.44, 0.84), control: point(r, 0.4, 0.6))
        c.stroke(groove, with: .color(.white.opacity(0.15)), lineWidth: r.width * 0.03)
    }

    static func eggplant(_ r: CGRect, _ c: inout GraphicsContext) {
        var body = Path()
        body.move(to: point(r, 0.58, 0.22))
        body.addQuadCurve(to: point(r, 0.72, 0.75), control: point(r, 0.85, 0.4))
        body.addQuadCurve(to: point(r, 0.35, 0.9), control: point(r, 0.6, 1.0))
        body.addQuadCurve(to: point(r, 0.58, 0.22), control: point(r, 0.2, 0.45))
        c.fill(body, with: .color(Theme.aubergineViolet))
        c.fill(leaf(r, from: point(r, 0.58, 0.24), to: point(r, 0.4, 0.12), width: r.width * 0.08), with: .color(Theme.leaf))
        stem(r, from: point(r, 0.6, 0.22), to: point(r, 0.66, 0.08), &c, width: 0.045)
    }

    static func flower(_ r: CGRect, _ c: inout GraphicsContext) {
        stem(r, from: point(r, 0.5, 0.95), to: point(r, 0.5, 0.5), &c, color: Theme.leaf)
        c.fill(leaf(r, from: point(r, 0.5, 0.8), to: point(r, 0.3, 0.66), width: r.width * 0.08), with: .color(Theme.leaf))
        let center = point(r, 0.5, 0.32)
        for petalIndex in 0..<6 {
            let angle = Double(petalIndex) / 6 * 2 * .pi
            let tip = CGPoint(x: center.x + CGFloat(cos(angle)) * r.width * 0.22,
                              y: center.y + CGFloat(sin(angle)) * r.height * 0.22)
            c.fill(leaf(r, from: center, to: tip, width: r.width * 0.09), with: .color(Theme.flowerLilac))
        }
        c.fill(Path(ellipseIn: CGRect(x: center.x - r.width * 0.08, y: center.y - r.height * 0.08,
                                      width: r.width * 0.16, height: r.height * 0.16)),
               with: .color(Theme.carrotOrange))
    }
}

#Preview("Icônes") {
    let columns = [GridItem(.adaptive(minimum: 60))]
    return ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(PlantIconKind.allCases, id: \.rawValue) { kind in
                VStack {
                    PlantIconView(kind: kind, size: 48)
                    Text(kind.rawValue).font(.caption2)
                }
            }
        }
        .padding()
    }
}
