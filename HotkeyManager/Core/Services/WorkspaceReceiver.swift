//
//  WorkspaceReceiver.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 20.11.24.
//

import ApplicationServices
import Cocoa

/// Service for managing application-related business logic.
internal final class WorkspaceReceiver {
    // MARK: - Private Properties

    /// NSWorkspace instance for managing app-related notifications.
    private let workspace = NSWorkspace.shared

    // MARK: - Public API

    /// Fetches all currently running apps across all workspaces.
    func fetchAllRunningApps(limit: Int = 4) async -> [NSRunningApplication] {
        let workspaceApps = await fetchWorkspaceApps()
        let filteredApps = workspaceApps.filter { $0.activationPolicy == .regular }

        if filteredApps.count >= limit {
            return Array(filteredApps.prefix(limit))
        }

        let additionalApps = await fetchRunningApps(limit: limit)
            .filter { app in
                !filteredApps.contains { $0.bundleIdentifier == app.bundleIdentifier }
            }
        return filteredApps + additionalApps
    }

    /// Fetches all global apps where activation policy is not `.regular`,
    /// excluding Apple utility services.
    func fetchGlobalApps() -> [NSRunningApplication] {
        let runningApps = workspace.runningApplications
        return runningApps.filter { app in
            app.activationPolicy != .regular &&
            !(app.bundleIdentifier?.hasPrefix("com.apple") ?? false)
        }
    }


    // MARK: - Private Methods

    /// Fetches a list of running apps using `NSWorkspace`.
    private func fetchRunningApps(limit: Int) async -> [NSRunningApplication] {
        let runningApps = workspace.runningApplications
        let filteredApps = runningApps.filter { $0.activationPolicy == .regular }
        return Array(filteredApps.prefix(limit))
    }

    /// Fetches and updates all workspace apps using `CGWindowListCopyWindowInfo`.
    private func fetchWorkspaceApps() async -> [NSRunningApplication] {
        await withCheckedContinuation { continuation in
            let options: CGWindowListOption = [.excludeDesktopElements, .optionOnScreenOnly]
            guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
                continuation.resume(returning: [])
                return
            }

            let windowOwners = Set(
                windows.compactMap { $0[kCGWindowOwnerName as String] as? String }
            )

            let runningApps = workspace.runningApplications.filter { app in
                guard let appName = app.localizedName else { return false }
                return windowOwners.contains(appName)
            }
            continuation.resume(returning: runningApps)
        }
    }
}
