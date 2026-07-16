import SwiftUI

/// Palette naturelle de l'application. Les couleurs s'adaptent au mode sombre
/// en variant la luminosité, pas la teinte.
public enum Theme {
    public static let leaf = Color(hex: "#2E8B57")
    public static let olive = Color(hex: "#556B2F")
    public static let lightGreen = Color(hex: "#90EE90")
    public static let beige = Color(hex: "#F5F5DC")
    public static let wood = Color(hex: "#DEB887")

    // Accents doux pour les fruits/légumes des icônes.
    public static let tomatoRed = Color(hex: "#C25B4E")
    public static let carrotOrange = Color(hex: "#DE9152")
    public static let aubergineViolet = Color(hex: "#6E5A8E")
    public static let berryRose = Color(hex: "#C96A7B")
    public static let flowerLilac = Color(hex: "#9C8ABF")

    public static var background: Color {
        Color(light: Color(hex: "#FAF8EF"), dark: Color(hex: "#1C1F1A"))
    }

    public static var cardBackground: Color {
        Color(light: .white, dark: Color(hex: "#262B23"))
    }

    public static var mapBackground: Color {
        Color(light: Color(hex: "#F1EEDC"), dark: Color(hex: "#20241D"))
    }

    public static func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 2: return tomatoRed
        case 1: return carrotOrange
        default: return leaf
        }
    }

    public static func healthColor(_ score: Double) -> Color {
        switch score {
        case ..<0: return .secondary.opacity(0.4)
        case ..<0.5: return tomatoRed
        case ..<0.75: return carrotOrange
        default: return leaf
        }
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
