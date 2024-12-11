//
//  AppVM.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 06.12.24.
//

import Foundation

final class AppVM: ObservableObject {
    // MARK: - Singleton Instance

    static let shared = AppVM()

    // MARK: - Published Properties

    @Published var activeApp: Application?
    @Published var recentApps: [Application] = []
    @Published var globalApp: [Application] = []

    private let workspace = WorkspaceReceiver()

    private init() {
        self.fetchApps()
    }

    /// Activates the specified app and its menu traversal.
    func activateApp(_ app: Application) {
        guard app != activeApp else { return }

        activeApp = app

        if !app.global {
            recentApps.removeAll(where: { $0.id == app.id })
            recentApps.insert(app, at: 0)
        }
    }
}

extension AppVM {
    /// Fetches the running apps and updates the properties using ``WorkspaceReceiver``.
    private func fetchApps() {
        // Fetch the running apps asynchronously
        Task {
            // Fetch running apps
            let runningApps = await workspace.fetchAllRunningApps(limit: 4)

            // Convert to `Application` instances
            let apps = runningApps.compactMap { Application(nsApp: $0) }.filter { $0.global == false }

            // Filter global and regular apps
            let globalApps = workspace.fetchGlobalApps().compactMap { Application(nsApp: $0) }

            // Update properties on the main thread
            DispatchQueue.main.async {
                self.globalApp = globalApps
                self.recentApps = apps
                self.activeApp = apps.first
            }
        }
    }
}
