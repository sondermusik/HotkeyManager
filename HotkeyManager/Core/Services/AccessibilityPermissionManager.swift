//
//  AccessibilityPermissionManager.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import Cocoa
import Foundation

/// Manages macOS Accessibility permissions required for interacting with the system UI.
final class AccessibilityPermissionManager: ObservableObject {
    // MARK: - Singleton Instance

    /// Shared instance for global access.
    static let shared = AccessibilityPermissionManager()

    // MARK: - Published Properties

    /// Tracks whether Accessibility permissions are enabled.
    ///
    /// This property is updated whenever `isAccessibilityEnabled` is called.
    @Published internal private(set) var accessibilityEnabled: Bool = false

    // MARK: - Private Properties

    /// URL to open the *Security & Privacy* settings page.
    private let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )

    // MARK: - Initializer

    /// Private initializer to enforce the singleton pattern.
    ///
    /// Ensures centralized management of Accessibility permissions.
    private init() {
        self.accessibilityEnabled = isAccessibilityEnabled()
    }

    // MARK: - Public Methods

    /// Checks and updates the Accessibility permission state.
    ///
    /// - Returns: A Boolean indicating whether the app has Accessibility permissions.
    private func isAccessibilityEnabled() -> Bool {
        let currentState = AXIsProcessTrusted()

        if currentState != accessibilityEnabled {
            accessibilityEnabled = currentState
        }

        return currentState
    }

    /// Requests Accessibility permissions if they are not already enabled.
    ///
    /// Opens the *Security & Privacy* settings page and triggers a system prompt if necessary.
    /// This method dispatches UI-related operations to the main thread to ensure thread safety.
    func ensureAccessibilityPermissions() {
        guard !isAccessibilityEnabled() else {
            return
        }

        print("[Accessibility] Requesting Accessibility Permissions")

        DispatchQueue.main.async { [weak self] in
            self?.openAccessibilitySettings()
            self?.triggerAccessibilityPrompt()
        }
    }

    // MARK: - Private Methods

    /// Opens the *Security & Privacy* settings page to the Accessibility tab.
    private func openAccessibilitySettings() {
        guard let settingsURL else {
            print("[Accessibility] Invalid Settings URL")
            return
        }

        if NSWorkspace.shared.open(settingsURL) {
        } else {
            print("[Accessibility] Failed to open Accessibility Settings")
        }
    }

    /// Triggers an Accessibility prompt by simulating a system event.
    private func triggerAccessibilityPrompt() {
        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            print("[Accessibility] Failed to create event source")
            return
        }

        guard let moveEvent = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .mouseMoved,
            mouseCursorPosition: CGPoint(x: 0, y: 0),
            mouseButton: .left
        ) else {
            print("[Accessibility] Failed to create mouse event")
            return
        }

        moveEvent.post(tap: .cgSessionEventTap)
    }
}
