import SwiftUI

struct SettingsRootView: View {
    @Environment(AppModel.self) private var model

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    private var groups: [(ShortcutCategory, [ResolvedShortcut])] {
        ShortcutResolver.grouped(overrides: model.settings.bindingOverrides)
    }

    var body: some View {
        Form {
            Section(String(localized: "Remapping")) {
                Toggle(String(localized: "Enable key remapping"), isOn: Binding(
                    get: { model.settings.isEnabled },
                    set: { model.setEnabled($0) }
                ))
                .disabled(!model.isAccessibilityTrusted)

                Toggle(String(localized: "Smart terminal Ctrl+C/Z"), isOn: Binding(
                    get: { model.settings.smartTerminalShortcuts },
                    set: { value in
                        model.updateSettings { $0.smartTerminalShortcuts = value }
                    }
                ))
            }

            Section(String(localized: "Accessibility")) {
                LabeledContent(String(localized: "Status")) {
                    Text(model.isAccessibilityTrusted
                         ? String(localized: "Granted")
                         : String(localized: "Not granted"))
                        .foregroundStyle(model.isAccessibilityTrusted ? .green : .orange)
                }
                Button(String(localized: "Open Accessibility Settings")) {
                    model.requestAccessibility()
                }
                .disabled(model.isAccessibilityTrusted)
            }

            Section(String(localized: "Startup")) {
                Toggle(String(localized: "Launch at Login"), isOn: Binding(
                    get: { model.launchAtLoginStatus == .enabled },
                    set: { model.setLaunchAtLogin($0) }
                ))
                LabeledContent(String(localized: "Login Item")) {
                    Text(loginItemLabel).foregroundStyle(.secondary)
                }
                if model.launchAtLoginStatus == .requiresApproval {
                    Button(String(localized: "Open Login Items Settings")) {
                        LaunchAtLoginService.openLoginItemsSettings()
                    }
                }
            }

            Section(String(localized: "Appearance")) {
                Toggle(String(localized: "Show Dock icon"), isOn: Binding(
                    get: { model.settings.showDockIcon },
                    set: { value in
                        model.updateSettings { $0.showDockIcon = value }
                    }
                ))
            }

            Section {
                Button(String(localized: "Reset")) {
                    model.resetAllShortcuts()
                }
            } header: {
                Text(String(localized: "Keys"))
            }

            ForEach(groups, id: \.0) { category, rows in
                Section(category.title) {
                    ForEach(rows) { item in
                        ShortcutRow(item: item)
                    }
                }
            }

            Section(String(localized: "About")) {
                LabeledContent(String(localized: "Version")) {
                    Text(version)
                }
            }
        }
        .formStyle(.grouped)
        .padding(12)
        .frame(minWidth: 720, minHeight: 520)
    }

    private var loginItemLabel: String {
        switch model.launchAtLoginStatus {
        case .enabled: String(localized: "Registered")
        case .requiresApproval: String(localized: "Requires Approval")
        case .notRegistered: String(localized: "Not Registered")
        case .unavailable: String(localized: "Unavailable")
        }
    }
}

private struct ShortcutRow: View {
    @Environment(AppModel.self) private var model
    let item: ResolvedShortcut

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.action.localizedTitle)
                    if item.isCustomized {
                        Text(String(localized: "Custom"))
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())
                    }
                    if item.hasConflict {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .help(String(localized: "Conflicts with another key"))
                    }
                }
                Text(String(localized: "Performs: \(item.performsDescription)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            ShortcutRecorderView(
                chord: Binding(
                    get: { item.from },
                    set: { model.setShortcutFrom(actionID: item.id, from: $0) }
                )
            )
            .disabled(!item.isEnabled)

            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { model.setShortcutEnabled(actionID: item.id, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(.vertical, 2)
    }
}
