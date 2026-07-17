import JardinCore
import SwiftUI

/// Navigation adaptée à la plateforme :
/// - iPhone : barre d'onglets (Carte, Plantes, Récoltes, Analyse, Réglages) ;
/// - iPad et macOS : barre latérale + vue principale.
public struct RootView: View {
    public enum Section: String, CaseIterable, Identifiable {
        case carte, plantes, recoltes, analyse, reglages

        public var id: String { rawValue }

        var label: String {
            switch self {
            case .carte: return "Carte"
            case .plantes: return "Plantes"
            case .recoltes: return "Récoltes"
            case .analyse: return "Analyse"
            case .reglages: return "Réglages"
            }
        }

        var systemImage: String {
            switch self {
            case .carte: return "map"
            case .plantes: return "leaf"
            case .recoltes: return "basket"
            case .analyse: return "chart.line.uptrend.xyaxis"
            case .reglages: return "gearshape"
            }
        }
    }

    @EnvironmentObject private var appEnv: AppEnvironment
    @State private var selection: Section = .carte
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    public init() {}

    public var body: some View {
        Group {
            #if os(macOS)
            splitLayout
            #else
            if horizontalSizeClass == .regular {
                splitLayout
            } else {
                tabLayout
            }
            #endif
        }
        .environment(\.managedObjectContext, appEnv.store.context)
        .environmentObject(appEnv.store)
        // Bascule démo/réel : reconstruit la hiérarchie pour rebrancher les @FetchRequest.
        .id(appEnv.demoMode)
        .tint(Theme.leaf)
        .task {
            await appEnv.performDailyRefresh()
        }
    }

    private var tabLayout: some View {
        TabView(selection: $selection) {
            ForEach(Section.allCases) { section in
                NavigationStack {
                    destination(for: section)
                }
                .tabItem { Label(section.label, systemImage: section.systemImage) }
                .tag(section)
            }
        }
    }

    private var splitLayout: some View {
        NavigationSplitView {
            List(Section.allCases, selection: Binding(
                get: { Optional(selection) },
                set: { selection = $0 ?? .carte }
            )) { section in
                Label(section.label, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Jardin")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #endif
        } detail: {
            NavigationStack {
                destination(for: selection)
            }
        }
    }

    @ViewBuilder
    private func destination(for section: Section) -> some View {
        switch section {
        case .carte: GardenMapView()
        case .plantes: PlantListView()
        case .recoltes: HarvestDashboardView()
        case .analyse: InsightsView()
        case .reglages: SettingsView()
        }
    }
}
