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

    @Published var appMenu: [MenuSection] = []
    @Published var appHotkeys: [MenuItem] = []
    @Published var globalMenu: [MenuSection] = []
    @Published var globalHotkeys: [MenuItem] = []

    private let appVM = AppVM.shared
    private let menuBarService = MenuBarService()
    private let menuDataManager = MenuDataManager()

    private var cancellables = Set<AnyCancellable>()
    private var currentFetchTask: Task<Void, Never>? // This will hold the current fetch task

    init() {
        appVM.$activeApp
            .sink { [weak self] activeApp in
                self?.handleActiveAppChange(activeApp)
            }
            .store(in: &cancellables)
    }

    private func handleActiveAppChange(_ activeApp: Application?) {
        if let app = activeApp {
            self.appMenu = []
            self.appHotkeys = []

            // Cancel any ongoing fetch task before starting a new one
            currentFetchTask?.cancel()
            currentFetchTask = Task {
                await fetchMenu(for: app)
            }
        } else {
            print("[HotkeyVM] No active app change")
        }
    }

    private func fetchMenu(for app: Application) async {
        // Fetch the menu items stream
        let stream = menuBarService.loadMenuItems(for: app)
        do {
            for try await result in stream {
                // Check if task was canceled before continuing
                guard !Task.isCancelled else {
                    print("[HotkeyVM] Task canceled while fetching menu items for \(app.name)")
                    return
                }

                switch result {
                case .item(let item):
                    print("[HotkeyVM] Fetched item for \(app.name)")
                    if item.hotkey != nil && item.hidden == false {
                        await MainActor.run {
                            self.appHotkeys.append(item)
                        }
                        menuDataManager.upsertItem(item)
                    }
                case .section(let section):
                    print("[HotkeyVM] Fetched section for \(app.name)")
                    await MainActor.run {
                        self.appMenu.append(section)
                        self.appHotkeys.append(contentsOf: section.items.filter { $0.hotkey != nil && $0.hidden == false })
                    }
                    menuDataManager.upsertSection(section)
                    for sectionItem in section.flattenedSections() {
                        menuDataManager.upsertSection(sectionItem)
                    }

                    for items in section.flattenedItems() {
                        menuDataManager.upsertItem(items)
                    }
                }
            }
            print("[HotkeyVM] Finished fetching and saving menu items for \(app.name)")
        }
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        currentFetchTask?.cancel() // Cancel any ongoing fetch task when the view model is deinitialized
    }
}
