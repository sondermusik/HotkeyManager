//
//  MenuItemType.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import Foundation

/// Represents the types of menu items in a menu bar.
enum MenuItemType: Int {
    case section = 0

    /// A selectable menu item.
    case item = 1

    /// A menu item with an associated hotkey.
    case hotkey = 2

    /// A visual separator between menu items.
    case separator = 3

    var description: String {
        switch self {
        case .item:
            return "Item"
        case .hotkey:
            return "Hotkey"
        case .separator:
            return "Separator"
        case .section:
            return "Section"
        }
    }
}
