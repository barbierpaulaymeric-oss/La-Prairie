import CoreData
import Foundation

/// Pile Core Data + CloudKit.
///
/// Stratégie de conflits : suivi d'historique persistant activé, fusion automatique
/// des changements distants dans le contexte principal, et politique
/// `NSMergeByPropertyObjectTrumpMergePolicy` (la dernière écriture gagne, propriété
/// par propriété) — le compromis standard d'Apple pour la synchronisation multi-appareils.
public final class PersistenceController: ObservableObject {
    public static let shared = PersistenceController()

    /// Pile en mémoire remplie de données de démonstration (previews et mode démo).
    public static let demo: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        SeedService.seedSpeciesIfNeeded(in: context)
        DemoDataService.seedDemoGarden(in: context)
        return controller
    }()

    public let container: NSPersistentCloudKitContainer
    public private(set) var cloudSyncActive: Bool = false
    public private(set) var loadError: Error?

    public static var cloudContainerIdentifier: String {
        (Bundle.main.object(forInfoDictionaryKey: "JIICloudContainerIdentifier") as? String)
            ?? "iCloud.com.laprairie.jardinintelligent"
    }

    public init(inMemory: Bool = false, cloudKitEnabled: Bool = true) {
        container = NSPersistentCloudKitContainer(name: "Jardin", managedObjectModel: JardinModel.shared)

        let description = NSPersistentStoreDescription()
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("Jardin.sqlite")
            description.url = storeURL
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            if cloudKitEnabled {
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: Self.cloudContainerIdentifier
                )
            }
        }
        container.persistentStoreDescriptions = [description]

        loadStores(fallbackToLocal: cloudKitEnabled && !inMemory)

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.name = "viewContext"
    }

    /// Charge les stores ; si CloudKit échoue (compte iCloud absent, entitlement manquant…),
    /// recharge en local uniquement plutôt que de faire planter l'app.
    private func loadStores(fallbackToLocal: Bool) {
        var firstError: Error?
        container.loadPersistentStores { _, error in firstError = error }

        if let error = firstError, fallbackToLocal {
            container.persistentStoreDescriptions.forEach { $0.cloudKitContainerOptions = nil }
            var secondError: Error?
            container.loadPersistentStores { _, error in secondError = error }
            loadError = secondError
            cloudSyncActive = false
            if secondError != nil {
                assertionFailure("Échec de chargement du store Core Data : \(error)")
            }
        } else {
            loadError = firstError
            cloudSyncActive = firstError == nil
                && container.persistentStoreDescriptions.contains { $0.cloudKitContainerOptions != nil }
        }
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Exécute un bloc sur un contexte d'arrière-plan et sauvegarde, en async/await.
    public func performBackground<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = newBackgroundContext()
        return try await context.perform {
            let result = try block(context)
            if context.hasChanges { try context.save() }
            return result
        }
    }
}
