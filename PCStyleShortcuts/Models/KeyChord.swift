import Foundation

struct KeyChord: Codable, Hashable, Sendable, Equatable {
    var keyCode: UInt16
    var modifiers: ModifierSet

    init(keyCode: UInt16, modifiers: ModifierSet = []) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    var isModifiersOnly: Bool {
        keyCode == KeyCodes.modifiersOnly
    }

    var displayString: String {
        let mods = modifiers.displayString
        if isModifiersOnly {
            return mods.isEmpty ? "?" : mods
        }
        let key = KeyCodes.displayName(for: keyCode)
        
        return mods.isEmpty ? key : mods + key
    }
}
