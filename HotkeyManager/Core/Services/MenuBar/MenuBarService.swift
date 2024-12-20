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

    /// Loads menu items for a specified application in chunks.
    ///
    /// This method starts an asynchronous stream of menu items for the given application, yielding chunks of menu items as they are processed.
    /// The menu items are grouped into chunks based on the specified chunk size.
    ///
    /// - Parameters:
    ///   - app: The application whose menu items are to be loaded.
    ///   - chunkSize: The number of items to yield per chunk.
    /// - Returns: An `AsyncStream` of `MenuItem` arrays.
    func loadMenuItems(for app: Application) -> AsyncStream<MenuResult> {
        AsyncStream { continuation in
            Task(priority: task){
                do {
                    print("Starting to load menu items for \(app.name)")

                    let stream = try await self.getMenuItems(for: app)

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
    private func getMenuItems(for app: Application) async throws -> AsyncStream<MenuResult> {
        AsyncStream { continuation in
            Task(priority: task) {
                guard !Task.isCancelled else {
                    continuation.finish()
                    return
                }

                await withTaskGroup(of: Result<MenuResult, Error>.self) { group in
                    for await section in self.getSections(for: app) {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }

                        group.addTask {
                            do {
                                // Unwrap the optional result from traverseMenu
                                if let results = try await self.traverseMenu(item: section) {
                                    return .success(results)
                                } else {
                                    return .failure(NSError(domain: "MenuTraversal", code: 0, userInfo: [NSLocalizedDescriptionKey: "Traversal returned nil"]))
                                }

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

    /// Fetches the menu bar for a given application.
    ///
    /// This method validates the application’s availability and retrieves the associated menu bar reference. If the menu bar cannot be found,
    /// the method returns `nil`.
    ///
    /// - Parameter app: The application for which the menu bar is to be fetched.
    /// - Returns: A `MenuBarElement` representing the menu bar of the application, or `nil` if not found.
    private func fetchMenuBar(for app: Application) async -> MenuBarElement? {
        // Handle fetching Apple Global MenuSection hotkeys using finder
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
            print("Failed to retrieve menu bar for \(app.name) with error: \(result)")
            return nil
        }

        return await MenuBarElement(
            element: menuBar as! AXUIElement,
            app: app,
            layer: 0,
            index: 0
        )
    }

    /// Recursively traverses a menu bar item and its children.
    ///
    /// This method processes the menu bar elements and recursively traverses through their children. It processes menu items in chunks
    /// and returns a list of `MenuItem` objects.
    ///
    /// - Parameters:
    ///   - item: The `MenuBarElement` to traverse.
    ///   - chunkSize: The number of items per chunk to yield.
    /// - Returns: An array of `MenuItem` objects, representing the items in the menu.
    /// - Returns: An array of `MenuItem` objects, representing the items in the menu.
    private func traverseMenu(item: MenuBarElement, parent: MenuSection? = nil) async throws -> MenuResult? {
        guard !Task.isCancelled else {
            throw CancellationError()
        }

        // Collect children from getChildren
        var childrenArray: [MenuBarElement] = []
        for await child in await item.getChildren() {
            childrenArray.append(child)
        }

        // Check if there are any children
        guard !childrenArray.isEmpty else {
            print("No children found for \(item.title ?? "unknown")")
            if let parent {
                if let item = MenuItem(from: item, parent: parent) {
                    print("Created MenuItem for \(item.name)")
                    return .item(item)
                }
            }
            return nil
        }

        // Process children in a task group
        if let section = MenuSection(from: item, parent: parent) {
            let children = try await withThrowingTaskGroup(of: MenuResult?.self) { group -> [MenuResult] in
                for child in childrenArray {
                    group.addTask {
                        try await self.traverseMenu(item: child, parent: section)
                    }
                }

                var childItems: [MenuResult] = []
                for try await childResults in group {
                    if let result = childResults { // Filter out nil results
                        childItems.append(result)
                    }
                }
                return childItems
            }

            // Filter children into MenuItems and MenuSections
            let menuItems = children.compactMap { result -> MenuItem? in
                if case .item(let menuItem) = result {
                    return menuItem
                }
                return nil
            }
            section.addItems(menuItems)

            let menuSections = children.compactMap { result -> MenuSection? in
                if case .section(let menuSection) = result {
                    return menuSection
                }
                return nil
            }
            section.addChildren(menuSections)

            print("MenuSections: \(menuSections.count) MenuItems: \(menuItems.count)")

            return .section(section)
        }
        print("Failed to create MenuSection")

        return nil
    }

    /// Fetches child sections from a menu bar element.
    ///
    /// This method retrieves the child sections of a menu bar element. It processes these sections and yields them as an `AsyncStream`.
    ///
    /// - Parameter menuBar: The top-level `MenuBarElement`.
    /// - Parameter onlyFirst: A flag indicating whether to fetch only the first section.
    ///                        If set to `true`, only the first section with index 0 will be yielded.
    ///                        Set to false by default to prevent repetitive fetching of Apple menu items.
    ///
    /// - Returns: An `AsyncStream` of `MenuBarElement` objects, representing the sections in the menu bar.
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

    /// Retrieves the sections of the menu bar for a specified application.
    ///
    /// This method fetches the sections of the menu bar for the given application and returns them as an `AsyncStream` of `MenuBarElement`
    /// objects. Each section corresponds to a distinct part of the menu bar.
    ///
    /// - Parameter app: The application whose menu bar sections are to be fetched.
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
