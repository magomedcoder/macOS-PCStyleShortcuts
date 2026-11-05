import Foundation
import OSLog

nonisolated final class SettingsStore: @unchecked Sendable {
    static let shared = SettingsStore()

    private let defaultsKey = "app.settings.v2"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()
    private var cached: AppSettings

    private init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let settings = try? decoder.decode(AppSettings.self, from: data) {
            cached = settings
        } else {
            cached = .default
            persistLocked(cached)
        }
    }

    func load() -> AppSettings {
        lock.lock()
        defer { lock.unlock() }
        return cached
    }

    func save(_ settings: AppSettings) {
        lock.lock()
        defer { lock.unlock() }
        cached = settings
        persistLocked(settings)
    }

    private func persistLocked(_ settings: AppSettings) {
        do {
            let data = try encoder.encode(settings)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            AppLog.general.error("Failed to persist settings: \(error.localizedDescription, privacy: .public)")
        }
    }
}
