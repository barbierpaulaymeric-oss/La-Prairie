import JardinCore
import JardinUI
import SwiftUI
import UserNotifications

@main
struct JardinIntelligentApp: App {
    @StateObject private var appEnv = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    private static let notificationDelegate = NotificationCenterDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = Self.notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appEnv)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await appEnv.performDailyRefresh() }
                    }
                }
        }
        #if os(macOS)
        .defaultSize(width: 1150, height: 760)
        #endif
    }
}

/// Affiche les notifications même quand l'app est au premier plan.
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
