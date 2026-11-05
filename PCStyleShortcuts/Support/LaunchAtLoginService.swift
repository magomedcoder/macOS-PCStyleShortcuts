import Foundation
import OSLog
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case enabled
    case requiresApproval
    case notRegistered
    case unavailable
}

enum LaunchAtLoginService {
    static var status: LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notRegistered:
            return .notRegistered
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> LaunchAtLoginStatus {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            AppLog.general.error("Launch at login failed: \(error.localizedDescription, privacy: .public)")
        }
        return status
    }

    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
