import Foundation

/// Analyse colorimétrique du feuillage : part de pixels verts / jaunes / bruns
/// parmi la végétation visible. Logique pure sur tampon RGBA — testable sans Vision.
public enum HealthMath {
    public struct Report: Sendable, Equatable {
        /// 0 (très atteint) … 1 (sain) ; -1 si pas assez de végétation visible.
        public let score: Double
        public let greenRatio: Double
        public let yellowRatio: Double
        public let brownRatio: Double
        /// Part de l'image (ou du masque) occupée par de la végétation.
        public let vegetationRatio: Double
        public let issues: [DetectedIssue]
    }

    public struct DetectedIssue: Sendable, Equatable, Hashable {
        public let label: String
        public let probableCauses: String

        public init(label: String, probableCauses: String) {
            self.label = label
            self.probableCauses = probableCauses
        }
    }

    /// `mask` : booléen par pixel (true = premier plan) à la même résolution que le tampon,
    /// ou `nil` pour analyser toute l'image.
    public static func analyze(pixels: [UInt8], width: Int, height: Int, mask: [Bool]? = nil) -> Report {
        var green = 0, yellow = 0, brown = 0, considered = 0

        let count = width * height
        for index in 0..<count {
            if let mask, index < mask.count, !mask[index] { continue }
            considered += 1

            let offset = index * 4
            let r = Double(pixels[offset]) / 255
            let g = Double(pixels[offset + 1]) / 255
            let b = Double(pixels[offset + 2]) / 255
            let (hue, saturation, value) = rgbToHSV(r: r, g: g, b: b)

            guard saturation > 0.15, value > 0.12 else { continue }
            switch hue {
            case 70..<170 where g >= b:
                green += 1
            case 38..<70 where saturation > 0.25:
                yellow += 1
            case 10..<38 where value < 0.72:
                brown += 1
            default:
                break
            }
        }

        let vegetation = green + yellow + brown
        let vegetationRatio = considered > 0 ? Double(vegetation) / Double(considered) : 0

        guard vegetation > 0, vegetationRatio >= 0.05 else {
            return Report(score: -1, greenRatio: 0, yellowRatio: 0, brownRatio: 0,
                          vegetationRatio: vegetationRatio,
                          issues: [DetectedIssue(label: "Végétation peu visible",
                                                 probableCauses: "Cadrez la plante de plus près pour une analyse fiable.")])
        }

        let greenRatio = Double(green) / Double(vegetation)
        let yellowRatio = Double(yellow) / Double(vegetation)
        let brownRatio = Double(brown) / Double(vegetation)

        var issues: [DetectedIssue] = []
        if yellowRatio >= 0.2 {
            issues.append(DetectedIssue(
                label: "Jaunissement du feuillage",
                probableCauses: "Manque d'eau, carence (azote, magnésium) ou excès d'arrosage."
            ))
        }
        if brownRatio >= 0.12 {
            issues.append(DetectedIssue(
                label: "Taches brunes / nécroses",
                probableCauses: "Maladie foliaire (mildiou, alternariose), brûlure ou carence en potassium."
            ))
        }

        return Report(score: greenRatio,
                      greenRatio: greenRatio,
                      yellowRatio: yellowRatio,
                      brownRatio: brownRatio,
                      vegetationRatio: vegetationRatio,
                      issues: issues)
    }

    /// Conversion RGB (0…1) → (teinte 0…360, saturation 0…1, valeur 0…1).
    public static func rgbToHSV(r: Double, g: Double, b: Double) -> (hue: Double, saturation: Double, value: Double) {
        let maxComponent = max(r, g, b)
        let minComponent = min(r, g, b)
        let delta = maxComponent - minComponent

        var hue: Double = 0
        if delta > 0 {
            if maxComponent == r {
                hue = 60 * ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxComponent == g {
                hue = 60 * ((b - r) / delta + 2)
            } else {
                hue = 60 * ((r - g) / delta + 4)
            }
            if hue < 0 { hue += 360 }
        }
        let saturation = maxComponent > 0 ? delta / maxComponent : 0
        return (hue, saturation, maxComponent)
    }
}
