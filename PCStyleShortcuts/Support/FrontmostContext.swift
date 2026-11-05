import ApplicationServices
import AppKit

enum FrontmostContext {
    private static let selectionGatedActionIDs: Set<String> = [ "editing.copy", "editing.cut", "editing.undo"]
    private static let paneHints = ["terminal", "console"]
    private static let dedicatedAppHints = [ "terminal", "iterm", "kitty", "alacritty", "wezterm", "warp", "hyper", "ghostty"]
    private static let terminalContextTTL: CFTimeInterval = 0.1
    private static let terminalContextCache = TerminalContextCache()

    static func shouldKeepShellShortcut(actionID: String) -> Bool {
        guard selectionGatedActionIDs.contains(actionID) else { return false }
        if hasTextSelection() { return false }
        return isTerminalContextFocused()
    }

    private static func isTerminalContextFocused() -> Bool {
        let now = CFAbsoluteTimeGetCurrent()
        if let cached = terminalContextCache.getIfFresh(now: now, ttl: terminalContextTTL) {
            return cached
        }
        let value = focusedHierarchyLooksLikeTerminal() || frontmostIsDedicatedTerminalApp()
        terminalContextCache.set(value, at: now)
        return value
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

    private static func focusedHierarchyLooksLikeTerminal() -> Bool {
        guard var element = focusedElement() else { return false }
        for _ in 0..<16 {
            if elementLooksLikeTerminalPane(element) { return true }
            var parentRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(
                element,
                kAXParentAttribute as CFString,
                &parentRef
            ) == .success,
                let parentRef
            else { break }
            element = parentRef as! AXUIElement
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
            if matchesAnyHint(stringAttribute(element, key), paneHints) {
                return true
            }
        }
        return false
    }

    private static func hasTextSelection() -> Bool {
        guard let focused = focusedElement() else { return false }
        var selectedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            focused,
            kAXSelectedTextAttribute as CFString,
            &selectedRef
        ) == .success,
            let selectedRef
        else { return false }
        let selected = selectedRef as? String ?? ""
        return !selected.isEmpty
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
        guard AXUIElementCopyAttributeValue(root, attribute, &ref) == .success, let ref
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

private final class TerminalContextCache: @unchecked Sendable {
    private let lock = NSLock()
    private var cached: (at: CFAbsoluteTime, value: Bool)?

    func getIfFresh(now: CFAbsoluteTime, ttl: CFTimeInterval) -> Bool? {
        lock.lock()
        defer { lock.unlock() }
        guard let cached, now - cached.at < ttl else { return nil }
        return cached.value
    }

    func set(_ value: Bool, at time: CFAbsoluteTime) {
        lock.lock()
        cached = (time, value)
        lock.unlock()
    }
}
