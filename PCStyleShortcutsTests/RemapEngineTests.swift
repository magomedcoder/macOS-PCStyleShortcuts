import CoreGraphics
import Testing
@testable import PCStyleShortcuts

@Suite("ModifierSet")
struct ModifierSetTests {
    @Test func roundTripsFlags() {
        let original: ModifierSet = [.control, .shift, .command]
        #expect(ModifierSet(flags: original.cgEventFlags) == original)
    }

    @Test func optionShiftFromMixedFlags() {
        var flags: CGEventFlags = [.maskAlternate, .maskShift]
        flags.insert(CGEventFlags(rawValue: 0x20))
        #expect(ModifierSet(flags: flags) == [.option, .shift])
    }
}

@Suite("PC Style defaults")
struct PCStyleDefaultsTests {
    @Test func copyPasteCutUndo() {
        let rules = ShortcutResolver.effectiveRules(overrides: [:])
        for key in [KeyCodes.c, KeyCodes.v, KeyCodes.x, KeyCodes.z] {
            let rule = rules.first { $0.fromKey == key && $0.fromMods == .control && $0.effect == .remap }
            #expect(rule?.toKey == key)
            #expect(rule?.toMods == .command)
        }
    }

    @Test func homeMapsToCommandLeft() {
        let rules = ShortcutResolver.effectiveRules(overrides: [:])
        let home = rules.first { $0.fromKey == KeyCodes.home && $0.fromMods == [] }
        #expect(home?.toKey == KeyCodes.leftArrow)
        #expect(home?.toMods == .command)
    }

    @Test func languageEffectsPresent() {
        let rules = ShortcutResolver.effectiveRules(overrides: [:])
        #expect(rules.contains {
            $0.effect == .nextInputSource
                && $0.fromKey == KeyCodes.modifiersOnly
                && $0.fromMods == [.option, .shift]
        })
        #expect(rules.contains {
            $0.effect == .previousInputSource
                && $0.fromKey == KeyCodes.modifiersOnly
                && $0.fromMods == [.option, .control]
        })
    }

    @Test func modifiersOnlyDisplay() {
        let chord = KeyChord(keyCode: KeyCodes.modifiersOnly, modifiers: [.option, .shift])
        #expect(chord.displayString == "⌥⇧")
        #expect(chord.isModifiersOnly)
    }

    @Test func browserOffByDefault() {
        let resolved = ShortcutResolver.resolved(overrides: [:])
        let browser = resolved.filter { $0.action.category == .browser }
        #expect(!browser.isEmpty)
        #expect(browser.allSatisfy { !$0.isEnabled })
    }
}

@Suite("Overrides")
struct OverrideTests {
    @Test func customFromChangesMatch() {
        var overrides: [String: ShortcutBindingOverride] = [:]
        overrides["editing.copy"] = ShortcutBindingOverride(
            isEnabled: true,
            from: KeyChord(keyCode: KeyCodes.c, modifiers: [.option, .shift])
        )
        let rules = ShortcutResolver.effectiveRules(overrides: overrides)
        #expect(rules.contains {
            $0.actionID == "editing.copy"
                && $0.fromKey == KeyCodes.c
                && $0.fromMods == [.option, .shift]
        })
        #expect(!rules.contains {
            $0.actionID == "editing.copy" && $0.fromMods == .control
        })
    }

    @Test func disableRemovesRule() {
        var overrides: [String: ShortcutBindingOverride] = [:]
        overrides["editing.copy"] = ShortcutBindingOverride(
            isEnabled: false,
            from: KeyChord(keyCode: KeyCodes.c, modifiers: .control)
        )
        let rules = ShortcutResolver.effectiveRules(overrides: overrides)
        #expect(!rules.contains { $0.actionID == "editing.copy" })
    }

    @Test func conflictDetection() {
        var overrides: [String: ShortcutBindingOverride] = [:]
        let shared = KeyChord(keyCode: KeyCodes.c, modifiers: .control)
        overrides["editing.copy"] = ShortcutBindingOverride(isEnabled: true, from: shared)
        overrides["editing.cut"] = ShortcutBindingOverride(isEnabled: true, from: shared)
        let resolved = ShortcutResolver.resolved(overrides: overrides)
        let copy = resolved.first { $0.id == "editing.copy" }
        let cut = resolved.first { $0.id == "editing.cut" }
        #expect(copy?.hasConflict == true)
        #expect(cut?.hasConflict == true)
    }

    @Test func resetClearsOverrides() {
        var settings = AppSettings.default
        settings.setBinding(
            actionID: "editing.copy",
            isEnabled: false,
            from: KeyChord(keyCode: KeyCodes.c, modifiers: .control)
        )
        #expect(!settings.bindingOverrides.isEmpty)
        settings.resetBindings()
        #expect(settings.bindingOverrides.isEmpty)
    }
}

@Suite("Engine")
struct EngineTests {
    @Test func applyLoadsOverrides() {
        let engine = RemapEngine()
        var settings = AppSettings.default
        settings.bindingOverrides["editing.copy"] = ShortcutBindingOverride(
            isEnabled: true,
            from: KeyChord(keyCode: KeyCodes.c, modifiers: .option)
        )
        engine.apply(settings: settings)
        let rule = engine.match(keyCode: KeyCodes.c, modifiers: .option)
        #expect(rule?.actionID == "editing.copy")
        #expect(engine.match(keyCode: KeyCodes.c, modifiers: .control) == nil)
    }
}
