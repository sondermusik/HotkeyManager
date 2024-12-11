//
//  DataController.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import CoreData
import Combine

// MARK: - DataController

final class DataController: ObservableObject {
    private let container: NSPersistentContainer
    private(set) var viewContext: NSManagedObjectContext

    private var cancellables: Set<AnyCancellable> = []

    // MARK: Initialization

    init(containerName: String = "HotkeyManager") {
        self.container = NSPersistentContainer(name: containerName)
        self.viewContext = container.viewContext

        // Configure concurrency settings and load persistent stores
        self.configureContexts()
    }

    private func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true

        // Ensure all contexts are properly loaded
        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                fatalError("[DataController] Core Data failed to load: \(error), \(error.userInfo)")
            }

            self?.setupNotifications()
        }
    }

    // MARK: - Creating Independent Background Context

    func createBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        return backgroundContext
    }

    // MARK: - Core Data Save Operation

    func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("[DataController] Failed to save context: \(error.localizedDescription)")
        }
    }

    // MARK: - Merging Changes

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(mergeChanges),
            name: .NSManagedObjectContextDidSave,
            object: viewContext
        )
    }

    @objc private func mergeChanges(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let context = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> else {
            return
        }

        // Merge changes into the main context on the main thread
        DispatchQueue.main.async {
            context.forEach { _ in self.viewContext.mergeChanges(fromContextDidSave: notification) }
        }
    }

    // MARK: - Persistence Helper Methods

    func persistentStoreURL() -> URL? {
        return container.persistentStoreCoordinator.persistentStores.first?.url
    }
}
