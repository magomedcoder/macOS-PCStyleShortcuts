import Foundation

enum ShortcutCategory: String, CaseIterable, Sendable, Identifiable {
    case language
    case editing
    case navigation
    case window
    case browser

    var id: String { rawValue }

    var title: String {
        switch self {
        case .language: String(localized: "Language")
        case .editing: String(localized: "Editing")
        case .navigation: String(localized: "Navigation")
        case .window: String(localized: "Window")
        case .browser: String(localized: "Browser")
        }
    }
}

enum ShortcutEffect: String, Codable, Sendable, Equatable {
    case remap
    case nextInputSource
    case previousInputSource
}

struct CatalogAction: Sendable, Identifiable, Equatable {
    let id: String
    let category: ShortcutCategory
    let title: String
    let defaultFrom: KeyChord
    let defaultTo: KeyChord
    let effect: ShortcutEffect
    let defaultEnabled: Bool

    var localizedTitle: String {
        String(localized: String.LocalizationValue(title))
    }
}

enum ShortcutCatalog {
    static let all: [CatalogAction] = language + editing + navigation + window + browser

    static func action(id: String) -> CatalogAction? {
        all.first { $0.id == id }
    }

    private static let language: [CatalogAction] = [
        action(
            "language.next",
            .language,
            "Next input source",
            from: KeyChord(keyCode: KeyCodes.modifiersOnly, modifiers: [.option, .shift]),
            to: KeyChord(keyCode: KeyCodes.modifiersOnly, modifiers: [.option, .shift]),
            effect: .nextInputSource,
            enabled: true
        ),
        action(
            "language.previous",
            .language,
            "Previous input source",
            from: KeyChord(keyCode: KeyCodes.modifiersOnly, modifiers: [.option, .control]),
            to: KeyChord(keyCode: KeyCodes.modifiersOnly, modifiers: [.option, .control]),
            effect: .previousInputSource,
            enabled: true
        ),
    ]

    private static let editing: [CatalogAction] = [
        edit("editing.copy", title: "Copy", key: KeyCodes.c),
        edit("editing.paste", title: "Paste", key: KeyCodes.v),
        edit("editing.cut", title: "Cut", key: KeyCodes.x),
        edit("editing.undo", title: "Undo", key: KeyCodes.z),
        action("editing.redo", .editing, "Redo", from: KeyChord(keyCode: KeyCodes.z, modifiers: [.control, .shift]), to: KeyChord(keyCode: KeyCodes.z, modifiers: [.command, .shift])),
        edit("editing.selectAll", title: "Select All", key: KeyCodes.a),
        edit("editing.save", title: "Save", key: KeyCodes.s),
        edit("editing.find", title: "Find", key: KeyCodes.f),
        edit("editing.findNext", title: "Find Next", key: KeyCodes.g),
        edit("editing.bold", title: "Bold", key: KeyCodes.b, enabled: false),
        edit("editing.italic", title: "Italic", key: KeyCodes.i, enabled: false),
        edit("editing.underline", title: "Underline", key: KeyCodes.u, enabled: false),
        edit("editing.print", title: "Print", key: KeyCodes.p, enabled: false),
    ]

    private static let navigation: [CatalogAction] = [
        action("navigation.lineStart", .navigation, "Line start", from: KeyChord(keyCode: KeyCodes.home), to: KeyChord(keyCode: KeyCodes.leftArrow, modifiers: .command)),
        action("navigation.lineEnd", .navigation, "Line end", from: KeyChord(keyCode: KeyCodes.end), to: KeyChord(keyCode: KeyCodes.rightArrow, modifiers: .command)),
        action("navigation.selectLineStart", .navigation, "Select to line start", from: KeyChord(keyCode: KeyCodes.home, modifiers: .shift), to: KeyChord(keyCode: KeyCodes.leftArrow, modifiers: [.command, .shift])),
        action("navigation.selectLineEnd", .navigation, "Select to line end", from: KeyChord(keyCode: KeyCodes.end, modifiers: .shift), to: KeyChord(keyCode: KeyCodes.rightArrow, modifiers: [.command, .shift])),
        action("navigation.docStart", .navigation, "Document start", from: KeyChord(keyCode: KeyCodes.home, modifiers: .control), to: KeyChord(keyCode: KeyCodes.upArrow, modifiers: .command)),
        action("navigation.docEnd", .navigation, "Document end", from: KeyChord(keyCode: KeyCodes.end, modifiers: .control), to: KeyChord(keyCode: KeyCodes.downArrow, modifiers: .command)),
        action("navigation.selectDocStart", .navigation, "Select to document start", from: KeyChord(keyCode: KeyCodes.home, modifiers: [.control, .shift]), to: KeyChord(keyCode: KeyCodes.upArrow, modifiers: [.command, .shift])),
        action("navigation.selectDocEnd", .navigation, "Select to document end", from: KeyChord(keyCode: KeyCodes.end, modifiers: [.control, .shift]), to: KeyChord(keyCode: KeyCodes.downArrow, modifiers: [.command, .shift])),
        action("navigation.wordLeft", .navigation, "Word left", from: KeyChord(keyCode: KeyCodes.leftArrow, modifiers: .control), to: KeyChord(keyCode: KeyCodes.leftArrow, modifiers: .option)),
        action("navigation.wordRight", .navigation, "Word right", from: KeyChord(keyCode: KeyCodes.rightArrow, modifiers: .control), to: KeyChord(keyCode: KeyCodes.rightArrow, modifiers: .option)),
        action("navigation.selectWordLeft", .navigation, "Select word left", from: KeyChord(keyCode: KeyCodes.leftArrow, modifiers: [.control, .shift]),  to: KeyChord(keyCode: KeyCodes.leftArrow, modifiers: [.option, .shift])),
        action("navigation.selectWordRight", .navigation, "Select word right", from: KeyChord(keyCode: KeyCodes.rightArrow, modifiers: [.control, .shift]), to: KeyChord(keyCode: KeyCodes.rightArrow, modifiers: [.option, .shift])),
        action("navigation.deleteWordBackward", .navigation, "Delete word backward", from: KeyChord(keyCode: KeyCodes.delete, modifiers: .control),  to: KeyChord(keyCode: KeyCodes.delete, modifiers: .option)),
        action("navigation.deleteWordForward", .navigation, "Delete word forward", from: KeyChord(keyCode: KeyCodes.forwardDelete, modifiers: .control), to: KeyChord(keyCode: KeyCodes.forwardDelete, modifiers: .option)),
    ]

    private static let window: [CatalogAction] = [
        edit("window.close", category: .window, title: "Close tab / window", key: KeyCodes.w),
        edit("window.newTab", category: .window, title: "New tab", key: KeyCodes.t),
        edit("window.newWindow", category: .window, title: "New window", key: KeyCodes.n),
        action( "window.switchApp", .window, "Switch apps", from: KeyChord(keyCode: KeyCodes.tab, modifiers: .option), to: KeyChord(keyCode: KeyCodes.tab, modifiers: .command), enabled: false),
    ]

    private static let browser: [CatalogAction] = [
        edit("browser.refresh", category: .browser, title: "Refresh", key: KeyCodes.r, enabled: false),
        edit("browser.addressBar", category: .browser, title: "Focus address bar", key: KeyCodes.l, enabled: false),
        action("browser.zoomIn", .browser, "Zoom in", from: KeyChord(keyCode: KeyCodes.equal, modifiers: .control), to: KeyChord(keyCode: KeyCodes.equal, modifiers: .command), enabled: false),
        action("browser.zoomOut", .browser, "Zoom out", from: KeyChord(keyCode: KeyCodes.minus, modifiers: .control), to: KeyChord(keyCode: KeyCodes.minus, modifiers: .command), enabled: false),
    ]

    private static func edit(
        _ id: String,
        category: ShortcutCategory = .editing,
        title: String,
        key: UInt16,
        enabled: Bool = true
    ) -> CatalogAction {
        action(
            id,
            category,
            title,
            from: KeyChord(keyCode: key, modifiers: .control),
            to: KeyChord(keyCode: key, modifiers: .command),
            enabled: enabled
        )
    }

    private static func action(
        _ id: String,
        _ category: ShortcutCategory,
        _ title: String,
        from: KeyChord,
        to: KeyChord,
        effect: ShortcutEffect = .remap,
        enabled: Bool = true
    ) -> CatalogAction {
        CatalogAction(
            id: id,
            category: category,
            title: title,
            defaultFrom: from,
            defaultTo: to,
            effect: effect,
            defaultEnabled: enabled
        )
    }
}

struct RemapRule: Sendable, Equatable {
    let actionID: String
    let fromKey: UInt16
    let fromMods: ModifierSet
    let toKey: UInt16
    let toMods: ModifierSet
    let effect: ShortcutEffect
}
