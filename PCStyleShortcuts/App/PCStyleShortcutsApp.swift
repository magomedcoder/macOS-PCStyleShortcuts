import SwiftUI

@main
struct PCStyleShortcutsApp: App {
    @State private var model = AppModel.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(model)
        } label: {
            Image(systemName: model.menuBarSymbolName)
                .accessibilityLabel(Text("PC Style Shortcuts"))
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsRootView().environment(model)
        }
        .defaultSize(width: 760, height: 640)

        Window(String(localized: "Welcome"), id: "onboarding") {
            OnboardingView().environment(model).frame(width: 520, height: 360)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 360)
        .defaultLaunchBehavior(model.showOnboarding ? .presented : .suppressed)
    }
}
