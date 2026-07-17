import Charts
import JardinCore
import JardinML
import SwiftUI

public struct PlantDetailView: View {
    @ObservedObject var plant: PlantMO
    @EnvironmentObject private var store: GardenStore
    @Environment(\.dismiss) private var dismiss

    @State private var showObservationEditor = false
    @State private var showHarvestEditor = false
    @State private var confirmDelete = false

    public init(plant: PlantMO) {
        self.plant = plant
    }

    public var body: some View {
        List {
            headerSection
            careSection
            if plant.species != nil {
                SpeciesFicheView(plant: plant)
            }
            growthSection
            observationsSection
            harvestsSection
            dangerSection
        }
        .navigationTitle(plant.displayName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showObservationEditor) {
            ObservationEditorView(plant: plant)
        }
        .sheet(isPresented: $showHarvestEditor) {
            HarvestEditorView(plant: plant)
        }
        .confirmationDialog("Supprimer cette plante et tout son historique ?",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                store.deletePlant(plant)
                dismiss()
            }
        }
    }

    // MARK: Sections

    private var headerSection: some View {
        Section {
            HStack(spacing: 14) {
                PlantIconView(plant: plant, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Nom", text: Binding(
                        get: { plant.name ?? "" },
                        set: { plant.name = $0 }
                    ), prompt: Text("Nom de la plante"))
                    .font(.title3.weight(.semibold))
                    .onSubmit { store.save() }

                    if let species = plant.species {
                        Text("\(species.commonName ?? "") · \(species.scientificName ?? "")")
                            .font(.caption)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        Label(plant.category.label, systemImage: plant.category.systemImage)
                        if let zone = plant.zone?.name { Label(zone, systemImage: "map") }
                        if let age = plant.ageDescription { Label(age, systemImage: "calendar") }
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.olive)
                }
            }

            let stage = GrowthAnalyzer.estimateStage(
                ageDays: plant.plantedDate.map { Int(Date().timeIntervalSince($0) / 86400) },
                lifespanYears: plant.species?.lifespanYears ?? 1
            )
            LabeledContent("Stade estimé", value: stage.label)

            DatePicker("Plantée le", selection: Binding(
                get: { plant.plantedDate ?? Date() },
                set: { plant.plantedDate = $0; store.save() }
            ), displayedComponents: .date)
        }
    }

    private var careSection: some View {
        Section("Entretien") {
            Picker("Besoin en eau", selection: Binding(
                get: { plant.effectiveWaterNeed },
                set: { newValue in
                    plant.customWaterNeedRaw = newValue == plant.species?.waterNeed ? nil : newValue.rawValue
                    store.save()
                    Task { await store.refreshNotificationSchedules() }
                }
            )) {
                ForEach(WaterNeed.allCases) { need in
                    Text(need.label + (need == plant.species?.waterNeed ? " (fiche)" : "")).tag(need)
                }
            }

            Stepper(value: Binding(
                get: { Int(plant.wateringIntervalOverride) },
                set: { plant.wateringIntervalOverride = Int16($0); store.save() }
            ), in: 0...30) {
                LabeledContent("Intervalle d'arrosage",
                               value: plant.wateringIntervalOverride == 0
                                   ? "Auto (\(plant.wateringIntervalDays) j)"
                                   : "\(plant.wateringIntervalOverride) j")
            }

            Picker("Lumière", selection: Binding(
                get: { plant.effectiveSunNeed },
                set: { newValue in
                    plant.customSunNeedRaw = newValue == plant.species?.sunNeed ? nil : newValue.rawValue
                    store.save()
                }
            )) {
                ForEach(SunNeed.allCases) { need in
                    Text(need.label).tag(need)
                }
            }

            TextField("Sol (personnalisé)", text: Binding(
                get: { plant.customSoil ?? plant.species?.soil ?? "" },
                set: { plant.customSoil = $0 == plant.species?.soil ? nil : $0 }
            ))
            .onSubmit { store.save() }

            VStack(alignment: .leading, spacing: 4) {
                LabeledContent("Emprise au sol (carte)") {
                    Text(Formatters.meters(plant.effectiveSpreadM)
                         + (plant.customSpreadM > 0 ? "" : " (auto)"))
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { plant.customSpreadM > 0 ? plant.customSpreadM : plant.effectiveSpreadM },
                    set: { plant.customSpreadM = $0 }
                ), in: 0.05...8) { _ in
                    store.save()
                }
                if plant.customSpreadM > 0 {
                    Button("Revenir à la taille de la fiche") {
                        plant.customSpreadM = 0
                        store.save()
                    }
                    .font(.caption)
                }
            }

            Toggle("Notifications pour cette plante", isOn: Binding(
                get: { plant.notificationsEnabled },
                set: { plant.notificationsEnabled = $0
                       store.save()
                       Task { await store.refreshNotificationSchedules() } }
            ))
        }
    }

    private var growthSection: some View {
        Group {
            let scored = plant.observationList.filter(\.hasHealthScore).reversed()
            if scored.count >= 2 {
                Section("Évolution de la santé") {
                    Chart(Array(scored), id: \.objectID) { observation in
                        LineMark(x: .value("Date", observation.date ?? Date()),
                                 y: .value("Santé", observation.healthScore * 100))
                            .foregroundStyle(Theme.leaf)
                        PointMark(x: .value("Date", observation.date ?? Date()),
                                  y: .value("Santé", observation.healthScore * 100))
                            .foregroundStyle(Theme.healthColor(observation.healthScore))
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 140)

                    if let growth = growthMessage {
                        Label(growth, systemImage: "arrow.up.right.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// Compare les deux dernières photos exploitables (surface de premier plan).
    private var growthMessage: String? {
        let measured = plant.observationList.filter { $0.foregroundAreaRatio > 0 }
        guard measured.count >= 2 else { return nil }
        let current = measured[0], previous = measured[1]
        var days: Int?
        if let d1 = previous.date, let d2 = current.date {
            days = Calendar.current.dateComponents([.day], from: d1, to: d2).day
        }
        return GrowthAnalyzer.compare(previousRatio: previous.foregroundAreaRatio,
                                      currentRatio: current.foregroundAreaRatio,
                                      daysBetween: days).message
    }

    private var observationsSection: some View {
        Section {
            ForEach(plant.observationList) { observation in
                ObservationRowView(observation: observation)
            }
            .onDelete { indexSet in
                let list = plant.observationList
                for index in indexSet { store.context.delete(list[index]) }
                store.save()
            }
        } header: {
            HStack {
                Text("Observations (\(plant.observationList.count))")
                Spacer()
                Button {
                    showObservationEditor = true
                } label: {
                    Label("Ajouter", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                }
            }
        }
    }

    private var harvestsSection: some View {
        Section {
            let year = Calendar.current.component(.year, from: Date())
            LabeledContent("Total \(String(year))", value: Formatters.kg(plant.totalYieldKg(year: year)))
            if let average = plant.species?.averageYieldKg, average > 0 {
                LabeledContent("Moyenne de l'espèce", value: "\(Formatters.kg(average))/an")
                    .font(.caption)
            }
            ForEach(plant.harvestList) { harvest in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(harvest.date ?? Date(), style: .date)
                        if let method = harvest.conservationMethod {
                            Text(method).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if harvest.quality > 0 {
                        HStack(spacing: 1) {
                            ForEach(0..<Int(harvest.quality), id: \.self) { _ in
                                Image(systemName: "star.fill").imageScale(.small)
                            }
                        }
                        .foregroundStyle(Theme.carrotOrange)
                    }
                    Text(Formatters.kg(harvest.quantityKg))
                        .font(.callout.weight(.medium))
                }
            }
            .onDelete { indexSet in
                let list = plant.harvestList
                for index in indexSet { store.context.delete(list[index]) }
                store.save()
            }
        } header: {
            HStack {
                Text("Récoltes (\(plant.harvestList.count))")
                Spacer()
                Button {
                    showHarvestEditor = true
                } label: {
                    Label("Ajouter", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                }
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Toggle("Archiver (masquer de la carte)", isOn: Binding(
                get: { plant.archived },
                set: { plant.archived = $0; store.save() }
            ))
            Button("Supprimer la plante…", role: .destructive) {
                confirmDelete = true
            }
        }
    }
}

struct ObservationRowView: View {
    @ObservedObject var observation: ObservationMO

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StoredPhotoView(data: observation.thumbnailData)
                .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(observation.date ?? Date(), style: .date)
                        .font(.caption.weight(.medium))
                    Spacer()
                    if observation.hasHealthScore {
                        HealthBadge(score: observation.healthScore)
                    }
                }
                if !observation.tags.isEmpty {
                    TagChipsView(tags: observation.tags)
                }
                if let note = observation.note, !note.isEmpty {
                    Text(note).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                }
                ForEach(observation.detectedIssues, id: \.self) { issue in
                    Label(issue, systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundStyle(Theme.carrotOrange)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
