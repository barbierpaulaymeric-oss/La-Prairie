import CoreData
import JardinCore
import SwiftUI

/// Analyses et suggestions générées par `InsightEngine` (baisse de rendement,
/// disparités entre zones, tags récurrents, santé en déclin…).
public struct InsightsView: View {
    @EnvironmentObject private var appEnv: AppEnvironment
    @EnvironmentObject private var store: GardenStore

    @FetchRequest(entity: InsightMO.entity(),
                  sortDescriptors: [
                      NSSortDescriptor(key: "acknowledged", ascending: true),
                      NSSortDescriptor(key: "severityRaw", ascending: false),
                      NSSortDescriptor(key: "date", ascending: false),
                  ])
    private var insights: FetchedResults<InsightMO>

    @State private var refreshing = false

    public init() {}

    public var body: some View {
        List {
            if let weather = appEnv.lastWeather {
                Section("Météo du jardin") {
                    HStack {
                        Image(systemName: weather.conditionSymbol)
                            .font(.title2)
                            .foregroundStyle(Theme.secondaryTint)
                        VStack(alignment: .leading) {
                            Text("\(Int(weather.temperatureCelsius)) °C · \(weather.conditionDescription)")
                            Text("Pluie : aujourd'hui \(Int(weather.rainProbabilityToday * 100)) %, demain \(Int(weather.rainProbabilityTomorrow * 100)) %")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if weather.rainProbabilityTomorrow >= WateringPlanner.rainPostponeThreshold {
                        Label("Pluie prévue demain : les rappels d'arrosage imminents sont décalés d'un jour.",
                              systemImage: "cloud.rain")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryTint)
                    }
                }
            }

            Section {
                if insights.isEmpty {
                    EmptyStateView(systemImage: "chart.line.uptrend.xyaxis",
                                   title: "Pas encore d'analyse",
                                   message: "Ajoutez des observations et des récoltes : l'app croisera les données pour vous suggérer des pistes.")
                }
                ForEach(insights) { insight in
                    InsightRowView(insight: insight)
                        .swipeActions(edge: .trailing) {
                            Button(insight.acknowledged ? "Réactiver" : "Vu") {
                                insight.acknowledged.toggle()
                                store.save()
                            }
                            .tint(Theme.secondaryTint)
                            Button("Supprimer", role: .destructive) {
                                store.context.delete(insight)
                                store.save()
                            }
                        }
                }
            } header: {
                HStack {
                    Text("Suggestions")
                    Spacer()
                    Button {
                        refreshing = true
                        Task {
                            await store.refreshInsights()
                            refreshing = false
                        }
                    } label: {
                        if refreshing {
                            ProgressView().controlSize(.mini)
                        } else {
                            Label("Recalculer", systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                    }
                }
            } footer: {
                Text("Les analyses croisent récoltes, emplacements, tags d'observation et scores de santé des photos.")
            }
        }
        .navigationTitle("Analyse")
        .refreshable { await store.refreshInsights() }
    }
}

struct InsightRowView: View {
    @ObservedObject var insight: InsightMO
    @EnvironmentObject private var store: GardenStore

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.severityColor(Int(insight.severityRaw)))
                .frame(width: 28, height: 28)
                .background(Theme.severityBg(Int(insight.severityRaw)), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.message ?? "")
                    .font(.callout)
                HStack {
                    Text(insight.severity.label)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.severityColor(Int(insight.severityRaw)).opacity(0.15), in: Capsule())
                        .foregroundStyle(Theme.severityColor(Int(insight.severityRaw)))
                    if let date = insight.date {
                        Text(date, style: .date).font(.caption2).foregroundStyle(.secondary)
                    }
                    if let plantID = insight.plantID, let plant = store.plant(withID: plantID) {
                        Text("· \(plant.displayName)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .opacity(insight.acknowledged ? 0.45 : 1)
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch insight.kind {
        case .baisseRendement: return "chart.line.downtrend.xyaxis"
        case .comparaisonZone: return "map"
        case .tendanceObservations: return "tag"
        case .santeEnDeclin: return "heart.text.square"
        case .meteo: return "cloud.sun"
        case .info: return "info.circle"
        }
    }
}
