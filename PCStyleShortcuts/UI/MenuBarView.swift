import SwiftUI

struct MenuBarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        if !model.isAccessibilityTrusted {
            Button(String(localized: "Grant Accessibility...")) {
                model.requestAccessibility()
            }
            Divider()
        }

        Toggle(String(localized: "Enable key remapping"), isOn: Binding(
            get: { model.settings.isEnabled },
            set: { model.setEnabled($0) }
        ))
        .disabled(!model.isAccessibilityTrusted)

        if let status = model.statusMessage {
            Text(status).foregroundStyle(.secondary)
        } else {
            Text(statusLine).foregroundStyle(.secondary)
        }

        Divider()

        Button(String(localized: "Settings...")) {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button(String(localized: "Quit PC Style Shortcuts")) {
            model.quit()
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private var statusLine: String {
        if !model.isAccessibilityTrusted {
            return String(localized: "Needs Accessibility")
        }
        if model.settings.isEnabled {
            return model.isTapRunning
                ? String(localized: "Active")
                : String(localized: "Enabled tap starting...")
        }
        return String(localized: "Disabled")
    }
}
