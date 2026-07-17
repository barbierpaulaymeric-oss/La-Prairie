import CoreData
import JardinCore
import JardinML
import SwiftUI

/// Flux « Identifier une plante » : photo → candidats avec confiance →
/// validation/correction (qui nourrit l'apprentissage) → création ou rattachement.
/// Les dépendances sont injectées par le parent (elles viennent de l'environnement).
public struct RecognitionView: View {
    @EnvironmentObject private var store: GardenStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: RecognitionViewModel
    @State private var showManualPicker = false
    @State private var attachSheetCandidate: IdentificationCandidate?

    public init(store: GardenStore, identifier: CompositePlantIdentifier) {
        _viewModel = StateObject(wrappedValue: RecognitionViewModel(store: store, identifier: identifier))
    }

    public var body: some View {
        content
            .navigationTitle("Identifier une plante")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .pickPhoto:
            RecognitionPickView { capture in
                viewModel.identify(capture)
            }
        case .analyzing:
            VStack(spacing: 16) {
                ProgressView()
                Text("Analyse en cours…")
                Text("Sources : votre jardin, modèle local, Vision" +
                     (RemoteAPIConfiguration.fromDefaults() != nil ? ", API en ligne" : ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .results:
            resultsView
        case .confirmed:
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.leaf)
                Text("Plante enregistrée !")
                    .font(.title3.weight(.semibold))
                Text("La photo enrichit l'apprentissage : la prochaine identification de cette plante sera plus fiable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Identifier une autre plante") { viewModel.reset() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.leaf)
                Button("Fermer") { dismiss() }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var resultsView: some View {
        List {
            if let captured = viewModel.captured {
                Section {
                    StoredPhotoView(data: captured.stored.thumbnail)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                }
            }

            if let analysis = viewModel.analysis, analysis.healthScore >= 0 {
                Section("État de la plante") {
                    HStack {
                        Text("Santé du feuillage")
                        Spacer()
                        HealthBadge(score: analysis.healthScore)
                    }
                    ForEach(analysis.detectedIssues, id: \.self) { issue in
                        Label(issue, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(Theme.carrotOrange)
                    }
                }
            }

            Section {
                if let outcome = viewModel.outcome, !outcome.candidates.isEmpty {
                    ForEach(outcome.candidates) { candidate in
                        Button {
                            attachSheetCandidate = candidate
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    PlantIconView(kind: PlantIconKind.detect(name: candidate.name, category: .autre),
                                                  size: 30)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(candidate.name).font(.body.weight(.medium))
                                        if let scientific = candidate.scientificName {
                                            Text(scientific).font(.caption2).italic().foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(candidate.source.label)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Theme.beige, in: Capsule())
                                        .foregroundStyle(Theme.olive)
                                }
                                ConfidenceBar(value: candidate.confidence)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("Aucune correspondance trouvée.")
                        .foregroundStyle(.secondary)
                }

                Button {
                    showManualPicker = true
                } label: {
                    Label("Aucune de ces propositions — recherche manuelle", systemImage: "magnifyingglass")
                }
            } header: {
                Text("Propositions")
            } footer: {
                if let outcome = viewModel.outcome {
                    Text("Sources consultées : " + outcome.usedSources.map(\.label).joined(separator: ", ") +
                         ". Valider ou corriger améliore les prochaines identifications.")
                }
            }

            Section {
                Button("Reprendre une photo") { viewModel.reset() }
            }
        }
        .sheet(item: $attachSheetCandidate) { candidate in
            RecognitionConfirmSheet(candidateName: candidate.name) { existingPlant, newName in
                viewModel.confirm(candidate: candidate, manualSpecies: nil,
                                  attachTo: existingPlant, newPlantName: newName)
            }
        }
        .sheet(isPresented: $showManualPicker) {
            ManualSpeciesPicker { species in
                viewModel.confirm(candidate: nil, manualSpecies: species,
                                  attachTo: nil, newPlantName: nil)
            }
        }
    }
}

/// Écran d'accueil de la reconnaissance (choix de photo).
struct RecognitionPickView: View {
    let onCapture: (PhotoCaptureButton.Captured) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(Theme.leaf)
            Text("Photographiez une plante")
                .font(.title3.weight(.semibold))
            Text("L'app l'identifie, détecte les problèmes visibles et remplit sa fiche automatiquement. Chaque validation ou correction améliore la reconnaissance.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            PhotoCaptureButton(onCapture: onCapture)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Choix après validation d'un candidat : nouvelle plante ou observation d'une existante.
struct RecognitionConfirmSheet: View {
    let candidateName: String
    let onConfirm: (PlantMO?, String?) -> Void

    @EnvironmentObject private var store: GardenStore
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""

    @FetchRequest(entity: PlantMO.entity(),
                  sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
                  predicate: NSPredicate(format: "archived == NO"))
    private var plants: FetchedResults<PlantMO>

    var body: some View {
        NavigationStack {
            Form {
                Section("Nouvelle plante « \(candidateName) »") {
                    TextField("Nom personnalisé (optionnel)", text: $newName)
                    Button {
                        onConfirm(nil, newName)
                        dismiss()
                    } label: {
                        Label("Créer sur la carte", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.leaf)
                }

                if !plants.isEmpty {
                    Section("… ou rattacher la photo à une plante existante") {
                        ForEach(plants) { plant in
                            Button {
                                onConfirm(plant, nil)
                                dismiss()
                            } label: {
                                HStack {
                                    PlantIconView(plant: plant, size: 28)
                                    Text(plant.displayName)
                                    Spacer()
                                    if let zone = plant.zone?.name {
                                        Text(zone).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Confirmer")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
    }
}

/// Recherche manuelle dans la base de fiches (correction d'identification).
struct ManualSpeciesPicker: View {
    let onPick: (PlantSpeciesMO) -> Void

    @EnvironmentObject private var store: GardenStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.fetchSpecies(matching: query.isEmpty ? nil : query)) { species in
                    Button {
                        onPick(species)
                        dismiss()
                    } label: {
                        HStack {
                            PlantIconView(species: species, size: 30)
                            VStack(alignment: .leading) {
                                Text(species.commonName ?? "")
                                Text(species.scientificName ?? "")
                                    .font(.caption2).italic().foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(species.category.label)
                                .font(.caption2)
                                .foregroundStyle(Theme.olive)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $query, prompt: "Nom commun ou scientifique")
            .navigationTitle("Choisir l'espèce")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
    }
}
