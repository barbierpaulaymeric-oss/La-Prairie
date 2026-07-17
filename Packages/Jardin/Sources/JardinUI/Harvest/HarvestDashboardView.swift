import Charts
import CoreData
import JardinCore
import SwiftUI

/// Tableau de bord des récoltes : rendement par mois/plante/zone, comparaison à
/// la moyenne des espèces, export CSV/JSON. Les données viennent de snapshots
/// recalculés à l'affichage (volumes faibles, calcul pur → simple et fiable).
public struct HarvestDashboardView: View {
    @EnvironmentObject private var store: GardenStore

    @FetchRequest(entity: HarvestMO.entity(),
                  sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)])
    private var harvestMOs: FetchedResults<HarvestMO>

    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    public init() {}

    private var harvests: [HarvestSnapshot] {
        harvestMOs.compactMap(HarvestSnapshot.init)
    }

    private var availableYears: [Int] {
        let years = Set(harvests.map { Calendar.current.component(.year, from: $0.date) })
        return years.sorted(by: >)
    }

    public var body: some View {
        List {
            if harvests.isEmpty {
                EmptyStateView(systemImage: "basket",
                               title: "Aucune récolte",
                               message: "Enregistrez vos récoltes depuis la fiche d'une plante pour suivre vos rendements.")
            } else {
                yearPicker
                monthlyChartSection
                byPlantSection
                byZoneSection
                recentSection
            }
        }
        .navigationTitle("Récoltes")
    }

    private var yearPicker: some View {
        Section {
            Picker("Année", selection: $selectedYear) {
                ForEach(availableYears, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.segmented)

            let total = harvests
                .filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
                .reduce(0) { $0 + $1.quantityKg }
            LabeledContent("Total \(String(selectedYear))") {
                Text(Formatters.kg(total))
                    .font(Theme.dataXL)
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var monthlyChartSection: some View {
        Section("Rendement mensuel") {
            let points = HarvestAnalytics.monthlyYield(harvests, year: selectedYear)
            if points.isEmpty {
                Text("Aucune récolte cette année-là.").foregroundStyle(.secondary)
            } else {
                Chart(points) { point in
                    BarMark(
                        x: .value("Mois", point.monthDate, unit: .month),
                        y: .value("kg", point.totalKg)
                    )
                    .foregroundStyle(by: .value("Plante", point.label))
                }
                .chartForegroundStyleScale(range: Theme.dataSeries)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
                .frame(height: 220)
                .padding(.vertical, 4)
            }
        }
    }

    private var byPlantSection: some View {
        Section("Par plante") {
            let totals = HarvestAnalytics.totalByPlant(harvests, year: selectedYear)
            Chart(totals.prefix(8)) { total in
                BarMark(
                    x: .value("kg", total.totalKg),
                    y: .value("Plante", total.label)
                )
                .foregroundStyle(Theme.dataSeries[0])
                .annotation(position: .trailing) {
                    Text(Formatters.kg(total.totalKg)).font(Theme.dataS).foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(height: CGFloat(min(totals.count, 8)) * 34 + 20)
        }
    }

    private var byZoneSection: some View {
        Section("Par zone") {
            let totals = HarvestAnalytics.totalByZone(harvests, year: selectedYear)
            if totals.count <= 1 {
                Text("Placez vos plantes dans des zones de la carte pour comparer les emplacements.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(totals) { total in
                    SectorMark(angle: .value("kg", total.totalKg),
                               innerRadius: .ratio(0.55),
                               angularInset: 1.5)
                        .foregroundStyle(by: .value("Zone", total.label))
                }
                .frame(height: 200)

                ForEach(HarvestAnalytics.zoneDisparities(harvests), id: \.self) { disparity in
                    Label("\(disparity.speciesName) : \(Int(disparity.relativeGap * 100)) % de moins en « \(disparity.worstZone) » qu'en « \(disparity.bestZone) »",
                          systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(Theme.warning)
                }
            }
        }
    }

    private var recentSection: some View {
        Section("Dernières récoltes") {
            ForEach(harvestMOs.prefix(12)) { harvest in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(harvest.plant?.displayName ?? "—").font(.callout.weight(.medium))
                        Text(harvest.date ?? Date(), style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let method = harvest.conservationMethod {
                        Text(method).font(.caption2).foregroundStyle(Theme.secondaryTint)
                    }
                    Text(Formatters.kg(harvest.quantityKg)).font(Theme.dataFont)
                }
            }
        }
    }
}
