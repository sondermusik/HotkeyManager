//
//  ConstMenuBar.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import ApplicationServices
import Foundation

internal typealias AXAttribute = CFString

internal enum ConstMenuBar {

    // MARK: - Attribute Indices

    /// Indices of attributes in the `attributes` array.
    ///
    /// This nested enum maps logical attribute names to their indices in the `attributes` array. Using indices improves
    /// performance by avoiding repetitive string lookups when dealing with attributes in bulk. Each case corresponds to
    /// an accessibility attribute used when interacting with ``AXUIElement``.
    ///
    /// - Note: The ordering of attributes in the `attributes` array must align with these indices for accurate mapping.
    @frozen
    internal enum AttributeValues {
        case title
        case commandCharacter
        case commandModifiers
        case role
        case virtualKey
        case children

        /// The index of the attribute in the `attributes` array.
        ///
        /// This property is essential for indexing into the `attributes` array and ensuring consistency
        /// between logical attributes and their corresponding raw values.
        var index: Int {
            switch self {
            case .title:                return 0
            case .commandCharacter:     return 1
            case .commandModifiers:     return 2
            case .role:                 return 3
            case .virtualKey:           return 4
            case .children:             return 5
            }
        }

        /// The raw key string representing the attribute in Apple's Accessibility API.
        ///
        /// This property provides the exact string keys used to fetch attribute values from accessibility elements.
        /// These keys are constants defined in Apple's Accessibility API and must be accurate to ensure proper functionality.
        var key: String {
            switch self {
            case .title:                return "AXTitle"
            case .commandCharacter:     return "AXMenuItemCmdChar"
            case .commandModifiers:     return "AXMenuItemCmdModifiers"
            case .role:                 return "AXRole"
            case .virtualKey:           return "AXMenuItemCmdVirtualKey"
            case .children:             return "AXChildren"
            }
        }
    }

    // MARK: - Menu Item Types

    /// Types of menu items abstracted for menu bar processing.
    ///
    /// This enum maps specific Accessibility Kit roles (`AXMenuBarItem`, `AXMenuItem`, `AXMenu`) into a cohesive
    /// type system for higher-level menu item handling. It also introduces abstractions like `separator` and `section`,
    /// which do not directly exist in Accessibility APIs but are useful for grouping and processing menu items.
    ///
    /// The abstraction provided by this enum simplifies menu handling logic by categorizing items based on their role
    /// and expected behavior in the menu hierarchy.
    @frozen
    enum MenuItemTypes: String {
        // MARK: Hierarchical Cases

        /// A top-level menu in the menu bar.
        ///
        /// This represents menu items like "File" or "Edit" and corresponds directly to the Accessibility Kit role `AXMenuBarItem`.
        /// These items typically open a submenu when selected.
        case menuBarItem = "AXMenuBarItem"

        /// A standard menu item within a menu or submenu.
        ///
        /// This corresponds to the Accessibility Kit role `AXMenuItem`. Examples include options like "New", "Open", or "Preferences".
        /// These items may have associated commands, shortcuts, or actions.
        case menuItem = "AXMenuItem"

        /// A submenu within a menu bar or another submenu.
        ///
        /// This corresponds to the Accessibility Kit role `AXMenu`. Submenus often group related menu items and can nest hierarchically.
        case menu = "AXMenu"

        // MARK: Abstraction Cases

        /// A menu separator used to divide groups of items visually.
        ///
        /// This is an abstraction not present in the Accessibility Kit but is useful for menu processing.
        /// Separators often signify logical groupings of menu items.
        case separator = "Separator"

        /// A conceptual section within a menu for grouping related items.
        ///
        /// This abstraction helps represent logical groupings, like "Recent Files", in the menu structure.
        case section = "Section"

        /// A menu item with an associated keyboard shortcut.
        ///
        /// This abstraction categorizes menu items with specific key bindings for quick access.
        case hotkey = "Hotkey"

//        /// Maps `MenuItemTypes` to a general-purpose `MenuItemType` for use in broader menu management contexts.
//        ///
//        /// This property ensures compatibility with other systems that process menu items at a higher abstraction level.
//        var menuItemRole: MenuItemType {
//            switch self {
//            case .hotkey:           return .hotkey
//            case .separator:        return .separator
//            case .section:          return .section
//            default:                return .item
//            }
//        }
    }

    // MARK: - Attributes

    /// Accessibility attributes for menu bar elements.
    ///
    /// This array contains the raw keys used to fetch attribute values from accessibility elements. The order
    /// of keys in this array must align with the indices defined in `AttributeValues` to ensure correct mapping.
    ///
    /// Using a centralized attribute array minimizes redundancy and ensures consistent usage across the application.
    static let attributes: [AXAttribute] = [
        AXAttribute.title,
        AXAttribute.menuItemCommandCharacter,
        AXAttribute.menuItemCommandModifiers,
        AXAttribute.role,
        AXAttribute.menuItemCommandVirtualKey,
        AXAttribute.children
    ]
}

// MARK: - Accessibility Attribute Extensions

/// Accessibility attribute keys for menu bar elements.
///
/// These extensions map string-based attribute constants to `CFString` values for use with Apple's Accessibility API.
/// This design centralizes the mapping and ensures code clarity when fetching attributes from accessibility elements.
///
/// ## Tip:
/// Centralizing attribute definitions in one place ensures consistency and simplifies updates when Accessibility APIs change.
extension AXAttribute {

    /// Accessibility attribute for the title of an element.
    static let title: CFString = kAXTitleAttribute as CFString

    /// Accessibility attribute for the command character of a menu item.
    static let menuItemCommandCharacter: CFString = kAXMenuItemCmdCharAttribute as CFString

    /// Accessibility attribute for the command modifiers of a menu item.
    static let menuItemCommandModifiers: CFString = kAXMenuItemCmdModifiersAttribute as CFString

    /// Accessibility attribute for the role of an element.
    static let role: CFString = kAXRoleAttribute as CFString

    /// Accessibility attribute for the virtual key of a menu item.
    static let menuItemCommandVirtualKey: CFString = kAXMenuItemCmdVirtualKeyAttribute as CFString

    /// Accessibility attribute for the children of an element.
    static let children: CFString = kAXChildrenAttribute as CFString
}
