import AppKit
import CoreGraphics
import OSLog

nonisolated final class RemapEngine: @unchecked Sendable {
    private let lock = NSLock()
    private var isEnabled = true
    private var smartTerminalShortcuts = true
    private var rules: [RemapRule] = []
    private var previousModifiers: ModifierSet = []
    private var modifiersOnlyConsumed = false

    func apply(settings: AppSettings) {
        lock.lock()
        defer { lock.unlock() }
        isEnabled = settings.isEnabled
        smartTerminalShortcuts = settings.smartTerminalShortcuts
        rules = ShortcutResolver.effectiveRules(overrides: settings.bindingOverrides)
    }

    func setEnabled(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        isEnabled = enabled
    }

    func match(keyCode: UInt16, modifiers: ModifierSet) -> RemapRule? {
        lock.lock()
        defer { lock.unlock() }
        return rules.first { $0.fromKey == keyCode && $0.fromMods == modifiers }
    }

    func handle(event: CGEvent, type: CGEventType) -> CGEvent? {
        if type == .flagsChanged {
            return handleFlagsChanged(event)
        }

        guard type == .keyDown || type == .keyUp else {
            return event
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = ModifierSet(flags: event.flags)

        lock.lock()
        let enabled = isEnabled
        let smartTerminal = smartTerminalShortcuts
        let currentRules = rules
        lock.unlock()

        guard enabled else { return event }

        guard let rule = currentRules.first(where: {
            $0.fromKey == keyCode && $0.fromKey != KeyCodes.modifiersOnly && $0.fromMods == modifiers
        }) else {
            return event
        }

        if smartTerminal,
           FrontmostContext.shouldKeepShellShortcut(actionID: rule.actionID) {
            AppLog.remap.debug("Shell passthrough \(rule.actionID, privacy: .public)")
            return event
        }

        switch rule.effect {
        case .nextInputSource:
            if type == .keyDown {
                InputSourceService.selectNext()
            }
            
            return nil
        case .previousInputSource:
            if type == .keyDown {
                InputSourceService.selectPrevious()
            }
            
            return nil
        case .remap:
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(rule.toKey))
            var flags = event.flags
            flags.remove(.maskControl)
            flags.remove(.maskAlternate)
            flags.remove(.maskShift)
            flags.remove(.maskCommand)
            flags.formUnion(rule.toMods.cgEventFlags)
            event.flags = flags
            AppLog.remap.debug("Remap \(rule.actionID, privacy: .public)")
            return event
        }
    }

    private func handleFlagsChanged(_ event: CGEvent) -> CGEvent? {
        let current = ModifierSet(flags: event.flags)

        lock.lock()
        let previous = previousModifiers
        previousModifiers = current
        let enabled = isEnabled
        let currentRules = rules

        let holdingMatchedChord = currentRules.contains {
            $0.fromKey == KeyCodes.modifiersOnly && $0.fromMods == current
        }
        if !holdingMatchedChord {
            modifiersOnlyConsumed = false
        }

        guard enabled, current != previous, !modifiersOnlyConsumed else {
            lock.unlock()
            return event
        }

        guard let rule = currentRules.first(where: {
            $0.fromKey == KeyCodes.modifiersOnly && $0.fromMods == current
        }) else {
            lock.unlock()
            return event
        }

        modifiersOnlyConsumed = true
        lock.unlock()

        switch rule.effect {
        case .nextInputSource:
            InputSourceService.selectNext()
        case .previousInputSource:
            InputSourceService.selectPrevious()
        case .remap:
            break
        }

        return event
    }
}
