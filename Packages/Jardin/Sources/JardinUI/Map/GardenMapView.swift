import CoreData
import JardinCore
import SwiftUI

/// Plan du jardin : zones dessinées, plantes déplaçables, zoom/panoramique.
/// Coordonnées stockées normalisées (0…1) → la carte est indépendante de la taille d'écran.
public struct GardenMapView: View {
    @EnvironmentObject private var appEnv: AppEnvironment
    @EnvironmentObject private var store: GardenStore
    @StateObject private var viewModel = GardenMapViewModel()

    @FetchRequest(entity: PlantMO.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
                  predicate: NSPredicate(format: "archived == NO"))
    private var plants: FetchedResults<PlantMO>

    @FetchRequest(entity: GardenZoneMO.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var zones: FetchedResults<GardenZoneMO>

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let side = max(min(geo.size.width, geo.size.height) - 16, 100)
            ZStack {
                Theme.mapBackground.ignoresSafeArea()
                mapContent(side: side)
                    .frame(width: side, height: side)
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipped()
            .contentShape(Rectangle())
            .gesture(panGesture, including: viewModel.mode == .deplacer ? .subviews : .all)
            .simultaneousGesture(magnificationGesture)
        }
        .overlay(alignment: .bottomTrailing) { zoomControls }
        .overlay(alignment: .bottom) {
            if viewModel.mode == .dessinerZone { zoneDrawingBar }
        }
        .navigationTitle("Carte du jardin")
        .toolbar { toolbarContent }
        .sheet(isPresented: $viewModel.showAddPlant) {
            PlantEditorView(initialPosition: CGPoint(x: 0.5, y: 0.5))
        }
        .sheet(isPresented: $viewModel.showZoneEditor) {
            ZoneEditorView(points: viewModel.draftZonePoints) {
                viewModel.cancelZoneDrawing()
            }
        }
        .sheet(item: Binding(
            get: { viewModel.selectedPlantID.flatMap { store.plant(withID: $0) } },
            set: { viewModel.selectedPlantID = $0?.id }
        )) { plant in
            NavigationStack { PlantDetailView(plant: plant) }
        }
    }

    // MARK: Contenu de la carte

    private func mapContent(side: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.beige.opacity(0.6))
            gridLines

            ForEach(zones) { zone in
                ZoneShape(points: zone.points)
                    .fill(Color(hex: zone.colorHex ?? "#2E8B57").opacity(0.22))
                ZoneShape(points: zone.points)
                    .stroke(Color(hex: zone.colorHex ?? "#2E8B57").opacity(0.75),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                if let first = zone.points.first {
                    Text(zone.name ?? "Zone")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.olive)
                        .position(x: first.x * side, y: max(first.y * side - 12, 8))
                }
            }

            if !viewModel.draftZonePoints.isEmpty {
                ZoneShape(points: viewModel.draftZonePoints)
                    .stroke(Theme.tomatoRed, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                ForEach(Array(viewModel.draftZonePoints.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(Theme.tomatoRed)
                        .frame(width: 8, height: 8)
                        .position(x: point.x * side, y: point.y * side)
                }
            }

            ForEach(plants) { plant in
                plantMarker(plant, side: side)
            }
        }
        .coordinateSpace(name: "gardenMap")
        .onTapGesture(coordinateSpace: .named("gardenMap")) { location in
            viewModel.handleZoneTap(at: CGPoint(x: location.x / side, y: location.y / side))
        }
    }

    private var gridLines: some View {
        Canvas { context, size in
            let step = size.width / 10
            var path = Path()
            for index in 1..<10 {
                let position = CGFloat(index) * step
                path.move(to: CGPoint(x: position, y: 0))
                path.addLine(to: CGPoint(x: position, y: size.height))
                path.move(to: CGPoint(x: 0, y: position))
                path.addLine(to: CGPoint(x: size.width, y: position))
            }
            context.stroke(path, with: .color(Theme.olive.opacity(0.08)), lineWidth: 1)
        }
    }

    private func plantMarker(_ plant: PlantMO, side: CGFloat) -> some View {
        let isDragging = viewModel.draggingPlantID == plant.id
        return VStack(spacing: 2) {
            PlantIconView(plant: plant, size: 40)
                .padding(5)
                .background(Theme.cardBackground.opacity(0.92), in: Circle())
                .overlay(Circle().stroke(isDragging ? Theme.tomatoRed : Theme.leaf.opacity(0.5),
                                         lineWidth: isDragging ? 2.5 : 1.5))
                .shadow(color: .black.opacity(isDragging ? 0.25 : 0.08), radius: isDragging ? 8 : 3, y: 2)
            Text(plant.displayName)
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
                .padding(.horizontal, 4)
                .background(Theme.cardBackground.opacity(0.85), in: Capsule())
        }
        .scaleEffect(isDragging ? 1.15 : 1)
        .position(x: plant.posX * side, y: plant.posY * side)
        .onTapGesture {
            if viewModel.mode == .explorer { viewModel.selectedPlantID = plant.id }
        }
        .gesture(moveGesture(for: plant, side: side))
        .animation(.spring(duration: 0.2), value: isDragging)
        .accessibilityLabel("\(plant.displayName), \(plant.zone?.name ?? "hors zone")")
    }

    private func moveGesture(for plant: PlantMO, side: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("gardenMap"))
            .onChanged { value in
                guard viewModel.mode == .deplacer else { return }
                viewModel.draggingPlantID = plant.id
                plant.posX = min(max(value.location.x / side, 0), 1)
                plant.posY = min(max(value.location.y / side, 0), 1)
            }
            .onEnded { value in
                guard viewModel.mode == .deplacer else { return }
                viewModel.draggingPlantID = nil
                store.movePlant(plant, to: CGPoint(x: value.location.x / side,
                                                   y: value.location.y / side))
            }
    }

    // MARK: Gestes globaux

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard viewModel.mode != .dessinerZone else { return }
                viewModel.applyPan(value.translation)
            }
            .onEnded { _ in viewModel.endPan() }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { viewModel.applyMagnification($0) }
            .onEnded { _ in viewModel.endMagnification() }
    }

    private var zoomControls: some View {
        VStack(spacing: 10) {
            Button { viewModel.zoom(by: 1.3) } label: { Image(systemName: "plus.magnifyingglass") }
            Button { viewModel.zoom(by: 1 / 1.3) } label: { Image(systemName: "minus.magnifyingglass") }
            Button { viewModel.resetViewport() } label: { Image(systemName: "arrow.counterclockwise") }
        }
        .buttonStyle(.bordered)
        .tint(Theme.olive)
        .padding()
    }

    private var zoneDrawingBar: some View {
        HStack(spacing: 12) {
            Text("\(viewModel.draftZonePoints.count) point(s) — touchez la carte")
                .font(.caption)
            Button("Annuler le point", systemImage: "arrow.uturn.backward") { viewModel.undoZonePoint() }
                .disabled(viewModel.draftZonePoints.isEmpty)
            Button("Terminer", systemImage: "checkmark.circle.fill") { viewModel.finishZoneDrawing() }
                .disabled(viewModel.draftZonePoints.count < 3)
                .buttonStyle(.borderedProminent)
                .tint(Theme.leaf)
            Button("Abandonner", role: .destructive) { viewModel.cancelZoneDrawing() }
        }
        .font(.caption)
        .padding(10)
        .background(.regularMaterial, in: Capsule())
        .padding(.bottom, 8)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("Mode", selection: $viewModel.mode) {
                ForEach(GardenMapViewModel.Mode.allCases) { mode in
                    Label(mode.label, systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Ajouter une plante", systemImage: "plus") { viewModel.showAddPlant = true }
                Button("Zone rectangulaire", systemImage: "rectangle.dashed") { viewModel.insertPresetRectangle() }
                Button("Zone à main levée", systemImage: "pencil.and.outline") {
                    viewModel.draftZonePoints = []
                    viewModel.mode = .dessinerZone
                }
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
    }
}

/// Polygone en coordonnées normalisées, rendu dans le rectangle courant.
public struct ZoneShape: Shape {
    let points: [CGPoint]

    public init(points: [CGPoint]) {
        self.points = points
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: first.x * rect.width, y: first.y * rect.height))
        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: point.x * rect.width, y: point.y * rect.height))
        }
        path.closeSubpath()
        return path
    }
}
