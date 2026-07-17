import JardinCore
import SwiftUI

struct HarvestEditorView: View {
    @ObservedObject var plant: PlantMO
    @EnvironmentObject private var store: GardenStore
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var quantityKg = 0.5
    @State private var quality = 4
    @State private var conservationMethod = "Frais"
    @State private var notes = ""
    @State private var captured: PhotoCaptureButton.Captured?

    var body: some View {
        NavigationStack {
            Form {
                Section("Récolte de \(plant.displayName)") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Quantité")
                        Spacer()
                        TextField("kg", value: $quantityKg, format: .number.precision(.fractionLength(0...2)))
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .frame(width: 80)
                        Text("kg").foregroundStyle(.secondary)
                    }
                    Picker("Qualité", selection: $quality) {
                        ForEach(1...5, id: \.self) { stars in
                            Text(String(repeating: "★", count: stars)).tag(stars)
                        }
                    }
                    Picker("Conservation", selection: $conservationMethod) {
                        ForEach(ConservationMethods.presets, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                }
                Section("Photo (optionnelle)") {
                    if let captured {
                        StoredPhotoView(data: captured.stored.thumbnail)
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                    }
                    PhotoCaptureButton { captured = $0 }
                }
                Section("Notes") {
                    TextField("Ex : rendement faible, sol trop sec ?", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Nouvelle récolte")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        store.addHarvest(to: plant,
                                         date: date,
                                         quantityKg: max(quantityKg, 0),
                                         quality: quality,
                                         conservationMethod: conservationMethod,
                                         notes: notes.isEmpty ? nil : notes,
                                         photo: captured?.stored)
                        Task { await store.refreshInsights() }
                        dismiss()
                    }
                    .disabled(quantityKg <= 0)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 520)
        #endif
    }
}
