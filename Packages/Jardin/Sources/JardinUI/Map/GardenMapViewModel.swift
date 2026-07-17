import CoreGraphics
import JardinCore
import SwiftUI

@MainActor
public final class GardenMapViewModel: ObservableObject {
    public enum Mode: String, CaseIterable, Identifiable {
        case explorer
        case deplacer
        case secteurs
        case dessinerZone

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .explorer: return "Explorer"
            case .deplacer: return "Déplacer"
            case .secteurs: return "Secteurs"
            case .dessinerZone: return "Tracer"
            }
        }

        public var systemImage: String {
            switch self {
            case .explorer: return "hand.point.up.left"
            case .deplacer: return "arrow.up.and.down.and.arrow.left.and.right"
            case .secteurs: return "square.dashed"
            case .dessinerZone: return "pencil.and.outline"
            }
        }
    }

    @Published public var mode: Mode = .explorer {
        didSet { if mode != .secteurs { selectedZoneID = nil } }
    }
    @Published public var scale: CGFloat = 1
    @Published public var offset: CGSize = .zero
    @Published public var draftZonePoints: [CGPoint] = []
    @Published public var showZoneEditor = false
    @Published public var showAddPlant = false
    @Published public var showDimensionsSheet = false
    @Published public var showZoneInfo = false
    @Published public var selectedPlantID: UUID?
    @Published public var draggingPlantID: UUID?

    // Édition de secteur
    @Published public var selectedZoneID: UUID?
    @Published public var draggingVertexIndex: Int?
    /// Points au début d'un déplacement de zone entière (translation relative).
    public var zoneDragStartPoints: [CGPoint]?

    private var gestureScaleBase: CGFloat = 1
    private var panBase: CGSize = .zero

    public init() {}

    // MARK: Zoom / pan

    public func applyMagnification(_ value: CGFloat) {
        scale = min(max(gestureScaleBase * value, 0.5), 6)
    }

    public func endMagnification() {
        gestureScaleBase = scale
    }

    public func applyPan(_ translation: CGSize) {
        offset = CGSize(width: panBase.width + translation.width,
                        height: panBase.height + translation.height)
    }

    public func endPan() {
        panBase = offset
    }

    public func resetViewport() {
        withAnimation(.spring(duration: 0.35)) {
            scale = 1
            offset = .zero
        }
        gestureScaleBase = 1
        panBase = .zero
    }

    public func zoom(by factor: CGFloat) {
        withAnimation(.spring(duration: 0.25)) {
            scale = min(max(scale * factor, 0.5), 6)
        }
        gestureScaleBase = scale
    }

    // MARK: Dessin de zone

    public func handleZoneTap(at normalizedPoint: CGPoint) {
        guard mode == .dessinerZone else { return }
        draftZonePoints.append(normalizedPoint.clampedToUnit)
    }

    public func undoZonePoint() {
        _ = draftZonePoints.popLast()
    }

    public func finishZoneDrawing() {
        guard draftZonePoints.count >= 3 else { return }
        showZoneEditor = true
    }

    public func cancelZoneDrawing() {
        draftZonePoints = []
        mode = .explorer
    }

    /// Rectangle prédéfini au centre, ajustable ensuite en mode Secteurs.
    public func insertPresetRectangle() {
        draftZonePoints = [CGPoint(x: 0.35, y: 0.35), CGPoint(x: 0.65, y: 0.35),
                           CGPoint(x: 0.65, y: 0.6), CGPoint(x: 0.35, y: 0.6)]
        mode = .dessinerZone
    }
}

extension CGPoint {
    var clampedToUnit: CGPoint {
        CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
    }
}
