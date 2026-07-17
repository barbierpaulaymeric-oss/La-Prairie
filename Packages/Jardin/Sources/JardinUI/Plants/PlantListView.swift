import CoreData
import JardinCore
import SwiftUI

public struct PlantListView: View {
    @EnvironmentObject private var appEnv: AppEnvironment
    @EnvironmentObject private var store: GardenStore

    @FetchRequest(entity: PlantMO.entity(),
                  sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var plants: FetchedResults<PlantMO>

    @FetchRequest(entity: GardenZoneMO.entity(),
                  sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var zones: FetchedResults<GardenZoneMO>

    @State private var filter = PlantFilter()
    @State private var showFilters = false
    @State private var showAddPlant = false
    @State private var showRecognition = false

    public init() {}

    private var filtered: [PlantMO] {
        plants.filter { filter.matches($0) }
    }

    public var body: some View {
        List {
            if filtered.isEmpty {
                EmptyStateView(systemImage: "leaf",
                               title: "Aucune plante",
                               message: filter.isActive || !filter.searchText.isEmpty
                                   ? "Aucun résultat pour ces critères."
                                   : "Ajoutez votre première plante ou identifiez-la par photo.")
            }
            ForEach(filtered) { plant in
                // NavigationLink(value: UUID?) pousse un UUID non optionnel :
                // la destination doit être enregistrée pour UUID.self, pas UUID?.self.
                NavigationLink(value: plant.id ?? UUID()) {
                    PlantRowView(plant: plant)
                }
            }
            .onDelete { indexSet in
                for index in indexSet { store.deletePlant(filtered[index]) }
            }
        }
        .navigationTitle("Mes plantes")
        .navigationDestination(for: UUID.self) { id in
            if let plant = store.plant(withID: id) {
                PlantDetailView(plant: plant)
            }
        }
        .searchable(text: $filter.searchText, prompt: "Nom, espèce, note, tag…")
        .searchSuggestions {
            ForEach(PlantFilter.suggestions(for: filter.searchText, plants: Array(plants)), id: \.self) { suggestion in
                Text(suggestion).searchCompletion(suggestion)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showRecognition = true
                } label: {
                    Label("Identifier par photo", systemImage: "camera.viewfinder")
                }
                Button {
                    showFilters = true
                } label: {
                    Label("Filtres", systemImage: filter.isActive
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle")
                }
                Button {
                    showAddPlant = true
                } label: {
                    Label("Ajouter", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            PlantFilterSheet(filter: $filter, zoneNames: zones.compactMap(\.name))
        }
        .sheet(isPresented: $showAddPlant) {
            PlantEditorView()
        }
        .sheet(isPresented: $showRecognition) {
            NavigationStack { RecognitionView(store: store, identifier: appEnv.identifier) }
        }
    }
}

struct PlantRowView: View {
    @ObservedObject var plant: PlantMO

    var body: some View {
        HStack(spacing: 12) {
            PlantIconView(plant: plant, size: 30)
                .frame(width: Theme.Metrics.cellIcon, height: Theme.Metrics.cellIcon)
                .background(Theme.subtleBackground, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(plant.displayName)
                    .font(.headline)
                HStack(spacing: 6) {
                    if let species = plant.species?.commonName {
                        Text(species)
                    }
                    if let zone = plant.zone?.name {
                        Text("· \(zone)")
                    }
                    if let age = plant.ageDescription {
                        Text("· \(age)")
                    }
                }
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if let lastObservation = plant.lastObservation, lastObservation.hasHealthScore {
                HealthBadge(score: lastObservation.healthScore)
            }
            Image(systemName: "drop.fill")
                .foregroundStyle(Theme.accent.opacity(0.7))
                .imageScale(.small)
                .overlay(alignment: .bottom) {
                    Text("\(plant.wateringIntervalDays)j")
                        .font(.system(size: 8))
                        .offset(y: 10)
                        .foregroundStyle(.secondary)
                }
        }
        .padding(.vertical, 2)
        .opacity(plant.archived ? 0.5 : 1)
    }
}

struct PlantFilterSheet: View {
    @Binding var filter: PlantFilter
    let zoneNames: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Caractéristiques") {
                    Picker("Type", selection: $filter.category) {
                        Text("Tous").tag(PlantCategory?.none)
                        ForEach(PlantCategory.allCases) { category in
                            Text(category.label).tag(PlantCategory?.some(category))
                        }
                    }
                    Picker("Besoin en eau", selection: $filter.waterNeed) {
                        Text("Tous").tag(WaterNeed?.none)
                        ForEach(WaterNeed.allCases) { need in
                            Text(need.label).tag(WaterNeed?.some(need))
                        }
                    }
                    Picker("Lumière", selection: $filter.sunNeed) {
                        Text("Toutes").tag(SunNeed?.none)
                        ForEach(SunNeed.allCases) { need in
                            Text(need.label).tag(SunNeed?.some(need))
                        }
                    }
                }
                Section("Saison et lieu") {
                    Picker("À récolter en", selection: $filter.harvestMonth) {
                        Text("Toute l'année").tag(Int?.none)
                        ForEach(1...12, id: \.self) { month in
                            Text(Months.label(for: month)).tag(Int?.some(month))
                        }
                    }
                    Picker("Zone", selection: $filter.zoneName) {
                        Text("Toutes").tag(String?.none)
                        ForEach(zoneNames, id: \.self) { name in
                            Text(name).tag(String?.some(name))
                        }
                    }
                }
                Section("État") {
                    Toggle("Problèmes récents uniquement", isOn: $filter.onlyWithIssues)
                    Toggle("Inclure les plantes archivées", isOn: $filter.includeArchived)
                    Picker("Tag d'observation", selection: $filter.tag) {
                        Text("Tous").tag(String?.none)
                        ForEach(ObservationTags.presets, id: \.self) { tag in
                            Text("#\(tag)").tag(String?.some(tag))
                        }
                    }
                }
                Section {
                    Button("Réinitialiser les filtres", role: .destructive) {
                        let text = filter.searchText
                        filter = PlantFilter()
                        filter.searchText = text
                    }
                }
            }
            .navigationTitle("Filtres")
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
        .frame(minWidth: 380, minHeight: 420)
        #endif
    }
}
