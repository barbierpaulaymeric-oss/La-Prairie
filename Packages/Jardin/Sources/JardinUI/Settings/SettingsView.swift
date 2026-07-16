import CoreData
import JardinCore
import JardinML
import SwiftUI
import UniformTypeIdentifiers

public struct SettingsView: View {
    @EnvironmentObject private var appEnv: AppEnvironment
    @EnvironmentObject private var store: GardenStore

    @AppStorage(AppEnvironment.notificationsKey) private var notificationsEnabled = true
    @AppStorage(AppEnvironment.weatherKey) private var weatherEnabled = false
    @AppStorage(RemoteAPIConfiguration.providerDefaultsKey) private var remoteProvider = ""
    @AppStorage(RemoteAPIConfiguration.apiKeyDefaultsKey) private var remoteAPIKey = ""

    @State private var exportDocument: ExportDocument?
    @State private var exportFilename = ""
    @State private var showExporter = false
    @State private var learningExportURL: URL?
    @State private var showLearningImporter = false
    @State private var statusMessage: String?

    public init() {}

    public var body: some View {
        Form {
            demoSection
            syncSection
            notificationSection
            recognitionSection
            exportSection
            learningSection
            aboutSection
        }
        .navigationTitle("Réglages")
        .fileExporter(isPresented: $showExporter,
                      document: exportDocument,
                      contentType: exportDocument?.contentType ?? .data,
                      defaultFilename: exportFilename) { result in
            if case .success = result { statusMessage = "Export réussi." }
        }
        .fileImporter(isPresented: $showLearningImporter,
                      allowedContentTypes: [.folder]) { result in
            importLearningDataset(result)
        }
        .alert("Jardin Intelligent", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusMessage ?? "")
        }
    }

    // MARK: Sections

    private var demoSection: some View {
        Section {
            Toggle("Mode démo", isOn: $appEnv.demoMode)
        } footer: {
            Text("Le mode démo charge un jardin d'exemple (zones, plantes, deux saisons de récoltes, observations) sans toucher à vos données. Idéal pour découvrir l'app.")
        }
    }

    private var syncSection: some View {
        Section("iCloud") {
            LabeledContent("Synchronisation") {
                Label(store.persistence.cloudSyncActive ? "Active" : "Locale uniquement",
                      systemImage: store.persistence.cloudSyncActive ? "icloud.fill" : "icloud.slash")
                    .foregroundStyle(store.persistence.cloudSyncActive ? Theme.leaf : .secondary)
            }
            if !store.persistence.cloudSyncActive {
                Text("Vérifiez que vous êtes connecté à iCloud et que l'app dispose de l'entitlement CloudKit. Les données restent enregistrées localement.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var notificationSection: some View {
        Section("Notifications") {
            Toggle("Rappels (arrosage, récoltes, alertes)", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, _ in
                    Task { await store.refreshNotificationSchedules() }
                }
            Toggle("Ajuster selon la météo locale", isOn: $weatherEnabled)
                .onChange(of: weatherEnabled) { _, enabled in
                    if enabled { Task { await appEnv.performDailyRefresh() } }
                }
            Button("Autoriser les notifications…") {
                Task {
                    let granted = await NotificationScheduler.shared.requestAuthorization()
                    statusMessage = granted ? "Notifications autorisées." : "Autorisation refusée — activez-les dans Réglages système."
                    await store.refreshNotificationSchedules()
                }
            }
        } footer: {
            Text("La fréquence se personnalise plante par plante dans sa fiche. La météo (WeatherKit) requiert l'autorisation de localisation et reporte l'arrosage en cas de pluie prévue.")
        }
    }

    private var recognitionSection: some View {
        Section("Reconnaissance — API de secours") {
            Picker("Fournisseur", selection: $remoteProvider) {
                Text("Aucun (100 % local)").tag("")
                ForEach(RemoteAPIConfiguration.Provider.allCases, id: \.rawValue) { provider in
                    Text(provider.label).tag(provider.rawValue)
                }
            }
            if !remoteProvider.isEmpty {
                SecureField("Clé API", text: $remoteAPIKey)
            }
        } footer: {
            Text("Optionnel : si la reconnaissance locale (vos photos + Vision + modèle embarqué) manque de confiance, l'app peut interroger Pl@ntNet ou Plant.id. La photo est alors envoyée à ce service.")
        }
        .onChange(of: remoteProvider) { _, _ in appEnv.reloadRemoteAPIConfiguration() }
        .onChange(of: remoteAPIKey) { _, _ in appEnv.reloadRemoteAPIConfiguration() }
    }

    private var exportSection: some View {
        Section("Exports") {
            Button("Plantes (CSV)") {
                export(ExportService.plantsCSV(ExportService.plantDTOs(in: store.context)),
                       type: .commaSeparatedText, filename: "plantes.csv")
            }
            Button("Plantes (JSON)") {
                exportJSON(ExportService.plantDTOs(in: store.context), filename: "plantes.json")
            }
            Button("Récoltes (CSV)") {
                export(ExportService.harvestsCSV(ExportService.harvestDTOs(in: store.context)),
                       type: .commaSeparatedText, filename: "recoltes.csv")
            }
            Button("Récoltes (JSON)") {
                exportJSON(ExportService.harvestDTOs(in: store.context), filename: "recoltes.json")
            }
            Button("Carte du jardin (PDF)") {
                exportMapPDF()
            }
        }
    }

    private var learningSection: some View {
        Section("Données d'apprentissage") {
            LabeledContent("Exemples enregistrés", value: "\(store.learningExampleCount())")
            Button("Exporter le dataset (photos + tags)") {
                exportLearningDataset()
            }
            if let url = learningExportURL {
                ShareLink(item: url) {
                    Label("Partager le dernier export", systemImage: "square.and.arrow.up")
                }
            }
            Button("Importer un dataset…") {
                showLearningImporter = true
            }
        } footer: {
            Text("Le dataset (manifest.json + images) sert à réentraîner un modèle Core ML avec MLTraining/retrain_from_export.py, ou à retrouver vos exemples sur un autre appareil.")
        }
    }

    private var aboutSection: some View {
        Section("À propos") {
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev")
            LabeledContent("Conflits de synchronisation", value: "Dernière modification gagnante")
                .font(.caption)
            Text("Vos photos et données d'apprentissage restent sur vos appareils et votre iCloud, sauf si vous activez l'API de secours.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Actions

    private func export(_ text: String, type: UTType, filename: String) {
        exportDocument = ExportDocument(data: Data(text.utf8), contentType: type)
        exportFilename = filename
        showExporter = true
    }

    private func exportJSON<T: Encodable>(_ value: T, filename: String) {
        guard let data = try? ExportService.json(value) else {
            statusMessage = "Échec de l'encodage JSON."
            return
        }
        exportDocument = ExportDocument(data: data, contentType: .json)
        exportFilename = filename
        showExporter = true
    }

    private func exportMapPDF() {
        let zones = (try? store.context.fetch(NSFetchRequest<GardenZoneMO>(entityName: "GardenZone"))) ?? []
        let plants = store.fetchAllPlants().filter { !$0.archived }
        guard let data = MapPDFExporter.pdfData(zones: zones, plants: plants) else {
            statusMessage = "Impossible de générer le PDF."
            return
        }
        exportDocument = ExportDocument(data: data, contentType: .pdf)
        exportFilename = "carte-jardin.pdf"
        showExporter = true
    }

    private func exportLearningDataset() {
        do {
            let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let folder = try ExportService.exportLearningDataset(in: store.context, to: base)
            learningExportURL = folder
            statusMessage = "Dataset exporté dans « \(folder.lastPathComponent) » (dossier Documents de l'app)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func importLearningDataset(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let count = try ExportService.importLearningDataset(from: url, in: store.context)
            statusMessage = "\(count) exemple(s) importé(s)."
        } catch {
            statusMessage = "Import impossible : \(error.localizedDescription)"
        }
    }
}
