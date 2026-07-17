import CoreGraphics
import JardinCore
import SwiftUI

/// Infos et réglages d'un secteur existant (mode Secteurs de la carte).
struct ZoneInfoSheet: View {
    @ObservedObject var zone: GardenZoneMO
    let onDelete: () -> Void

    @EnvironmentObject private var store: GardenStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Secteur") {
                    TextField("Nom", text: Binding(
                        get: { zone.name ?? "" },
                        set: { zone.name = $0 }
                    ))
                    Picker("Type", selection: Binding(
                        get: { zone.kind },
                        set: { zone.kind = $0; zone.colorHex = $0.defaultColorHex }
                    )) {
                        ForEach(ZoneKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    Picker("Exposition", selection: Binding(
                        get: { zone.sunExposure ?? .soleil },
                        set: { zone.sunExposure = $0 }
                    )) {
                        ForEach(SunNeed.allCases) { need in
                            Text(need.label).tag(need)
                        }
                    }
                    TextField("Type de sol", text: Binding(
                        get: { zone.soilType ?? "" },
                        set: { zone.soilType = $0.isEmpty ? nil : $0 }
                    ))
                }
                Section {
                    LabeledContent("Plantes dans ce secteur", value: "\(zone.plantList.count)")
                } footer: {
                    Text("Forme et taille se modifient directement sur la carte : déplacez les poignées blanches, touchez « + » sur une arête pour ajouter un sommet, appui long sur un sommet pour le supprimer, glissez l'intérieur pour déplacer tout le secteur.")
                }
                Section {
                    Button("Supprimer ce secteur…", role: .destructive) {
                        confirmDelete = true
                    }
                }
            }
            .navigationTitle(zone.name ?? "Secteur")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        store.save()
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Supprimer ce secteur ? Les plantes qu'il contient sont conservées.",
                                isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    store.deleteZone(zone)
                    onDelete()
                    dismiss()
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
    }
}

struct ZoneEditorView: View {
    let points: [CGPoint]
    let onDone: () -> Void

    @EnvironmentObject private var store: GardenStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var kind: ZoneKind = .potager
    @State private var soilType = ""
    @State private var sunExposure: SunNeed = .soleil

    var body: some View {
        NavigationStack {
            Form {
                Section("Nouvelle zone") {
                    TextField("Nom (ex : Potager sud)", text: $name)
                    Picker("Type", selection: $kind) {
                        ForEach(ZoneKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    Picker("Exposition", selection: $sunExposure) {
                        ForEach(SunNeed.allCases) { need in
                            Text(need.label).tag(need)
                        }
                    }
                    TextField("Type de sol (ex : argileux, riche)", text: $soilType)
                }
                Section {
                    ZoneShape(points: points)
                        .fill(Theme.zoneColor(kind).opacity(0.3))
                        .overlay(ZoneShape(points: points).stroke(Theme.zoneColor(kind), lineWidth: 2))
                        .frame(height: 140)
                        .accessibilityLabel("Aperçu de la zone, \(points.count) sommets")
                } header: {
                    Text("Aperçu (\(points.count) sommets)")
                }
            }
            .navigationTitle("Zone")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        store.createZone(name: name.isEmpty ? kind.label : name,
                                         kind: kind,
                                         points: points,
                                         soilType: soilType.isEmpty ? nil : soilType,
                                         sunExposure: sunExposure)
                        onDone()
                        dismiss()
                    }
                    .disabled(points.count < 3)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
    }
}
