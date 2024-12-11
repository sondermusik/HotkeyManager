//
//  HotkeyVM.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import Combine
import Foundation
import CoreData

@MainActor
final class HotkeyVM: ObservableObject {
    // MARK: - Published Properties

    /// Menu items for the currently active application.
    @Published var appMenuItems: [MenuItem] = []
    @Published var appHotkeys: [MenuItem] = []

    /// Menu items for global applications.
    @Published var globalMenuItems: [MenuItem] = []
    @Published var globalHotkeys: [MenuItem] = []

    private let appVM = AppVM.shared

    /// Service for fetching menu items from the menu bar.
    private let menuBarService = MenuBarService()

    /// Cancellation tokens for cancelling subscriptions of activeApp changes.
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to activeApp changes from AppVM
        appVM.$activeApp
            .sink { [weak self] activeApp in
                self?.handleActiveAppChange(activeApp)
            }
            .store(in: &cancellables)
    }

    /// Method to handle changes to the active app
    private func handleActiveAppChange(_ activeApp: Application?) {
        if let app = activeApp {
            self.appMenuItems = []
            self.appHotkeys = []
            Task {
                await fetchMenu(for: app)
            }
        } else {
            print("[HotkeyVM] No active app change")
        }
    }

    /// Fetches the menu items for the specified app.
    private func fetchMenu(for app: Application) async {
        // Fetch the menu items stream
        let stream = menuBarService.loadMenuItems(for: app)
        do {
            // Process the chunks of menu items from the stream
            for try await chunk in stream {
                // Check if task was canceled before continuing
                guard !Task.isCancelled else {
                    print("[HotkeyVM] Task canceled while fetching menu items for \(app.name)")
                    return
                }

                // Filter and organize menu items into categories
                let hotkeys = chunk.filter { $0.hotkey != nil } // Correct filter closure

                // Here you could transform or append these items to your `@Published` properties
                await MainActor.run {
                    self.appMenuItems.append(contentsOf: chunk) // Use `append(contentsOf:)`
                    self.appHotkeys.append(contentsOf: hotkeys)
                }
            }
            print("[HotkeyVM] Finished fetching and saving menu items for \(app.name)")
        }
    }


    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
