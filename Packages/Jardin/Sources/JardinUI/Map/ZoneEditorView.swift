import CoreGraphics
import JardinCore
import SwiftUI

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
                        .fill(Color(hex: kind.defaultColorHex).opacity(0.3))
                        .overlay(ZoneShape(points: points).stroke(Color(hex: kind.defaultColorHex), lineWidth: 2))
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
