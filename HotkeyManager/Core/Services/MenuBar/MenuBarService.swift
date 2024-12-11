//
//  MenuBarService.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 11.12.24.
//

import ApplicationServices
import Cocoa

internal class MenuBarService {
    typealias Const = ConstMenuBar

    private let task: TaskPriority = .utility

    func loadMenuItems(for app: Application, chunkSize: Int = 75) -> AsyncStream<[MenuItem]> {
        AsyncStream { continuation in
            Task(priority: task){
                do {
                    print("Starting to load menu items for \(app.name)")

                    let stream = try await self.getMenuItems(for: app, chunkSize: chunkSize)

                    for await chunk in stream {
                        if Task.isCancelled {
                            print("Cancelled loading menu items for \(app.name)")
                            continuation.finish()
                            return
                        }
                        continuation.yield(chunk)
                    }

                    continuation.finish()
                } catch {
                    if !Task.isCancelled {
                        print("Failed to load menu items for \(app.name): \(error)")
                    }
                    continuation.finish()
                }
            }
        }
    }

    // MARK: - Private Methods

    /// Fetches menu items for the specified application.
    ///
    /// This method retrieves sections of the menu bar and processes them concurrently, yielding chunks of menu items.
    ///
    /// - Parameters:
    ///   - app: The bundle identifier of the target application.
    ///   - chunkSize: The number of items per chunk to yield.
    /// - Returns: An `AsyncStream` of `MenuItem` arrays.
    private func getMenuItems(for app: Application, chunkSize: Int = 25) async throws -> AsyncStream<[MenuItem]> {
        AsyncStream { continuation in
            Task(priority: task){
                guard !Task.isCancelled else {
                    continuation.finish()
                    return
                }

                await withTaskGroup(of: Result<[MenuItem], Error>.self) { group in
                    for await section in self.getSections(for: app) {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }

                        group.addTask {
                            do {
                                let results = try await self.traverseMenu(item: section, parent: nil, chunkSize: chunkSize)
                                return .success(results)
                            } catch {
                                return .failure(error)
                            }
                        }
                    }

                    for await result in group {
                        switch result {
                        case .success(let chunk):
                            continuation.yield(chunk)

                        case .failure(let error):
                            print("Failed to load menu items for \(app.name): \(error)")
                        }
                    }
                }

                continuation.finish()
            }
        }
    }

    /// Validates and retrieves the menu bar reference for the given app.
    ///
    /// This method ensures the application is running and its menu bar is accessible.
    ///
    /// - Parameter app: The bundle identifier of the target application.
    /// - Returns: The `MenuBarElement` representing the menu bar, or `nil` if not found.
    private func fetchMenuBar(for app: Application) async -> MenuBarElement? {
        var id = app.id
        if app.id == "com.apple.Apple" { id = "com.apple.Finder" }
        guard let runningApp = NSRunningApplication.runningApplications(
            withBundleIdentifier: id
        ).first else {
            return nil
        }

        let appRef = AXUIElementCreateApplication(runningApp.processIdentifier)
        var menuBarRef: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(appRef, kAXMenuBarAttribute as CFString, &menuBarRef)
        guard result == .success, let menuBar = menuBarRef else {
            //            Crashlytics.crashlytics().record(
            //                error: FIRMenuBar.Errors.menuBarRetrievalFailed(app.id, result).log()
            //            )
            return nil
        }

        return await MenuBarElement(
            element: menuBar as! AXUIElement,
            app: app,
            layer: 0,
            index: 0
        )
    }

    /// Traverses a menu bar item recursively, processing its children concurrently.
    ///
    /// - Parameters:
    ///   - item: The `MenuBarElement` to process.
    ///   - chunkSize: The number of items per chunk.
    /// - Returns: An array of `MenuItem` objects.
    private func traverseMenu(
        item: MenuBarElement,
        parent: MenuItem?,
        chunkSize: Int = 25
    ) async throws -> [MenuItem] {
        guard !Task.isCancelled else {
            throw CancellationError()
        }


        let children = try await withThrowingTaskGroup(of: [MenuItem].self) { group -> [MenuItem] in
            for await child in await item.getChildren() {
                group.addTask(priority: task) {
                    try await self.traverseMenu(item: child, parent: parent, chunkSize: chunkSize)
                }
            }

            var childItems: [MenuItem] = []
            for try await childResults in group {
                childItems.append(contentsOf: childResults)
            }
            return childItems
        }

        if let menuItem = MenuItem(from: item, parent: parent, children: children) {
            return [menuItem]
        }

        // Yielding the parent item and its children through the stream
        return []
    }

    /// Fetches child sections from a menu bar element.
    ///
    /// - Parameter menuBar: The top-level `MenuBarElement`.
    /// - Returns: An `AsyncStream` of `MenuBarElement` objects representing the sections.
    private func fetchChildSections(from menuBar: MenuBarElement, onlyFirst: Bool = false) -> AsyncStream<MenuBarElement> {
        AsyncStream { continuation in
            Task(priority: task){
                defer { continuation.finish() }

                for await section in await menuBar.getChildren() {
                    // Handle the case when onlyFirst is true (only return items with index == 0)
                    if onlyFirst && section.index == 0 {
                        continuation.yield(section)
                    } else if section.index != 0 {
                        // Handle the case when onlyFirst is false (return all items)

                        continuation.yield(section)
                    }
                }
            }
        }
    }

    /// Retrieves the sections of the menu bar for the specified application.
    ///
    /// - Parameter app: The bundle identifier of the target application.
    /// - Returns: An `AsyncStream` of `MenuBarElement` objects representing the sections.
    private func getSections(for app: Application) -> AsyncStream<MenuBarElement> {
        AsyncStream { continuation in
            Task(priority: task){
                defer { continuation.finish() }

                guard let menuBar = await fetchMenuBar(for: app) else {
                    return
                }

                var onlyFirst = false
                if app.id == "com.apple.Apple" { onlyFirst = true }

                for await section in fetchChildSections(from: menuBar, onlyFirst: onlyFirst) {
                    continuation.yield(section)
                }
            }
        }
    }
}
