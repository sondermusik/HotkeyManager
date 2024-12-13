//
//  Hotkey.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import Foundation
import SwiftUI

class Hotkey {
    // MARK: - Properties

    /// The  ``KeyCode`` associated with the hotkey.
    var keyCode: KeyCode
    var command: Bool = false
    var shift: Bool = false
    var option: Bool = false
    var control: Bool = false
    var function: Bool = false

    // MARK: - Initializers

    /// Initializes a `Hotkey` with a ``KeyCode`` and optional modifiers.
    init?(
        keyCode: Int,
        command: Bool = false,
        shift: Bool = false,
        option: Bool = false,
        control: Bool = false,
        function: Bool = false
    ) {
        guard let validKeyCode = KeyCode(rawValue: Int(keyCode)) else {
            return nil
        }
        self.keyCode = validKeyCode
        self.command = command
        self.shift = shift
        self.option = option
        self.control = control
        self.function = function
    }

    init?(from element: MenuBarElement) {
        guard let code = element.keyCode else { return nil }
        guard let code = KeyCode(rawValue: code) else { return nil }
        self.keyCode = code
        if let modifiers = element.modifiers {
            modifierFromElement(mask: modifiers)
        }
    }

    /// Initializes a `Hotkey` from a `MenuItemEntity`.
    init(from entity: MenuItemEntity) {
        guard let validKeyCode = KeyCode(rawValue: Int(entity.keyCode)) else {
            fatalError("Invalid keyCode in MenuItemEntity: \(entity.keyCode)")
        }
        self.keyCode = validKeyCode

        modifierFromInt16(mask: entity.modifier)
    }
}

extension Hotkey {
    // MARK: - Display

    /// Generates a human-readable display string for the hotkey.
    func toDisplay() -> String {
        let key = keyCode.displayString

        var modifier = ""
        if command { modifier += "􀆔 " }
        if shift { modifier += "􀆝 " }
        if option { modifier += "􀆕 " }
        if control { modifier += "􀆍 " }
        return modifier + key
    }
}

extension Hotkey {
    // MARK: - Modifier

    /// Modifier Init from Int16 (bitmask) used for CoreData
    func modifierFromInt16 (mask: Int16) {
        self.command = (mask & 0x01) != 0      // Command (Bit 0)
        self.shift = (mask & 0x02) != 0        // Shift (Bit 1)
        self.option = (mask & 0x04) != 0       // Option (Bit 2)
        self.control = (mask & 0x08) != 0      // Control (Bit 3)
        self.function = (mask & 0x10) != 0     // Function (Bit 4)
    }

    /// Encode to Int16 (bitmask) used for CoreData
    func modifierToInt16() -> Int16 {
        var mask: Int16 = 0
        if command { mask |= 0x01 }   // Command (Bit 0)
        if shift { mask |= 0x02 }     // Shift (Bit 1)
        if option { mask |= 0x04 }    // Option (Bit 2)
        if control { mask |= 0x08 }   // Control (Bit 3)
        if function { mask |= 0x10 }  // Function (Bit 4)
        return mask
    }

    /// Modifier Init from ``MenuBarElement`` attributes
    func modifierFromElement (mask: Int) {
        self.command = (0...8).contains(mask)
        self.shift = (mask % 2 == 1) // Odd masks enable shift
        self.option = (mask & 0b0010) != 0 // Second bit
        self.control = ((4...7).contains(mask) || (12...15).contains(mask))
        self.function = (mask == 24)
    }
}
