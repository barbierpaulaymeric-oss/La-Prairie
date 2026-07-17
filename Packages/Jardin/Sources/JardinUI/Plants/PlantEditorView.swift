import CoreData
import CoreGraphics
import JardinCore
import SwiftUI

/// Création manuelle d'une plante (la reconnaissance photo passe par RecognitionView).
public struct PlantEditorView: View {
    let initialPosition: CGPoint

    @EnvironmentObject private var store: GardenStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var speciesQuery = ""
    @State private var selectedSpecies: PlantSpeciesMO?
    @State private var category: PlantCategory = .potager
    @State private var plantedDate = Date()
    @State private var hasPlantedDate = true

    public init(initialPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)) {
        self.initialPosition = initialPosition
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Plante") {
                    TextField("Nom (ex : Tomate cerise du balcon)", text: $name)
                    Toggle("Date de plantation connue", isOn: $hasPlantedDate)
                    if hasPlantedDate {
                        DatePicker("Plantée le", selection: $plantedDate, displayedComponents: .date)
                    }
                }

                Section("Fiche espèce") {
                    SpeciesSearchField(query: $speciesQuery, selection: $selectedSpecies)
                    if let species = selectedSpecies {
                        LabeledContent("Espèce", value: species.commonName ?? "")
                        LabeledContent("Nom scientifique", value: species.scientificName ?? "—")
                            .font(.caption)
                    } else {
                        Picker("Catégorie (sans fiche)", selection: $category) {
                            ForEach(PlantCategory.allCases) { category in
                                Label(category.label, systemImage: category.systemImage).tag(category)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        PlantIconView(name: selectedSpecies?.commonName ?? name,
                                      category: selectedSpecies?.category ?? category,
                                      size: 52)
                        Text("Icône générée automatiquement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Nouvelle plante")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        let plant = store.createPlant(
                            name: name.isEmpty ? (selectedSpecies?.commonName ?? "Plante") : name,
                            species: selectedSpecies,
                            category: selectedSpecies?.category ?? category,
                            position: initialPosition,
                            plantedDate: hasPlantedDate ? plantedDate : nil
                        )
                        Task { await store.refreshNotificationSchedules() }
                        _ = plant
                        dismiss()
                    }
                    .disabled(name.isEmpty && selectedSpecies == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 480)
        #endif
    }
}

/// Champ de recherche d'espèce avec autocomplétion sur la base de fiches.
public struct SpeciesSearchField: View {
    @Binding var query: String
    @Binding var selection: PlantSpeciesMO?
    @EnvironmentObject private var store: GardenStore

    public init(query: Binding<String>, selection: Binding<PlantSpeciesMO?>) {
        _query = query
        _selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Rechercher une espèce…", text: $query)
                .textFieldStyle(.roundedBorder)
            if selection == nil, !query.isEmpty {
                let matches = store.fetchSpecies(matching: query).prefix(5)
                if matches.isEmpty {
                    Text("Aucune fiche trouvée — la plante sera créée sans fiche.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(matches)) { species in
                        Button {
                            selection = species
                            query = species.commonName ?? ""
                        } label: {
                            HStack {
                                PlantIconView(species: species, size: 24)
                                Text(species.commonName ?? "")
                                Spacer()
                                Text(species.scientificName ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if selection != nil {
                Button("Changer d'espèce", systemImage: "xmark.circle") {
                    selection = nil
                    query = ""
                }
                .font(.caption)
            }
        }
        .onChange(of: query) { _, newValue in
            if let current = selection, current.commonName != newValue { selection = nil }
        }
    }
}
