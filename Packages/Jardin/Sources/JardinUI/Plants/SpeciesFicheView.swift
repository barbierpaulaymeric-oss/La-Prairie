import JardinCore
import SwiftUI

/// Fiche espèce affichée dans le détail d'une plante. Les champs texte de la fiche
/// sont éditables : la modification vaut pour toutes les plantes de l'espèce et
/// marque la fiche « personnalisée » (les besoins eau/lumière/sol se personnalisent
/// par plante dans la section Entretien).
struct SpeciesFicheView: View {
    @ObservedObject var plant: PlantMO
    @EnvironmentObject private var store: GardenStore
    @State private var isEditing = false

    private var species: PlantSpeciesMO? { plant.species }

    var body: some View {
        if let species {
            Section {
                LabeledContent("Besoins (fiche)",
                               value: "\(species.waterNeed.label) · \(species.sunNeed.label)")
                LabeledContent("Sol conseillé", value: species.soil ?? "—")

                monthsRow(title: "Semis / plantation", months: species.sowingMonths)
                monthsRow(title: "Récolte", months: species.harvestMonths)

                LabeledContent("Durée de vie",
                               value: species.lifespanYears < 2
                                   ? "Annuelle"
                                   : "\(Int(species.lifespanYears)) ans")
                if species.averageYieldKg > 0 {
                    LabeledContent("Rendement moyen", value: "\(Formatters.kg(species.averageYieldKg))/an")
                }

                if isEditing {
                    fieldEditor(title: "Bouturage / multiplication", keyPath: \.propagation)
                    fieldEditor(title: "Conservation des récoltes", keyPath: \.conservation)
                    fieldEditor(title: "Notes de culture", keyPath: \.infoNotes)
                } else {
                    if let propagation = species.propagation, !propagation.isEmpty {
                        detailRow(title: "Bouturage / multiplication", text: propagation, icon: "scissors")
                    }
                    if let conservation = species.conservation, !conservation.isEmpty {
                        detailRow(title: "Conservation des récoltes", text: conservation, icon: "archivebox")
                    }
                    if let notes = species.infoNotes, !notes.isEmpty {
                        detailRow(title: "Conseils", text: notes, icon: "lightbulb")
                    }
                }

                if !species.companions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bonnes associations").font(.caption).foregroundStyle(.secondary)
                        TagChipsView(tags: species.companions)
                    }
                }
                if !species.antagonists.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("À éloigner de").font(.caption).foregroundStyle(.secondary)
                        TagChipsView(tags: species.antagonists)
                    }
                }
            } header: {
                HStack {
                    Text("Fiche « \(species.commonName ?? "") »")
                    if species.isUserModified {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(Theme.carrotOrange)
                            .help("Fiche personnalisée par vous")
                    }
                    Spacer()
                    Button(isEditing ? "Terminer" : "Modifier la fiche") {
                        if isEditing { store.markSpeciesModified(species) }
                        isEditing.toggle()
                    }
                    .font(.caption)
                }
            } footer: {
                Text("Modifier la fiche s'applique à toutes les plantes de cette espèce. Les besoins en eau, lumière et sol se personnalisent par plante dans « Entretien ».")
            }
        }
    }

    private func monthsRow(title: String, months: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 3) {
                ForEach(1...12, id: \.self) { month in
                    Text(Months.label(for: month).prefix(1))
                        .font(.system(size: 9, weight: .semibold))
                        .frame(width: 18, height: 18)
                        .background(months.contains(month) ? Theme.leaf : Theme.leaf.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(months.contains(month) ? .white : Theme.olive.opacity(0.6))
                        .accessibilityLabel(months.contains(month) ? "\(Months.label(for: month)) : oui" : "")
                }
            }
        }
    }

    private func detailRow(title: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.olive)
            Text(text).font(.caption)
        }
        .padding(.vertical, 2)
    }

    private func fieldEditor(title: String, keyPath: ReferenceWritableKeyPath<PlantSpeciesMO, String?>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption.weight(.medium)).foregroundStyle(Theme.olive)
            TextField(title, text: Binding(
                get: { species?[keyPath: keyPath] ?? "" },
                set: { species?[keyPath: keyPath] = $0 }
            ), axis: .vertical)
            .lineLimit(2...5)
            .textFieldStyle(.roundedBorder)
        }
    }
}
