//
//  MenuItem.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import Foundation

/// Represents a menu item within a menu section.
class MenuItem: Identifiable, ObservableObject {
    // MARK: - Properties

    /// Unique String identifier for the menu item. Constructed using the process ID,
    /// the memory address of the `AXUIElement` and the element's index.
    let id: String

    /// The index of the menu item within its parent item, used for sorting.
    let index: Int

    /// The displayed name of the menu item.
    let name: String

    /// The parent menu item of the current menu item.
    let parent: MenuSection

    /// The  ``Application`` that the menu item belongs to.
    let app: Application

    /// The hotkey associated with the menu item, if applicable.
    var hotkey: Hotkey?

    // MARK: - User Settings

    /// Indicates if the menu item sh
    var hidden: Bool

    // MARK: - Initializers

    /// Designated initializer for MenuItem.
    init(
        id: String,
        index: Int,
        name: String,
        app: Application,
        parent: MenuSection,
        hotkey: Hotkey?,
        hidden: Bool
    ) {
        // Required
        self.id = id
        self.index = index
        self.name = name
        // Relationships
        self.app = app
        self.parent = parent
        // Optional
        self.hotkey = hotkey

        self.hidden = hidden
    }
}

// MARK: - Element

extension MenuItem {
    /// Convenience initializer to create a MenuItem from a ``MenuBarElement``.
    convenience init?(from element: MenuBarElement, parent: MenuSection) {
        guard let title = element.title else { return nil }

        var name = title

        if element.role == .separator {
            name = "Separator"
        }

        self.init(
            id: element.id,
            index: element.index,
            name: name,
            app: element.app,
            parent: parent,
            hotkey: Hotkey(from: element),
            hidden: false
        )
    }
}
