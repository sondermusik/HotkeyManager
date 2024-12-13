//
//  MenuDataManager.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 13.12.24.
//

import CoreData
import Foundation

class MenuDataManager {
    let dataController = DataController.shared

    @discardableResult
    func upsertItem(_ item: MenuItem) -> MenuItemEntity? {
        guard let app = AppVM.shared.appDataManager.fetchOrCreateApp(item.app) else {
            print("[MenuDataManager] Error: Could not fetch or create associated app.")
            return nil
        }

        guard let parent = upsertSection(item.parent) else {
            print("[MenuDataManager] Error: Could not upsert parent section.")
            return nil
        }
        print("[MenuDataManager] Upserting item: \(item.name)")
        let context = dataController.backgroundContext
        let fetchRequest: NSFetchRequest<MenuItemEntity> = MenuItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", item.id)

        do {
            // Fetch or create the item

            let menuItem: MenuItemEntity
            if let fetchedItem = try context.fetch(fetchRequest).first {
                menuItem = fetchedItem
            } else {
                menuItem = MenuItemEntity(context: context)
                menuItem.id = item.id
            }

            // Update properties
            menuItem.index = Int16(item.index)
            menuItem.name = item.name
            menuItem.app = app
            menuItem.parent = parent


            if let hotkey = item.hotkey {
                menuItem.keyCode = Int16(hotkey.keyCode.rawValue)
                menuItem.modifier = hotkey.modifierToInt16()
            }
            menuItem.hidden = item.hidden

            // Save changes
            dataController.saveContext(context)
            return menuItem
        } catch {
            print("[MenuDataManager] Error fetching or creating item: \(error)")
        }

        return nil
    }


    @discardableResult
    func upsertSection(_ section: MenuSection) -> MenuSectionEntity? {
        let context = dataController.backgroundContext
        let fetchRequest: NSFetchRequest<MenuSectionEntity> = MenuSectionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", section.id)

        do {
            // Fetch or create the section
            let existingSection: MenuSectionEntity
            if let fetchedSection = try context.fetch(fetchRequest).first {
                existingSection = fetchedSection
            } else {
                existingSection = MenuSectionEntity(context: context)
                existingSection.id = section.id
                existingSection.app = AppVM.shared.appDataManager.fetchOrCreateApp(section.app)
            }

            // Update properties
            existingSection.index = Int16(section.index)
            existingSection.name = section.name

//            // Convert children to NSSet
//            let childEntities = section.children.compactMap { upsertSection($0) }
//            existingSection.children = NSSet(array: childEntities)

//            if let parent = section.parent, let upsertSection = upsertSection(parent) {
//                existingSection.parent = upsertSection
//            }

            // Save changes
            dataController.saveContext(context)
            return existingSection
        } catch {
            print("Error fetching or creating section: \(error)")
        }

        return nil
    }
}
