import Foundation

struct ShortcutBindingOverride: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var from: KeyChord
}

struct ResolvedShortcut: Identifiable, Sendable, Equatable {
    var id: String { action.id }
    let action: CatalogAction
    let isEnabled: Bool
    let from: KeyChord
    let to: KeyChord

    var isCustomized: Bool {
        isEnabled != action.defaultEnabled || from != action.defaultFrom
    }

    var hasConflict: Bool = false

    var performsDescription: String {
        switch action.effect {
        case .remap:
            return to.displayString
        case .nextInputSource:
            return String(localized: "Next input source")
        case .previousInputSource:
            return String(localized: "Previous input source")
        }
    }
}

enum ShortcutResolver {
    static func resolved(
        overrides: [String: ShortcutBindingOverride]
    ) -> [ResolvedShortcut] {
        var byFrom: [KeyChord: [String]] = [:]
        var items: [ResolvedShortcut] = ShortcutCatalog.all.map { action in
            let override = overrides[action.id]
            let item = ResolvedShortcut(
                action: action,
                isEnabled: override?.isEnabled ?? action.defaultEnabled,
                from: override?.from ?? action.defaultFrom,
                to: action.defaultTo
            )
            if item.isEnabled {
                byFrom[item.from, default: []].append(item.id)
            }
            return item
        }

        let conflictIDs = Set(byFrom.values.filter { $0.count > 1 }.joined())
        for index in items.indices {
            items[index].hasConflict = conflictIDs.contains(items[index].id)
        }
        return items
    }

    static func effectiveRules(
        overrides: [String: ShortcutBindingOverride]
    ) -> [RemapRule] {
        resolved(overrides: overrides)
            .filter(\.isEnabled)
            .map {
                RemapRule(
                    actionID: $0.id,
                    fromKey: $0.from.keyCode,
                    fromMods: $0.from.modifiers,
                    toKey: $0.to.keyCode,
                    toMods: $0.to.modifiers,
                    effect: $0.action.effect
                )
            }
    }

    static func grouped(
        overrides: [String: ShortcutBindingOverride]
    ) -> [(ShortcutCategory, [ResolvedShortcut])] {
        let items = resolved(overrides: overrides)
        return ShortcutCategory.allCases.compactMap { category in
            let rows = items.filter { $0.action.category == category }
            return rows.isEmpty ? nil : (category, rows)
        }
    }
}
