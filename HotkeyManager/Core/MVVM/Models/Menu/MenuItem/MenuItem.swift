//
//  MenuItem.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import Foundation

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
        hidden: Bool,
        app: Application,
        parent: MenuSection,
        hotkey: Hotkey?
    ) {
        // Required
        self.id = id
        self.index = index
        self.name = name
        self.hidden = hidden
        // Relationships
        self.app = app
        self.parent = parent
        // Optional
        self.hotkey = hotkey
    }

    /// Convenience initializer to create a MenuItem from a ``MenuBarElement``.
    init?(from element: MenuBarElement, parent: MenuSection) {
        guard let name = element.title else { return nil }

        self.id = element.id
        self.name = name
        self.index = element.index
        self.app = element.app
        self.parent = parent
        self.hidden = false

        if element.role == .hotkey {
            self.hotkey = Hotkey(from: element)
        }
    }
}
