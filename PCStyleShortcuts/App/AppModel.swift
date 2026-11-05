import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class AppModel {
    static let shared = AppModel()

    private(set) var settings: AppSettings
    private(set) var isAccessibilityTrusted: Bool
    private(set) var isTapRunning = false
    private(set) var launchAtLoginStatus: LaunchAtLoginStatus
    private(set) var statusMessage: String?
    var showOnboarding: Bool

    private let engine: RemapEngine
    private let eventTap: EventTapManager

    private var accessibilityTimer: Timer?
    private var statusClearTask: Task<Void, Never>?
    private var workspaceObservers: [NSObjectProtocol] = []

    private init() {
        let engine = RemapEngine()
        self.engine = engine
        self.eventTap = EventTapManager(engine: engine)

        let loaded = SettingsStore.shared.load()
        settings = loaded
        isAccessibilityTrusted = AccessibilityPermission.isTrusted
        launchAtLoginStatus = LaunchAtLoginService.status
        showOnboarding = !loaded.hasCompletedOnboarding

        engine.apply(settings: loaded)

        applyDockPolicy()
        startAccessibilityPolling()
        registerWorkspaceNotifications()
        syncTapWithState()
    }

    var menuBarSymbolName: String {
        if !isAccessibilityTrusted {
            return "keyboard.badge.ellipsis"
        }

        return settings.isEnabled ? "keyboard.fill" : "keyboard"
    }

    func setEnabled(_ enabled: Bool) {
        guard settings.isEnabled != enabled else { return }
        mutateSettings { $0.isEnabled = enabled }
        engine.setEnabled(enabled)
        syncTapWithState()
        flashStatus(
            enabled
                ? String(localized: "Key remapping enabled")
                : String(localized: "Key remapping disabled")
        )
    }

    func refreshAccessibility() {
        let trusted = AccessibilityPermission.isTrusted
        let changed = trusted != isAccessibilityTrusted
        isAccessibilityTrusted = trusted
        if changed {
            syncTapWithState()
            if trusted {
                flashStatus(String(localized: "Accessibility granted"))
            }
        }
    }

    func requestAccessibility() {
        guard !isAccessibilityTrusted else { return }
        _ = AccessibilityPermission.requestTrust()
        AccessibilityPermission.openSystemSettings()
        refreshAccessibility()
    }

    func completeOnboarding() {
        mutateSettings { $0.hasCompletedOnboarding = true }
        showOnboarding = false
        refreshAccessibility()
        if !isAccessibilityTrusted {
            requestAccessibility()
        }
        setEnabled(true)
    }

    func updateSettings(_ body: (inout AppSettings) -> Void) {
        mutateSettings(body)
        engine.apply(settings: settings)
        applyDockPolicy()
        syncTapWithState()
        launchAtLoginStatus = LaunchAtLoginService.status
    }

    func setShortcutEnabled(actionID: String, enabled: Bool) {
        updateSettings { settings in
            let current = settings.bindingOverrides[actionID]
            let action = ShortcutCatalog.action(id: actionID)
            let from = current?.from ?? action?.defaultFrom ?? KeyChord(keyCode: 0)
            settings.setBinding(actionID: actionID, isEnabled: enabled, from: from)
        }
    }

    func setShortcutFrom(actionID: String, from: KeyChord) {
        updateSettings { settings in
            let current = settings.bindingOverrides[actionID]
            let action = ShortcutCatalog.action(id: actionID)
            let enabled = current?.isEnabled ?? action?.defaultEnabled ?? true
            settings.setBinding(actionID: actionID, isEnabled: enabled, from: from)
        }
    }

    func resetAllShortcuts() {
        updateSettings { $0.resetBindings() }
        flashStatus(String(localized: "Reset to PC Style defaults"))
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginStatus = LaunchAtLoginService.setEnabled(enabled)
        if launchAtLoginStatus == .requiresApproval {
            flashStatus(String(localized: "Approve Login Item in System Settings"))
            LaunchAtLoginService.openLoginItemsSettings()
        }
    }

    func quit() {
        eventTap.stop()
        SettingsStore.shared.save(settings)
        NSApp.terminate(nil)
    }

    private func mutateSettings(_ body: (inout AppSettings) -> Void) {
        var copy = settings
        body(&copy)
        settings = copy
        SettingsStore.shared.save(copy)
    }

    private func syncTapWithState() {
        let shouldRun = settings.isEnabled && isAccessibilityTrusted
        if shouldRun {
            if !eventTap.isRunning {
                eventTap.start()
            }
        } else if eventTap.isRunning {
            eventTap.stop()
        }
        
        isTapRunning = eventTap.isRunning
    }

    private func applyDockPolicy() {
        let policy: NSApplication.ActivationPolicy = settings.showDockIcon ? .regular : .accessory
        _ = NSApp.setActivationPolicy(policy)
    }

    private func startAccessibilityPolling() {
        accessibilityTimer?.invalidate()
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.refreshAccessibility()
                self.isTapRunning = self.eventTap.isRunning
            }
        }
    }

    private func registerWorkspaceNotifications() {
        let center = NSWorkspace.shared.notificationCenter

        let wake = center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { @Sendable [weak self] _ in
            Task { @MainActor in
                self?.handleWake()
            }
        }

        let sleep = center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { @Sendable [weak self] _ in
            Task { @MainActor in
                self?.eventTap.stop()
                self?.isTapRunning = false
            }
        }

        let session = center.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { @Sendable [weak self] _ in
            Task { @MainActor in
                self?.handleWake()
            }
        }

        workspaceObservers = [wake, sleep, session]

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { @Sendable [weak self] _ in
            Task { @MainActor in
                self?.eventTap.stop()
            }
        }
    }

    private func handleWake() {
        refreshAccessibility()
        if settings.isEnabled && isAccessibilityTrusted {
            eventTap.restart()
            isTapRunning = eventTap.isRunning
        }
    }

    private func flashStatus(_ message: String) {
        statusMessage = message
        statusClearTask?.cancel()
        statusClearTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                statusMessage = nil
            }
        }
    }
}
