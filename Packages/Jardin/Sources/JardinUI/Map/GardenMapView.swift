import CoreData
import JardinCore
import SwiftUI

/// Plan du jardin à l'échelle réelle : dimensions en mètres (réglables), grille
/// métrique, barre d'échelle, plantes dessinées à leur emprise au sol, zones
/// éditables (sommets déplaçables, ajout/suppression de points, déplacement).
/// Coordonnées stockées normalisées (0…1) → indépendantes de la taille d'écran.
public struct GardenMapView: View {
    @EnvironmentObject private var appEnv: AppEnvironment
    @EnvironmentObject private var store: GardenStore
    @StateObject private var viewModel = GardenMapViewModel()

    @AppStorage("gardenWidthM") private var gardenWidthM: Double = 12
    @AppStorage("gardenHeightM") private var gardenHeightM: Double = 8

    @FetchRequest(entity: PlantMO.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
                  predicate: NSPredicate(format: "archived == NO"))
    private var plants: FetchedResults<PlantMO>

    @FetchRequest(entity: GardenZoneMO.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var zones: FetchedResults<GardenZoneMO>

    public init() {}

    private var selectedZone: GardenZoneMO? {
        guard let id = viewModel.selectedZoneID else { return nil }
        return zones.first { $0.id == id }
    }

    public var body: some View {
        GeometryReader { geo in
            let content = contentSize(available: geo.size)
            ZStack {
                Theme.mapBackground.ignoresSafeArea()
                mapContent(size: content)
                    .frame(width: content.width, height: content.height)
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipped()
            .contentShape(Rectangle())
            .gesture(panGesture, including: viewModel.mode == .explorer ? .all : .subviews)
            .simultaneousGesture(magnificationGesture)
            .overlay(alignment: .bottomLeading) {
                scaleBar(contentWidth: content.width)
            }
        }
        .overlay(alignment: .bottomTrailing) { zoomControls }
        .overlay(alignment: .bottom) { bottomBar }
        .navigationTitle("Carte du jardin")
        .toolbar { toolbarContent }
        .sheet(isPresented: $viewModel.showAddPlant) {
            PlantEditorView(initialPosition: CGPoint(x: 0.5, y: 0.5))
        }
        .sheet(isPresented: $viewModel.showZoneEditor) {
            ZoneEditorView(points: viewModel.draftZonePoints) {
                viewModel.draftZonePoints = []
                viewModel.mode = .secteurs
            }
        }
        .sheet(isPresented: $viewModel.showZoneInfo) {
            if let zone = selectedZone {
                ZoneInfoSheet(zone: zone) {
                    viewModel.selectedZoneID = nil
                }
            }
        }
        .sheet(isPresented: $viewModel.showDimensionsSheet) {
            GardenDimensionsSheet(widthM: $gardenWidthM, heightM: $gardenHeightM)
        }
        .sheet(item: Binding(
            get: { viewModel.selectedPlantID.flatMap { store.plant(withID: $0) } },
            set: { viewModel.selectedPlantID = $0?.id }
        )) { plant in
            NavigationStack { PlantDetailView(plant: plant) }
        }
    }

    // MARK: Géométrie réelle

    /// Rect du jardin, à l'aspect largeur/hauteur réel, inscrit dans l'espace disponible.
    private func contentSize(available: CGSize) -> CGSize {
        let aspect = CGFloat(max(gardenWidthM, 0.5) / max(gardenHeightM, 0.5))
        let availW = max(available.width - 16, 80)
        let availH = max(available.height - 16, 80)
        let width = min(availW, availH * aspect)
        return CGSize(width: width, height: width / aspect)
    }

    /// Pixels par mètre au niveau de zoom 1.
    private func pixelsPerMeter(contentWidth: CGFloat) -> CGFloat {
        contentWidth / CGFloat(max(gardenWidthM, 0.5))
    }

    // MARK: Contenu de la carte

    private func mapContent(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.mapBackground)
            meterGrid(size: size)

            ForEach(zones) { zone in
                zoneLayer(zone, size: size)
            }

            if !viewModel.draftZonePoints.isEmpty {
                ZoneShape(points: viewModel.draftZonePoints)
                    .stroke(Theme.danger, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                ForEach(Array(viewModel.draftZonePoints.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(Theme.danger)
                        .frame(width: 8, height: 8)
                        .position(x: point.x * size.width, y: point.y * size.height)
                }
            }

            ForEach(plants) { plant in
                plantMarker(plant, size: size)
            }

            if let zone = selectedZone, viewModel.mode == .secteurs {
                zoneEditHandles(zone, size: size)
            }
        }
        .coordinateSpace(name: "gardenMap")
        .onTapGesture(coordinateSpace: .named("gardenMap")) { location in
            let normalized = CGPoint(x: location.x / size.width, y: location.y / size.height)
            switch viewModel.mode {
            case .dessinerZone:
                viewModel.handleZoneTap(at: normalized)
            case .secteurs:
                viewModel.selectedZoneID = zones.first { $0.contains(normalized) }?.id
            default:
                break
            }
        }
    }

    /// Grille au pas de 1 m (5 m au-delà de 25 m de côté), pour lire les distances.
    private func meterGrid(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let stepMeters: Double = max(gardenWidthM, gardenHeightM) > 25 ? 5 : 1
            let stepX = canvasSize.width / CGFloat(gardenWidthM / stepMeters)
            let stepY = canvasSize.height / CGFloat(gardenHeightM / stepMeters)
            guard stepX > 4, stepY > 4 else { return }
            var path = Path()
            var x = stepX
            while x < canvasSize.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                x += stepX
            }
            var y = stepY
            while y < canvasSize.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                y += stepY
            }
            context.stroke(path, with: .color(Theme.secondaryTint.opacity(0.10)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    // MARK: Zones

    @ViewBuilder
    private func zoneLayer(_ zone: GardenZoneMO, size: CGSize) -> some View {
        let isSelected = zone.id == viewModel.selectedZoneID && viewModel.mode == .secteurs
        let color = Theme.zoneColor(zone.kind)

        ZoneShape(points: zone.points)
            .fill(color.opacity(isSelected ? 0.34 : 0.22))
        ZoneShape(points: zone.points)
            .stroke(color.opacity(isSelected ? 1 : 0.75),
                    style: StrokeStyle(lineWidth: isSelected ? 2.5 : 1.5, dash: isSelected ? [] : [6, 3]))

        let centroid = Self.centroid(of: zone.points)
        VStack(spacing: 1) {
            Text(zone.name ?? "Zone")
                .font(.caption2.weight(.semibold))
            if let area = zoneAreaLabel(zone) {
                Text(area).font(.system(size: 8))
            }
        }
        .foregroundStyle(Theme.secondaryTint)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Theme.cardBackground.opacity(0.7), in: Capsule())
        .position(x: centroid.x * size.width, y: centroid.y * size.height)
        .allowsHitTesting(false)

        // Déplacement de la zone entière (mode Secteurs, zone sélectionnée).
        if isSelected {
            ZoneShape(points: zone.points)
                .fill(Color.white.opacity(0.001))
                .gesture(zoneMoveGesture(zone, size: size))
        }
    }

    /// Surface réelle du secteur (formule du lacet, en m²).
    private func zoneAreaLabel(_ zone: GardenZoneMO) -> String? {
        let points = zone.points
        guard points.count >= 3 else { return nil }
        var doubled: Double = 0
        for index in 0..<points.count {
            let a = points[index], b = points[(index + 1) % points.count]
            doubled += Double(a.x * b.y - b.x * a.y)
        }
        let area = abs(doubled) / 2 * gardenWidthM * gardenHeightM
        return area < 1 ? String(format: "%.1f m²", area) : "\(Int(area.rounded())) m²"
    }

    private func zoneMoveGesture(_ zone: GardenZoneMO, size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("gardenMap"))
            .onChanged { value in
                if viewModel.zoneDragStartPoints == nil {
                    viewModel.zoneDragStartPoints = zone.points
                }
                guard let start = viewModel.zoneDragStartPoints else { return }
                let dx = value.translation.width / size.width
                let dy = value.translation.height / size.height
                zone.points = start.map {
                    CGPoint(x: $0.x + dx, y: $0.y + dy).clampedToUnit
                }
            }
            .onEnded { _ in
                viewModel.zoneDragStartPoints = nil
                store.save()
            }
    }

    /// Poignées d'édition : sommets déplaçables + insertion aux milieux d'arêtes.
    @ViewBuilder
    private func zoneEditHandles(_ zone: GardenZoneMO, size: CGSize) -> some View {
        let points = zone.points

        // Insertion d'un sommet au milieu de chaque arête.
        ForEach(points.indices, id: \.self) { index in
            let next = points[(index + 1) % points.count]
            let mid = CGPoint(x: (points[index].x + next.x) / 2, y: (points[index].y + next.y) / 2)
            Button {
                var updated = points
                updated.insert(mid, at: index + 1)
                zone.points = updated
                store.save()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 15, height: 15)
                    .background(Theme.secondaryTint.opacity(0.8), in: Circle())
            }
            .buttonStyle(.plain)
            .position(x: mid.x * size.width, y: mid.y * size.height)
        }

        // Sommets déplaçables (menu contextuel pour supprimer).
        ForEach(points.indices, id: \.self) { index in
            Circle()
                .fill(viewModel.draggingVertexIndex == index ? Theme.danger : Theme.cardBackground)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(Theme.danger, lineWidth: 2))
                .position(x: points[index].x * size.width, y: points[index].y * size.height)
                .gesture(
                    DragGesture(minimumDistance: 1, coordinateSpace: .named("gardenMap"))
                        .onChanged { value in
                            viewModel.draggingVertexIndex = index
                            var updated = zone.points
                            guard updated.indices.contains(index) else { return }
                            updated[index] = CGPoint(x: value.location.x / size.width,
                                                     y: value.location.y / size.height).clampedToUnit
                            zone.points = updated
                        }
                        .onEnded { _ in
                            viewModel.draggingVertexIndex = nil
                            store.save()
                        }
                )
                .contextMenu {
                    Button("Supprimer ce sommet", systemImage: "trash", role: .destructive) {
                        guard zone.points.count > 3 else { return }
                        var updated = zone.points
                        updated.remove(at: index)
                        zone.points = updated
                        store.save()
                    }
                    .disabled(zone.points.count <= 3)
                }
        }
    }

    static func centroid(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return CGPoint(x: 0.5, y: 0.5) }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }

    // MARK: Plantes

    private func plantMarker(_ plant: PlantMO, size: CGSize) -> some View {
        let isDragging = viewModel.draggingPlantID == plant.id
        let ppm = pixelsPerMeter(contentWidth: size.width)
        // Emprise réelle de la plante, bornée pour rester lisible et tapable.
        let diameter = min(max(CGFloat(plant.effectiveSpreadM) * ppm, 18), size.width * 0.6)
        let showLabel = diameter * viewModel.scale >= 26

        return VStack(spacing: 2) {
            PlantIconView(plant: plant, size: diameter * 0.82)
                .padding(diameter * 0.09)
                .background(Theme.cardBackground.opacity(0.85), in: Circle())
                .overlay(Circle().stroke(isDragging ? Theme.danger : Theme.accent.opacity(0.55),
                                         lineWidth: isDragging ? 2.5 : 1.5))
                .shadow(color: .black.opacity(isDragging ? 0.25 : 0.08), radius: isDragging ? 8 : 3, y: 2)
            if showLabel {
                Text(plant.displayName)
                    .font(.system(size: max(8, min(diameter * 0.16, 11)), weight: .medium))
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .background(Theme.cardBackground.opacity(0.85), in: Capsule())
            }
        }
        .scaleEffect(isDragging ? 1.1 : 1)
        .position(x: plant.posX * size.width, y: plant.posY * size.height)
        .onTapGesture {
            if viewModel.mode == .explorer { viewModel.selectedPlantID = plant.id }
        }
        .gesture(moveGesture(for: plant, size: size))
        .animation(.spring(duration: 0.2), value: isDragging)
        .accessibilityLabel("\(plant.displayName), \(Formatters.meters(plant.effectiveSpreadM)) d'emprise, \(plant.zone?.name ?? "hors zone")")
    }

    private func moveGesture(for plant: PlantMO, size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("gardenMap"))
            .onChanged { value in
                guard viewModel.mode == .deplacer else { return }
                viewModel.draggingPlantID = plant.id
                plant.posX = min(max(value.location.x / size.width, 0), 1)
                plant.posY = min(max(value.location.y / size.height, 0), 1)
            }
            .onEnded { value in
                guard viewModel.mode == .deplacer else { return }
                viewModel.draggingPlantID = nil
                store.movePlant(plant, to: CGPoint(x: value.location.x / size.width,
                                                   y: value.location.y / size.height))
            }
    }

    // MARK: Gestes globaux et habillage

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in viewModel.applyPan(value.translation) }
            .onEnded { _ in viewModel.endPan() }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { viewModel.applyMagnification($0) }
            .onEnded { _ in viewModel.endMagnification() }
    }

    /// Barre d'échelle : longueur « ronde » (25 cm à 20 m) adaptée au zoom courant.
    private func scaleBar(contentWidth: CGFloat) -> some View {
        let ppm = pixelsPerMeter(contentWidth: contentWidth) * viewModel.scale
        let candidates: [Double] = [0.25, 0.5, 1, 2, 5, 10, 20]
        let meters = candidates.first { CGFloat($0) * ppm >= 54 } ?? 20
        let barWidth = min(CGFloat(meters) * ppm, 220)

        return VStack(alignment: .leading, spacing: 3) {
            Text(meters < 1 ? "\(Int(meters * 100)) cm" : "\(Int(meters)) m")
                .font(Theme.dataS)
            HStack(spacing: 0) {
                Rectangle().frame(width: 2, height: 8)
                Rectangle().frame(width: max(barWidth - 4, 10), height: 3)
                Rectangle().frame(width: 2, height: 8)
            }
        }
        .foregroundStyle(Theme.secondaryTint)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(10)
        .accessibilityLabel("Échelle : \(meters < 1 ? "\(Int(meters * 100)) centimètres" : "\(Int(meters)) mètres")")
    }

    private var zoomControls: some View {
        VStack(spacing: 10) {
            Button { viewModel.zoom(by: 1.3) } label: { Image(systemName: "plus.magnifyingglass") }
            Button { viewModel.zoom(by: 1 / 1.3) } label: { Image(systemName: "minus.magnifyingglass") }
            Button { viewModel.resetViewport() } label: { Image(systemName: "arrow.counterclockwise") }
        }
        .buttonStyle(.bordered)
        .tint(Theme.secondaryTint)
        .padding()
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch viewModel.mode {
        case .dessinerZone:
            HStack(spacing: 12) {
                Text("\(viewModel.draftZonePoints.count) point(s) — touchez la carte")
                Button("Annuler le point", systemImage: "arrow.uturn.backward") { viewModel.undoZonePoint() }
                    .disabled(viewModel.draftZonePoints.isEmpty)
                Button("Terminer", systemImage: "checkmark.circle.fill") { viewModel.finishZoneDrawing() }
                    .disabled(viewModel.draftZonePoints.count < 3)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                Button("Abandonner", role: .destructive) { viewModel.cancelZoneDrawing() }
            }
            .font(.caption)
            .padding(10)
            .background(.regularMaterial, in: Capsule())
            .padding(.bottom, 8)
        case .secteurs:
            HStack(spacing: 12) {
                if let zone = selectedZone {
                    Text(zone.name ?? "Secteur").font(.caption.weight(.semibold))
                    Button("Infos", systemImage: "info.circle") { viewModel.showZoneInfo = true }
                    Button("Terminer", systemImage: "checkmark.circle") { viewModel.selectedZoneID = nil }
                } else {
                    Label("Touchez un secteur pour déplacer ses sommets, l'agrandir ou le modifier",
                          systemImage: "hand.tap")
                }
            }
            .font(.caption)
            .padding(10)
            .background(.regularMaterial, in: Capsule())
            .padding(.bottom, 8)
        default:
            EmptyView()
        }
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
                Divider()
                Button("Dimensions du jardin…", systemImage: "ruler") { viewModel.showDimensionsSheet = true }
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

/// Réglage des dimensions réelles du jardin (base de l'échelle).
struct GardenDimensionsSheet: View {
    @Binding var widthM: Double
    @Binding var heightM: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    dimensionRow(title: "Largeur", value: $widthM)
                    dimensionRow(title: "Hauteur", value: $heightM)
                } header: {
                    Text("Dimensions du terrain")
                } footer: {
                    Text("Ces dimensions calent l'échelle de la carte : la grille est au pas de 1 m (5 m pour les grands terrains) et les plantes sont dessinées à leur emprise au sol réelle.")
                }
                Section("Formats courants") {
                    ForEach([(6.0, 4.0, "Petit potager"), (12.0, 8.0, "Jardin de ville"),
                             (25.0, 15.0, "Grand jardin"), (50.0, 30.0, "Verger / terrain")], id: \.2) { preset in
                        Button {
                            widthM = preset.0
                            heightM = preset.1
                        } label: {
                            LabeledContent(preset.2, value: "\(Int(preset.0)) × \(Int(preset.1)) m")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Échelle")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 360)
        #endif
    }

    private func dimensionRow(title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: Binding(
                get: { value.wrappedValue },
                set: { value.wrappedValue = min(max($0, 1), 500) }
            ), format: .number.precision(.fractionLength(0...1)))
                .multilineTextAlignment(.trailing)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .frame(width: 70)
            Text("m").foregroundStyle(.secondary)
            Stepper("", value: value, in: 1...500, step: 1).labelsHidden()
        }
    }
}
