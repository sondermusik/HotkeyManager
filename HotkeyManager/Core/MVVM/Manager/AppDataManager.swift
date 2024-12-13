//
//  AppDataManager.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 13.12.24.
//

import CoreData
import Foundation

class AppDataManager {
    let dataController = DataController.shared

    // New batchFetchOrCreate method
    func batchFetchOrCreateApps(_ apps: [Application]) -> [Application] {
        let context = dataController.backgroundContext

        // Prepare a list of IDs to check which apps already exist in Core Data
        let appIds = apps.map { $0.id }

        // Create the fetch request to retrieve the existing apps from Core Data
        let fetchRequest: NSFetchRequest<AppEntity> = AppEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", appIds)

        do {
            // Fetch the existing apps from Core Data
            let existingApps = try context.fetch(fetchRequest)

            // Create a dictionary to quickly check if an app with a specific ID exists
            let existingAppDict = Dictionary(uniqueKeysWithValues: existingApps.map { ($0.id, $0) })

            // Iterate through the provided apps and either fetch or create them
            for app in apps {
                if let existingApp = existingAppDict[app.id] {
                    app.global = existingApp.global
                    app.display = existingApp.display
                } else {
                    let newApp = AppEntity(context: context)
                    newApp.id = app.id
                    newApp.name = app.name
                    newApp.global = app.global
                    newApp.display = app.display
                }
            }

            // Save context after batch processing
            dataController.saveContext(context)

            return apps
        } catch {
            print("Error batch fetching or creating apps: \(error)")
        }

        return apps
    }

   @discardableResult
    func fetchOrCreateApp(_ app: Application) -> AppEntity? {
        let context = dataController.backgroundContext

        let fetchRequest: NSFetchRequest<AppEntity> = AppEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", app.id)

        do {
            if let existingApp = try context.fetch(fetchRequest).first {
                app.global = existingApp.global
                app.display = existingApp.display
                return existingApp
            } else {
                let newApp = AppEntity(context: context)
                newApp.id = app.id
                newApp.name = app.name
                newApp.global = app.global
                newApp.display = app.display

                dataController.saveContext(context)
                return newApp
            }
        } catch {
            print("Error fetching or creating app: \(error)")
        }

        return nil
    }

    func updateApp(_ app: Application) {
        let context = dataController.backgroundContext

        let fetchRequest: NSFetchRequest<AppEntity> = AppEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", app.id)

        do {
            if let existingApp = try context.fetch(fetchRequest).first {
                existingApp.global = app.global
                existingApp.display = app.display
                dataController.saveContext(context)
            }
        } catch {
            print("Error updating app: \(error)")
        }
    }
}
