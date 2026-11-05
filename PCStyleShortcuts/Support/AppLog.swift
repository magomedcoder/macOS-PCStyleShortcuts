import OSLog

enum AppLog {
    static let general = Logger(subsystem: "ru.magomedcoder.PCStyleShortcuts", category: "general")
    static let tap = Logger(subsystem: "ru.magomedcoder.PCStyleShortcuts", category: "event-tap")
    static let remap = Logger(subsystem: "ru.magomedcoder.PCStyleShortcuts", category: "remap")
    static let permissions = Logger(subsystem: "ru.magomedcoder.PCStyleShortcuts", category: "permissions")
}
