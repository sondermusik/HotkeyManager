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

    var type: MenuItemType

    /// Indicates if the menu item sh
    var display: Bool?

    /// The parent menu item of the current menu item.
    let parent: MenuItem?

    /// The  ``Application`` that the menu item belongs to.
    let app: Application

    /// The hotkey associated with the menu item, if applicable.
    var hotkey: Hotkey?

    var children: [MenuItem] = []


    // MARK: - Initializers

    /// Designated initializer for MenuItem.
    init(
        id: String,
        name: String,
        index: Int,
        hotkey: Hotkey?,
        type: MenuItemType,
        app: Application,
        parent: MenuItem?,
        display: Bool
    ) {
        self.id = id
        self.name = name
        self.index = index
        self.hotkey = hotkey
        self.type = type
        self.app = app
        self.display = display
        self.parent = parent
    }

    /// Convenience initializer to create a MenuItem from a ``MenuBarElement``.
    init?(from element: MenuBarElement, parent: MenuItem? = nil, children: [MenuItem] = []) {
        guard let name = element.title else { return nil }

        self.id = element.id
        self.name = name
        self.index = element.index
        self.app = element.app
        self.parent = parent

        if element.role == .hotkey {
            self.hotkey = Hotkey(from: element)
            self.type = .hotkey

        } else {
            self.type = element.role.menuItemRole
        }
    }

    /// Adds child menu items to the current menu item.
    func addChildren(_ children: [MenuItem]) {
        self.children.append(contentsOf: children)
    }

    /// Recursively checks if the current `MenuItem` or any of its descendants have a `type` equal to `.hotkey`.
    func containsHotkey() -> Bool {
        if self.type == .hotkey {
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
