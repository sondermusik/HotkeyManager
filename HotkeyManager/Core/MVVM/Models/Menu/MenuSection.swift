//
//  MenuSection.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 13.12.24.
//

import Foundation

class MenuSection: Identifiable, ObservableObject {
    // MARK: - Properties

    /// Unique String identifier for the menu item. Constructed using the process ID,
    /// the memory address of the `AXUIElement` and the element's index.
    let id: String

    /// The index of the menu item within its parent item, used for sorting.
    let index: Int

    /// The displayed name of the menu item.
    let name: String

    /// The  ``Application`` that the menu item belongs to.
    let app: Application

    var items: [MenuItem] = []

    /// The parent menu item of the current menu item.
    let parent: MenuSection?

    var children: [MenuSection] = []

    // MARK: - Initializers

    /// Designated initializer for MenuItem.
    init(
        id: String,
        name: String,
        index: Int,
        app: Application,
        items: [MenuItem] = [],
        parent: MenuSection? = nil,
        children: [MenuSection] = []
    ) {
        self.id = id
        self.name = name
        self.index = index
        self.app = app
        self.items = items
        self.parent = parent
        self.children = children
    }

    /// Adds child menu items to the current menu item.
    func addChildren(_ children: [MenuSection]) {
        self.children.append(contentsOf: children)
    }

    func addItems(_ items: [MenuItem]) {
        Task { await MainActor.run { self.items.append(contentsOf: items) } }
    }

    /// Recursively checks if the current `MenuItem` or any of its descendants have a `type` equal to `.hotkey`.
    func containsHotkey() -> Bool {
        if self.items.contains(where: { $0.hotkey != nil && $0.hidden != true }) {
            return true
        }
        for child in children {
            if child.containsHotkey() {
                return true
            }
        }
        return false
    }
}

// MARK: - Element Initializer

extension MenuSection {
    /// Convenience initializer to create a MenuItem from a ``MenuBarElement``.
    convenience init?(
        from element: MenuBarElement,
        items: [MenuItem] = [],
        parent: MenuSection? = nil,
        children: [MenuSection] = []
    ) {
        guard let name = element.title else { return nil }

        // Call the designated initializer
        self.init(
            id: element.id,
            name: name,
            index: element.index,
            app: element.app,
            items: items,
            parent: parent,
            children: children
        )
    }
}

extension MenuSection {
    /// Returns a flattened array of all child `MenuSection` objects, including their descendants.
    func flattenedSections() -> [MenuSection] {
        // Start with the current section
        var allSections = self.children

        // Recursively add children and their descendants
        for child in children {
            allSections.append(contentsOf: child.flattenedSections())
        }
        return allSections
    }

    func flattenedItems() -> [MenuItem] {
        var allItems = self.items
        for child in children {
            allItems.append(contentsOf: child.flattenedItems())
        }
        return allItems
    }
}

// MARK: - Mixed Array

extension MenuSection {
    /// Returns a mixed array of `MenuResult` containing both sections and items sorted by index.
    func toMenuSection() -> [MenuResult] {
        // Create an array of mixed MenuResult elements
        var result: [MenuResult] = []

        // Add all child sections as MenuResults
        result.append(contentsOf: children.map { MenuResult.section($0) })

        // Add all items as MenuResults
        result.append(contentsOf: items.map { MenuResult.item($0) })

        // Sort the result array by index of sections and items
        result.sort {
            switch ($0, $1) {
            case (.section(let section1), .section(let section2)):
                return section1.index < section2.index
            case (.item(let item1), .item(let item2)):
                return item1.index < item2.index
            case (.section(let section1), .item(let item2)):
                return section1.index < item2.index
            case (.item(let item1), .section(let section2)):
                return item1.index < section2.index
            }
        }
        return result
    }
}
