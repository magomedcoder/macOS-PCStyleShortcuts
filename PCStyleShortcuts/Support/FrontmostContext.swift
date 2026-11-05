import ApplicationServices
import AppKit


enum FrontmostContext {
    private static let selectionGatedActionIDs: Set<String> = ["editing.copy", "editing.cut",  "editing.undo"]
    private static let paneHints = ["terminal", "console"]
    private static let editorHints = ["editor", "monaco"]
    private static let dedicatedAppHints = ["terminal", "iterm", "kitty", "alacritty", "wezterm", "warp", "hyper", "ghostty"]
    private static let state = ContextState()
    private static let mouseSelection = MouseSelectionTracker()
    private static let electronAccessibility = ElectronAccessibilityGate()

    static func shouldKeepShellShortcut(actionID: String) -> Bool {
        guard selectionGatedActionIDs.contains(actionID) else { return false }
        if state.snapshot.hasTextSelection || mouseSelection.hasLikelySelection {
            return false
        }
        return state.snapshot.keepShellWithoutSelection
    }

    static func startMonitoringIfNeeded() {
        state.startMonitoringIfNeeded(refresh: refreshSnapshot)
    }

    static func noteMouseEvent(type: CGEventType, event: CGEvent) {
        mouseSelection.handle(type: type, event: event)
    }

    private static func refreshSnapshot() {
        let app = NSWorkspace.shared.frontmostApplication
        let electron = app.map(isElectronApp) ?? false
        if let app, electron {
            electronAccessibility.enableIfNeeded(pid: app.processIdentifier)
        }

        let selection = hasTextSelection()
        let keepShell: Bool

        if frontmostIsDedicatedTerminalApp() {
            keepShell = true
        } else if electron {
            if focusedHierarchyLooksLikeTerminal(deepWalk: true) {
                keepShell = true
            } else if isEditorContextFocused(deepWalk: true) {
                keepShell = false
            } else {
                keepShell = true
            }
        } else {
            keepShell = focusedHierarchyLooksLikeTerminal(deepWalk: false)
        }

        state.update(
            Snapshot(
                hasTextSelection: selection,
                keepShellWithoutSelection: keepShell
            )
        )
    }

    private static func isElectronApp(_ app: NSRunningApplication) -> Bool {
        guard let bundleURL = app.bundleURL else { return false }
        let electronFramework = bundleURL
            .appendingPathComponent("Contents/Frameworks/Electron Framework.framework")
        return FileManager.default.fileExists(atPath: electronFramework.path)
    }

    private static func frontmostIsDedicatedTerminalApp() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        let haystack = [
            app.bundleIdentifier ?? "",
            app.localizedName ?? "",
            app.bundleURL?.lastPathComponent ?? "",
        ]
        .joined(separator: " ")
        .lowercased()
        return dedicatedAppHints.contains { haystack.contains($0) }
    }

    private static func focusedHierarchyLooksLikeTerminal(deepWalk: Bool) -> Bool {
        guard let focused = focusedElement() else { return false }

        let maxDepth = deepWalk ? 40 : 16
        var element = focused
        var depth = 0
        var axListDepth: Int?
        var foundTerminalLabel = false

        while depth < maxDepth {
            if elementLooksLikeTerminalPane(element) {
                foundTerminalLabel = true
                if terminalPanelLabel(stringAttribute(element, kAXDescriptionAttribute as CFString))
                    || terminalPanelLabel(stringAttribute(element, kAXTitleAttribute as CFString))
                {
                    return true
                }
            }

            let role = stringAttribute(element, kAXRoleAttribute as CFString) ?? ""
            if role == (kAXListRole as String) {
                axListDepth = depth
            }

            if role == "AXWebArea" || role == "AXHTMLContent" {
                if foundTerminalLabel, depth >= 15 {
                    return true
                }
                if let listDepth = axListDepth, depth - listDepth >= 20 {
                    return true
                }
                break
            }

            guard let parent = copyElement(element, kAXParentAttribute as CFString) else { break }
            element = parent
            depth += 1
        }

        return foundTerminalLabel
    }

    private static func isEditorContextFocused(deepWalk: Bool) -> Bool {
        guard let focused = focusedElement() else { return false }

        let focusedRole = stringAttribute(focused, kAXRoleAttribute as CFString) ?? ""
        if focusedRole == (kAXTextAreaRole as String) {
            if !elementLooksLikeTerminalPane(focused) {
                return true
            }
        }

        let maxDepth = deepWalk ? 24 : 12
        var element = focused
        for _ in 0..<maxDepth {
            if elementLooksLikeEditor(element) { return true }
            if elementLooksLikeTerminalPane(element) { return false }
            guard let parent = copyElement(element, kAXParentAttribute as CFString) else { break }
            element = parent
        }
        return false
    }

    private static func elementLooksLikeTerminalPane(_ element: AXUIElement) -> Bool {
        let keys: [CFString] = [
            kAXTitleAttribute as CFString,
            kAXDescriptionAttribute as CFString,
            kAXRoleDescriptionAttribute as CFString,
            kAXIdentifierAttribute as CFString,
            kAXHelpAttribute as CFString,
        ]
        for key in keys {
            let value = stringAttribute(element, key)
            if matchesAnyHint(value, paneHints) || terminalPanelLabel(value) {
                return true
            }
        }
        return false
    }

    private static func elementLooksLikeEditor(_ element: AXUIElement) -> Bool {
        let keys: [CFString] = [
            kAXTitleAttribute as CFString,
            kAXDescriptionAttribute as CFString,
            kAXRoleDescriptionAttribute as CFString,
            kAXIdentifierAttribute as CFString,
            kAXHelpAttribute as CFString,
        ]
        for key in keys {
            if matchesAnyHint(stringAttribute(element, key), editorHints) {
                return true
            }
        }
        return false
    }

    private static func terminalPanelLabel(_ raw: String?) -> Bool {
        guard let raw else { return false }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return value.hasPrefix("terminal")
            || value.contains("terminal ")
            || value.contains(", terminal")
    }

    private static func hasTextSelection() -> Bool {
        if let focused = focusedElement(), elementHasSelection(focused) {
            return true
        }

        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        if elementHasSelection(axApp) { return true }
        if let window = copyElement(axApp, kAXFocusedWindowAttribute as CFString),
           elementHasSelection(window)
        {
            return true
        
        return false
    }

    private static func elementHasSelection(_ element: AXUIElement) -> Bool {
        var selectedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedRef
        ) == .success,
           let selected = selectedRef as? String,
           !selected.isEmpty
        {
            return true
        }

        var rangeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &rangeRef
        ) == .success,
           let rangeRef,
           CFGetTypeID(rangeRef) == AXValueGetTypeID()
        {
            var range = CFRange(location: 0, length: 0)
            if AXValueGetValue(rangeRef as! AXValue, .cfRange, &range), range.length > 0 {
                return true
            }
        }
        return false
    }

    private static func focusedElement() -> AXUIElement? {
        if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier {
            let appElement = AXUIElementCreateApplication(pid)
            if let focused = copyElement(appElement, kAXFocusedUIElementAttribute as CFString) {
                return focused
            }
        }
        return copyElement(AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute as CFString)
    }

    private static func copyElement(_ root: AXUIElement, _ attribute: CFString) -> AXUIElement? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(root, attribute, &ref) == .success,
              let ref
        else { return nil }
        return (ref as! AXUIElement)
    }

    private static func matchesAnyHint(_ raw: String?, _ hints: [String]) -> Bool {
        guard let raw else { return false }
        let value = raw.lowercased()
        return hints.contains { value.contains($0) }
    }

    private static func stringAttribute(_ element: AXUIElement, _ key: CFString) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key, &value) == .success,
              let value
        else { return nil }
        return value as? String
    }
}

private struct Snapshot: Sendable {
    var hasTextSelection: Bool
    var keepShellWithoutSelection: Bool

    static let passthrough = Snapshot(hasTextSelection: false, keepShellWithoutSelection: false)
}

private final class ContextState: @unchecked Sendable {
    private let lock = NSLock()
    private var current = Snapshot.passthrough
    private var started = false

    var snapshot: Snapshot {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    func update(_ snapshot: Snapshot) {
        lock.lock()
        current = snapshot
        lock.unlock()
    }

    func startMonitoringIfNeeded(refresh: @escaping @Sendable () -> Void) {
        lock.lock()
        let already = started
        if !already { started = true }
        lock.unlock()
        guard !already else { return }

        DispatchQueue.main.async {
            refresh()
            Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
                refresh()
            }
        }
    }
}

private final class ElectronAccessibilityGate: @unchecked Sendable {
    private let lock = NSLock()
    private var enabledPIDs = Set<pid_t>()

    func enableIfNeeded(pid: pid_t) {
        lock.lock()
        let already = enabledPIDs.contains(pid)
        if !already {
            enabledPIDs.insert(pid)
        }
        lock.unlock()
        guard !already else { return }

        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetAttributeValue(
            appElement,
            "AXManualAccessibility" as CFString,
            kCFBooleanTrue
        )
    }
}

private final class MouseSelectionTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var downPoint: CGPoint?
    private var likelySelection = false

    var hasLikelySelection: Bool {
        lock.lock()
        defer { lock.unlock() }
        return likelySelection
    }

    func handle(type: CGEventType, event: CGEvent) {
        let point = event.location
        lock.lock()
        defer { lock.unlock() }

        switch type {
        case .leftMouseDown:
            downPoint = point
            let clickCount = event.getIntegerValueField(.mouseEventClickState)
            likelySelection = clickCount >= 2
        case .leftMouseDragged:
            guard let start = downPoint else {
                likelySelection = true
                return
            }
            let dx = point.x - start.x
            let dy = point.y - start.y
            if (dx * dx + dy * dy) >= 16 {
                likelySelection = true
            }
        case .leftMouseUp:
            downPoint = nil
        default:
            break
        }
    }
}
