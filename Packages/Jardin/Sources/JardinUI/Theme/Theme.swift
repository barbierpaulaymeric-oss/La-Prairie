import JardinCore
import SwiftUI

/// Jardin Intelligent — Theme v2 (design system claude.ai/design).
/// Même esprit naturel, hex recalés pour un contraste AA en plein soleil.
/// Source de vérité : `tokens/colors.css` du projet Design.
///
/// Deux familles :
/// - **Rôles** (accent, fonds, textes, sémantiques…) : adaptatifs clair/sombre,
///   seuls autorisés pour l'interface ;
/// - **Palette botanique héritée** (leaf, wood, tomatoRed…) : aplats décoratifs
///   des icônes de plantes uniquement, jamais porteurs d'information seuls.
public enum Theme {
    // MARK: Palette botanique héritée (décorative — icônes et illustrations)

    public static let leaf = Color(hex: "#2E8B57")
    public static let olive = Color(hex: "#556B2F")
    public static let lightGreen = Color(hex: "#90EE90")
    public static let beige = Color(hex: "#F5F5DC")
    public static let wood = Color(hex: "#DEB887")
    public static let tomatoRed = Color(hex: "#C25B4E")
    public static let carrotOrange = Color(hex: "#DE9152")
    public static let aubergineViolet = Color(hex: "#6E5A8E")
    public static let berryRose = Color(hex: "#C96A7B")
    public static let flowerLilac = Color(hex: "#9C8ABF")

    // MARK: Rôles interactifs

    public static var accent: Color { Color(light: Color(hex: "#23744A"), dark: Color(hex: "#6BC58C")) }
    public static var accentPressed: Color { Color(light: Color(hex: "#1B5C3A"), dark: Color(hex: "#86D3A0")) }
    public static var accentContainer: Color { Color(light: Color(hex: "#DBEBDE"), dark: Color(hex: "#1F4630")) }
    public static var onAccentContainer: Color { Color(light: Color(hex: "#154731"), dark: Color(hex: "#A8E4AC")) }
    public static var secondaryTint: Color { Color(light: Color(hex: "#45571F"), dark: Color(hex: "#B9C77E")) }

    // MARK: Fonds et surfaces

    public static var background: Color { Color(light: Color(hex: "#FAF8EF"), dark: Color(hex: "#171B14")) }
    public static var cardBackground: Color { Color(light: .white, dark: Color(hex: "#222819")) }
    public static var subtleBackground: Color { Color(light: Color(hex: "#F1EDDE"), dark: Color(hex: "#2A3120")) }
    public static var mapBackground: Color { Color(light: Color(hex: "#F0EBD7"), dark: Color(hex: "#1C2117")) }

    public static var border: Color {
        Color(light: Color(hex: "#556B2F").opacity(0.22), dark: Color(hex: "#A9B673").opacity(0.26))
    }
    public static var separator: Color {
        Color(light: Color(hex: "#556B2F").opacity(0.14), dark: Color(hex: "#A9B673").opacity(0.14))
    }

    // MARK: Textes

    public static var textPrimary: Color { Color(light: Color(hex: "#1E2419"), dark: Color(hex: "#ECEFE3")) }
    public static var textSecondary: Color { Color(light: Color(hex: "#4E5945"), dark: Color(hex: "#B4BDA5")) }
    public static var textTertiary: Color { Color(light: Color(hex: "#6E7A63"), dark: Color(hex: "#8C967D")) }

    // MARK: Sémantiques (info / attention / alerte)

    public static var success: Color { Color(light: Color(hex: "#23744A"), dark: Color(hex: "#6BC58C")) }
    public static var warning: Color { Color(light: Color(hex: "#9A5B12"), dark: Color(hex: "#E5A659")) }
    public static var danger: Color { Color(light: Color(hex: "#AE3B2C"), dark: Color(hex: "#E88070")) }
    public static var infoTint: Color { secondaryTint }
    public static var successBg: Color { Color(light: Color(hex: "#DBEBDE"), dark: Color(hex: "#1F4630")) }
    public static var warningBg: Color { Color(light: Color(hex: "#F6E3C6"), dark: Color(hex: "#46351A")) }
    public static var dangerBg: Color { Color(light: Color(hex: "#F6DAD4"), dark: Color(hex: "#4C2620")) }
    public static var infoBg: Color { Color(light: Color(hex: "#EAEBD4"), dark: Color(hex: "#333A22")) }

    /// Pastille « mois de récolte » (MonthDots) — terre 500.
    public static var harvestDot: Color { Color(light: Color(hex: "#B78A50"), dark: Color(hex: "#CBA36A")) }

    // MARK: Données (ordre fixe des séries Swift Charts)

    public static var dataSeries: [Color] {
        [Color(light: Color(hex: "#2E8B57"), dark: Color(hex: "#4FA878")),
         Color(light: Color(hex: "#C25B4E"), dark: Color(hex: "#D97D70")),
         Color(light: Color(hex: "#DE9152"), dark: Color(hex: "#E8A76F")),
         Color(light: Color(hex: "#6E5A8E"), dark: Color(hex: "#9784B5")),
         Color(light: Color(hex: "#C96A7B"), dark: Color(hex: "#D98B9B")),
         Color(light: Color(hex: "#9C8ABF"), dark: Color(hex: "#B3A3D3"))]
    }

    // MARK: Secteurs de la carte
    // Remplissage `.opacity(0.22)`, contour plein ; sélection 0,34 + 2,5 pt.

    public static func zoneColor(_ kind: ZoneKind) -> Color {
        switch kind {
        case .potager: return Color(light: Color(hex: "#2E8B57"), dark: Color(hex: "#4FA878"))
        case .aromatiques: return Color(light: Color(hex: "#7A8B3A"), dark: Color(hex: "#9CAD55"))
        case .verger: return Color(light: Color(hex: "#58AE6A"), dark: Color(hex: "#6FC581"))
        case .serre: return Color(light: Color(hex: "#B78A50"), dark: Color(hex: "#CBA36A"))
        case .massif: return Color(light: Color(hex: "#7FA98A"), dark: Color(hex: "#93BD9E"))
        case .autre: return Color(light: Color(hex: "#A29B7F"), dark: Color(hex: "#B0A98D"))
        }
    }

    // MARK: Seuils (inchangés : santé ≥ 0,75 / ≥ 0,5 ; confiance ≥ 0,60 / ≥ 0,35)

    public static func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 2: return danger
        case 1: return warning
        default: return infoTint
        }
    }

    public static func severityBg(_ severity: Int) -> Color {
        switch severity {
        case 2: return dangerBg
        case 1: return warningBg
        default: return infoBg
        }
    }

    public static func healthColor(_ score: Double) -> Color {
        switch score {
        case ..<0: return textTertiary.opacity(0.6)
        case ..<0.5: return danger
        case ..<0.75: return warning
        default: return success
        }
    }

    public static func confidenceColor(_ value: Double) -> Color {
        value >= 0.60 ? success : (value >= 0.35 ? warning : danger)
    }

    // MARK: Typographie de données (chiffres — arrondie, chasse fixe)

    public static var dataXL: Font { .system(.title, design: .rounded).weight(.bold).monospacedDigit() }
    public static var dataFont: Font { .system(.body, design: .rounded).weight(.semibold).monospacedDigit() }
    public static var dataS: Font { .system(.caption, design: .rounded).weight(.semibold).monospacedDigit() }

    // MARK: Métriques

    public enum Metrics {
        public static let cardRadius: CGFloat = 12
        public static let controlRadius: CGFloat = 10
        public static let sheetRadius: CGFloat = 16
        public static let mapRadius: CGFloat = 14
        public static let cardPadding: CGFloat = 12
        public static let screenMargin: CGFloat = 16
        public static let sectionSpacing: CGFloat = 24
        public static let hitMin: CGFloat = 44
        public static let hitGarden: CGFloat = 50
        public static let cellIcon: CGFloat = 40
        public static let markerMin: CGFloat = 18
    }
}

public extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r, g, b: Double
        if cleaned.count == 6 {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
        } else {
            r = 0.5; g = 0.5; b = 0.5
        }
        self.init(red: r, green: g, blue: b)
    }

    /// Couleur adaptative clair/sombre sans catalogue d'assets.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #endif
    }
}
