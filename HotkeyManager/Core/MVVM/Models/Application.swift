//
//  Application.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import Cocoa
import CoreData

class Application: Identifiable, ObservableObject {
    // MARK: - Properties

    /// BundleID of the Application
    let id: String

    /// Display Name of the Application
    let name: String

    /// Indicates if the application is global
    ///
    /// Initial set using
    /// ```swift
    /// let global = app.activationPolicy != .regular
    /// ```
    ///
    /// Can be updated by user
    var global: Bool

    /// User setting that indicates
    /// if the Apps Hotkeys should be fetched and displayed
    var display: Bool

    /// The Children Items of the Application
    var items: [MenuItem]

    /// Computed property to fetch the app icon
      var icon: NSImage? {
          NSWorkspace.shared.runningApplications
              .first { $0.bundleIdentifier == id }?
              .icon
      }


    // MARK: - Initializer

    init(id: String, name: String, display: Bool, global: Bool, items: [MenuItem] = []) {
        self.id = id
        self.name = name
        self.display = display
        self.global = global
        self.items = items
    }

    init?(nsApp: NSRunningApplication) {
        guard let id = nsApp.bundleIdentifier, let name = nsApp.localizedName else {
            print("[Application] Missing required properties")
            return nil
        }

        guard id != Bundle.main.bundleIdentifier else {
            return nil
        }

        // Initialize all properties
        self.id = id
        self.name = name
        self.display = true
        self.global = nsApp.activationPolicy != .regular
        self.items = []
    }
}

extension Application: Equatable {
    // MARK: - Equatable

    static func == (lhs: Application, rhs: Application) -> Bool {
        lhs.id == rhs.id
    }
}
