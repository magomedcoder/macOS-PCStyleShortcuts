import Foundation

struct AppSettings: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var showDockIcon: Bool
    var hasCompletedOnboarding: Bool
    var smartTerminalShortcuts: Bool
    var bindingOverrides: [String: ShortcutBindingOverride]

    static var `default`: AppSettings {
        AppSettings(
            isEnabled: true,
            showDockIcon: false,
            hasCompletedOnboarding: false,
            smartTerminalShortcuts: true,
            bindingOverrides: [:]
        )
    }

    enum CodingKeys: String, CodingKey {
        case isEnabled, showDockIcon, hasCompletedOnboarding
        case smartTerminalShortcuts, bindingOverrides
    }

    init(
        isEnabled: Bool,
        showDockIcon: Bool,
        hasCompletedOnboarding: Bool,
        smartTerminalShortcuts: Bool,
        bindingOverrides: [String: ShortcutBindingOverride]
    ) {
        self.isEnabled = isEnabled
        self.showDockIcon = showDockIcon
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.smartTerminalShortcuts = smartTerminalShortcuts
        self.bindingOverrides = bindingOverrides
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        showDockIcon = try container.decodeIfPresent(Bool.self, forKey: .showDockIcon) ?? false
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        smartTerminalShortcuts = try container.decodeIfPresent(Bool.self, forKey: .smartTerminalShortcuts) ?? true
        bindingOverrides = try container.decodeIfPresent([String: ShortcutBindingOverride].self, forKey: .bindingOverrides) ?? [:]
    }

    mutating func setBinding(actionID: String, isEnabled: Bool, from: KeyChord) {
        guard let action = ShortcutCatalog.action(id: actionID) else { return }
        if isEnabled == action.defaultEnabled, from == action.defaultFrom {
            bindingOverrides.removeValue(forKey: actionID)
        } else {
            bindingOverrides[actionID] = ShortcutBindingOverride(isEnabled: isEnabled, from: from)
        }
    }

    mutating func resetBindings() {
        bindingOverrides.removeAll()
    }
}
