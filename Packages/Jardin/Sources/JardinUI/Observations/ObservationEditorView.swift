import JardinCore
import JardinML
import SwiftUI

/// Nouvelle observation : photo (analysée automatiquement — santé, empreinte,
/// croissance), tags et note. La photo taguée alimente l'apprentissage continu.
struct ObservationEditorView: View {
    @ObservedObject var plant: PlantMO
    @EnvironmentObject private var store: GardenStore
    @Environment(\.dismiss) private var dismiss

    @State private var note = ""
    @State private var tags: [String] = []
    @State private var captured: PhotoCaptureButton.Captured?
    @State private var analysis: ObservationAnalysis?
    @State private var analyzing = false
    @State private var feedLearning = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    if let captured {
                        StoredPhotoView(data: captured.stored.thumbnail)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                    }
                    PhotoCaptureButton { newCapture in
                        captured = newCapture
                        runAnalysis(newCapture)
                    }
                    if analyzing {
                        HStack {
                            ProgressView().controlSize(.small)
                            Text("Analyse de la photo…").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let analysis, analysis.healthScore >= 0 {
                        HStack {
                            Text("Santé du feuillage")
                            Spacer()
                            HealthBadge(score: analysis.healthScore)
                        }
                        ForEach(analysis.detectedIssues, id: \.self) { issue in
                            Label(issue, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(Theme.warning)
                        }
                        if let growth = growthPreview {
                            Label(growth, systemImage: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Tags") {
                    TagPickerView(selection: $tags)
                }

                Section("Note") {
                    TextField("Ex : feuilles jaunes après 2 semaines sans pluie…",
                              text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                if captured != nil {
                    Section {
                        Toggle("Ajouter à l'apprentissage", isOn: $feedLearning)
                    } footer: {
                        Text("La photo et ses tags enrichissent la reconnaissance locale de vos plantes. Exportables depuis les Réglages.")
                    }
                }
            }
            .navigationTitle("Observation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer", action: save)
                        .disabled(captured == nil && note.isEmpty && tags.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
    }

    private var growthPreview: String? {
        guard let analysis, analysis.foregroundAreaRatio > 0,
              let previous = plant.observationList.first(where: { $0.foregroundAreaRatio > 0 })
        else { return nil }
        var days: Int?
        if let previousDate = previous.date {
            days = Calendar.current.dateComponents([.day], from: previousDate, to: Date()).day
        }
        return GrowthAnalyzer.compare(previousRatio: previous.foregroundAreaRatio,
                                      currentRatio: analysis.foregroundAreaRatio,
                                      daysBetween: days).message
    }

    private func runAnalysis(_ capture: PhotoCaptureButton.Captured) {
        analyzing = true
        analysis = nil
        Task {
            analysis = await PhotoAnalysisService.analyze(cgImage: capture.cgImage)
            analyzing = false
        }
    }

    private func save() {
        store.addObservation(to: plant,
                             note: note.isEmpty ? nil : note,
                             tags: tags,
                             photo: captured?.stored,
                             analysis: analysis)

        if feedLearning, let captured {
            let label = plant.species?.commonName ?? plant.displayName
            store.recordLearningExample(label: label,
                                        tags: tags,
                                        featurePrint: analysis?.featurePrint,
                                        photo: captured.stored,
                                        source: .manuelle,
                                        plantID: plant.id)
        }

        Task {
            await store.refreshInsights()
            await store.refreshNotificationSchedules()
        }
        dismiss()
    }
}
