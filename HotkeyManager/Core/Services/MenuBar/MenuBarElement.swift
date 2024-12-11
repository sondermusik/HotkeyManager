//
//  MenuBarElement.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 20.11.24.
//

import ApplicationServices
import Cocoa

// MARK: - MenuBarElement

/// Represents an accessibility element in the macOS menu bar.
///
/// This struct models the data for a single menu bar element, such as menu items or sections, with properties and methods to fetch, resolve, and cache its attributes asynchronously.
///
/// The `MenuBarElement` supports hierarchical structures by fetching child elements recursively and processes hotkeys, roles, and other attribute values in a performant, concurrent manner.
///
/// ## Features
/// - Caches accessibility attributes for performance.
/// - Resolves roles and hotkeys conditionally, optimizing for usage patterns in macOS apps.
/// - Provides concurrency-safe APIs using `async` and structured task groups.
/// - Implements a unique identifier (`id`) for precise tracking and debugging.
///
/// - Important: Requires macOS Accessibility Access permission and App Sandboxing disabled to access menu bar elements.
internal struct MenuBarElement: Identifiable {
    // MARK: - Typealiases

    /// Local alias for constant definitions to improve code readability.
    private typealias Const = ConstMenuBar
    private typealias AttrValues = Const.AttributeValues

    /// Encapsulates resolution results for attributes like title, role, keyCode, and modifiers.
    ///
    /// Provides a structured way to aggregate values from multiple concurrent tasks.
    private struct ResolutionResult {
        var title: String?
        var role: Const.MenuItemTypes?
        var keyCode: Int?
        var modifiers: Int?

        init(
            title: String? = nil,
            role: Const.MenuItemTypes? = nil,
            keyCode: Int? = nil,
            modifiers: Int? = nil
        ) {
            self.title = title
            self.role = role
            self.keyCode = keyCode
            self.modifiers = modifiers
        }
    }

    // MARK: - Public Properties

    /// The underlying macOS accessibility element.
    let element: AXUIElement

    /// The unique identifier for the associated app process.
    let app: Application

    /// Index of the element within its sibling hierarchy, aiding in distinguishing elements.
    let index: Int

    /// The depth of the element within the menu hierarchy.
    let layer: Int

    /// Cached title of the menu bar element.
    private(set) var title: String?

    /// Cached role of the menu bar element, describing its type (e.g., menu item, hotkey).
    private(set) var role: ConstMenuBar.MenuItemTypes

    /// Cached key code for the element, if applicable, representing keyboard shortcuts.
    private(set) var keyCode: Int?

    /// Cached modifier keys for the element, if applicable, representing keyboard shortcuts.
    private(set) var modifiers: Int?

    /// A unique identifier generated for each menu bar element.
    ///
    /// Combines process ID, memory address, and index for consistent identification.
    var id: String { generateID() }

    // MARK: - Private Properties

    /// A dictionary of accessibility attributes fetched from the underlying macOS APIs.
    ///
    /// Provides raw data used for resolving other properties like `title` and `role`.
    private let attributes: [String: Any]

    // MARK: - Initialization

    /// Initializes a new `MenuBarElement` with an accessibility element and app metadata.
    ///
    /// This initializer fetches attributes and resolves properties asynchronously for better responsiveness.
    ///
    /// - Parameters:
    ///   - element: The macOS accessibility element.
    ///   - appID: The identifier for the associated application.
    ///   - layer: The depth of the element in the menu hierarchy.
    ///   - index: The element's position within its siblings.
    init(element: AXUIElement, app: Application, layer: Int, index: Int) async {
        self.element = element
        self.app = app
        self.layer = layer
        self.index = index

        // Fetch attributes asynchronously
        let attributes = await Self.fetchAttributes(for: element)
        self.attributes = attributes

        // Use an array to collect individual results safely
        let results = await withTaskGroup(of: ResolutionResult.self) { group -> [ResolutionResult] in
            // Title resolution
            group.addTask {
                let title = await Self.resolveTitle(from: attributes)
                return ResolutionResult(title: title)
            }

            // Role resolution
            group.addTask {
                let role = await Self.resolveRole(from: attributes)
                var result = ResolutionResult(role: role)

                // Conditionally resolve keyCode and modifiers
                if role == .hotkey {
                    async let keyCode = Self.resolveKeyCode(from: attributes)
                    async let modifiers = Self.resolveModifiers(from: attributes)

                    if let keyCode = await keyCode {
                        result.keyCode = keyCode
                        result.role = .hotkey
                    }

                    result.modifiers = await modifiers
                }

                return result
            }

            // Aggregate results
            var collectedResults: [ResolutionResult] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }

        // Aggregate results into a final resolution
        var finalResult = ResolutionResult()
        for result in results {
            if let title = result.title { finalResult.title = title }
            if let role = result.role { finalResult.role = role }
            if let keyCode = result.keyCode { finalResult.keyCode = keyCode }
            if let modifiers = result.modifiers { finalResult.modifiers = modifiers }
        }

        // Assign resolved values to self
        self.title = finalResult.title ?? "ERROR"
        self.role = finalResult.role ?? .menuItem
        self.keyCode = finalResult.keyCode
        self.modifiers = finalResult.modifiers
    }

    // MARK: - Attribute Fetching

    /// Fetches and maps attributes for a given accessibility element.
    ///
    /// This method performs asynchronous concurrent fetching to minimize latency when interacting with the macOS Accessibility API.
    ///
    /// - Parameter element: The accessibility element to fetch attributes for.
    /// - Returns: A dictionary containing key-value pairs of attributes.
    private static func fetchAttributes(for element: AXUIElement) async -> [String: Any] {
        let rawValues = await fetchRawAttributeValues(for: element, keys: Const.attributes)

        return await withTaskGroup(of: (String, Any?).self) { group -> [String: Any] in
            for (index, key) in Const.attributes.enumerated() {
                group.addTask {
                    guard !Task.isCancelled else {
                        return (key as String, nil)
                    }
                    let value = rawValues.indices.contains(index) ? rawValues[index] : nil
                    return (key as String, value is NSNull ? nil : value)
                }
            }

            var attributes: [String: Any] = [:]
            for await (key, value) in group {
                attributes[key] = value
            }

            if attributes.isEmpty {
//                Crashlytics.crashlytics().record(
//                    error: FIRMenuBar.Errors.invalidAttribute(String(describing: element)).log()
//                )
            }

            return attributes
        }
    }

    /// Fetches raw attribute values for given keys with structured concurrency.
    ///
    /// - Parameters:
    ///   - element: The accessibility element.
    ///   - keys: The keys to fetch values for.
    /// - Returns: An array of raw values.
    private static func fetchRawAttributeValues(for element: AXUIElement, keys: [CFString]) async -> [Any] {
        await Task {
            guard !Task.isCancelled else {
                return []
            }

            var values: CFArray?
            let result = AXUIElementCopyMultipleAttributeValues(
                element,
                keys as CFArray,
                AXCopyMultipleAttributeOptions(rawValue: 0),
                &values
            )
            guard result == .success, let valuesArray = values as? [Any] else {
//                Crashlytics.crashlytics().record(error: FIRMenuBar.Errors.fetchError(result).log())
                return []
            }
            return valuesArray
        }.value
    }

    // MARK: - Attribute Resolution

    /// Resolves the title of the menu bar element from its attributes.
    ///
    /// The title is resolved based on the `title` attribute or, as a fallback, the element's `role`.
    /// This ensures meaningful default values are used when the `title` attribute is unavailable.
    ///
    /// - Parameter attributes: A dictionary containing the accessibility attributes of the element.
    /// - Returns: The resolved title string.
    private static func resolveTitle(from attributes: [String: Any]) async -> String? {
        await Task.detached {
            attributes[AttrValues.title.key] as? String
        }.value
    }

    /// Resolves the role of the menu bar element from its attributes.
    ///
    /// The role determines the type of menu bar element, such as a standard menu item, hotkey, section, or separator.
    /// Additional attributes like `virtualKey`, `commandCharacter`, or `children` are analyzed to resolve specialized roles.
    ///
    /// - Parameter attributes: A dictionary containing the accessibility attributes of the element.
    /// - Returns: A `Const.MenuItemTypes` value representing the resolved role.
    private  static func resolveRole(from attributes: [String: Any]) async -> Const.MenuItemTypes {
        // Extract the raw role
        let rawRole = attributes[AttrValues.role.key] as? String
        let resolvedRole = Const.MenuItemTypes(
            rawValue: rawRole ?? Const.MenuItemTypes.menuItem.rawValue
        ) ?? .menuItem

        // Early return for non-menu items
        guard resolvedRole == .menuItem else {
            return resolvedRole
        }

        // Concurrently fetch required attributes
        async let virtualKey = attributes[AttrValues.virtualKey.key] as? Int
        async let commandCharacter = attributes[AttrValues.commandCharacter.key] as? String
        async let childrenCount = (attributes[AttrValues.children.key] as? [AXUIElement])?.count ?? 0
        async let title = attributes[AttrValues.title.key] as? String

        // Await the results
        let virtualKeyValue = await virtualKey
        let commandCharacterValue = await commandCharacter
        let childrenExist = await childrenCount > 0
        let titleValue = await title

        // Determine specific cases for menu items
        if virtualKeyValue != nil || !(commandCharacterValue?.isEmpty ?? true) {
            return .hotkey
        }

        if childrenExist { return .section }

        if titleValue?.isEmpty ?? false { return .separator }

        return .menuItem
    }

    /// Resolves the key code associated with a menu item.
    ///
    /// The key code represents the virtual key equivalent for a hotkey menu item. It is determined
    /// either directly from the `virtualKey` attribute or inferred from the `commandCharacter` attribute.
    ///
    /// - Parameter attributes: A dictionary containing the accessibility attributes of the element.
    /// - Returns: The key code as an optional integer.
    private static func resolveKeyCode(from attributes: [String: Any]) async -> Int? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                if let virtualKey = attributes[AttrValues.virtualKey.key] as? Int {
                    continuation.resume(returning: virtualKey)
                    return
                }
                if let cmdChar = attributes[AttrValues.commandCharacter.key] as? String {
                    if let keyCode = KeyCode.keyCode(for: cmdChar) {
                        continuation.resume(returning: keyCode)
                        return
                    }
                }
                // If no key code or command character is found, resume with nil
                continuation.resume(returning: nil)
            }
        }
    }

    /// Resolves the hotkey modifiers for a menu item.
    ///
    /// Modifiers include keys such as Command, Shift, Option, and Control. These are determined
    /// from a modifier mask extracted from the element's attributes.
    ///
    /// - Parameter attributes: A dictionary containing the accessibility attributes of the element.
    /// - Returns: A `HotkeyModifier` object representing the resolved modifiers.
    private  static func resolveModifiers(from attributes: [String: Any]) async -> Int? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                guard let mask = attributes[AttrValues.commandModifiers.key] as? Int else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: mask)
            }
        }
    }

    // MARK: - Helpers

    /// Generates a unique identifier for the menu bar element.
    ///
    /// This identifier is constructed using the process ID, the memory address of the `AXUIElement`,
    /// and the element's index. This ensures uniqueness across different elements and sessions.
    ///
    /// - Returns: A string representing the unique identifier.
    private  func generateID() -> String {
        var processID: pid_t = 0
        AXUIElementGetPid(element, &processID) // Retrieve process ID

        // Pointer address of the AXUIElement as a unique part of the ID
        let elementAddress = Unmanaged.passUnretained(element).toOpaque().hashValue

        // Combine components into a unique string
        return String(format: "%d-%d-%d", processID, elementAddress, index)
    }

    /// Creates a child element.
    ///
    /// - Parameters:
    ///   - element: The child accessibility element.
    ///   - index: The index of the child.
    /// - Returns: A new `MenuBarElement`.
    private func createChildElement(_ element: AXUIElement, index: Int) async -> Self {
        await Self(
            element: element,
            app: app,
            layer: layer + 1,
            index: index
        )
    }

    func getChildren() async -> AsyncStream<Self> {
        AsyncStream { continuation in
            Task { @Sendable in
                // Ensure proper cleanup of the continuation when the task completes or is cancelled.
                defer { continuation.finish() }

                // Attempt to retrieve the `children` attribute from the element's attributes.
                guard let childrenArray = attributes[AttrValues.children.key] as? [AXUIElement] else {
                    // If no children are found, gracefully exit without yielding any elements.
                    return
                }

                do {
                    // Process each child element concurrently using a throwing task group.
                    try await withThrowingTaskGroup(of: Self?.self) { group in
                        for (childIndex, childElement) in childrenArray.enumerated() {
                            group.addTask {
                                // Skip processing if the task is cancelled to save resources.
                                guard !Task.isCancelled else { return nil }
                                // Create and return a child `MenuBarElement` for the current child.
                                return await createChildElement(childElement, index: childIndex)
                            }
                        }

                        for try await child in group {
                            // Handle cancellation between processing iterations.
                            guard !Task.isCancelled else { break }
                            // Safely unwrap the returned child element before yielding it.
                            guard let validChild = child else { continue }

                            // Recursively process children of menu-type elements to yield nested elements.
                            if validChild.role == Const.MenuItemTypes.menu {
                                for await grandChild in await validChild.getChildren() {
                                    // Handle potential cancellation during recursion.
                                    guard !Task.isCancelled else { break }
                                    continuation.yield(grandChild)
                                }
                            } else {
                                // Yield non-menu child elements directly.
                                continuation.yield(validChild)
                            }
                        }
                    }
                } catch {
                    // Log errors to aid debugging without disrupting execution for other elements.
//                    Crashlytics.crashlytics().record(error: FIRMenuBar.Errors.getChildrenFailed(error).log())
                }
            }
        }
    }
}
