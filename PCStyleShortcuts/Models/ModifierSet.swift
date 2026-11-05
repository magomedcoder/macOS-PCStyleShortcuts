import CoreGraphics
import Foundation

struct ModifierSet: OptionSet, Codable, Hashable, Sendable {
    let rawValue: Int

    static let control = ModifierSet(rawValue: 1 << 0)
    static let option = ModifierSet(rawValue: 1 << 1)
    static let shift = ModifierSet(rawValue: 1 << 2)
    static let command = ModifierSet(rawValue: 1 << 3)

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init(flags: CGEventFlags) {
        var set = ModifierSet()
        let raw = flags.rawValue
        if raw & CGEventFlags.maskControl.rawValue != 0 { set.insert(.control) }
        if raw & CGEventFlags.maskAlternate.rawValue != 0 { set.insert(.option) }
        if raw & CGEventFlags.maskShift.rawValue != 0 { set.insert(.shift) }
        if raw & CGEventFlags.maskCommand.rawValue != 0 { set.insert(.command) }
        self = set
    }

    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if contains(.control) { flags.insert(.maskControl) }
        if contains(.option) { flags.insert(.maskAlternate) }
        if contains(.shift) { flags.insert(.maskShift) }
        if contains(.command) { flags.insert(.maskCommand) }
        return flags
    }

    var displayString: String {
        var parts: [String] = []
        if contains(.control) { parts.append("⌃") }
        if contains(.option) { parts.append("⌥") }
        if contains(.shift) { parts.append("⇧") }
        if contains(.command) { parts.append("⌘") }
        return parts.joined()
    }
}
