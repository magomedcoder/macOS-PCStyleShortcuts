import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(String(localized: "PC Style Shortcuts"), systemImage: "keyboard.fill")
                .font(.title.weight(.semibold))

            Text(String(localized: "PC Style defaults are ready (Ctrl+C/V, Home/End, language switch, and more). Allow Accessibility once in System Settings, then customize keys in Settings."))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if model.isAccessibilityTrusted {
                Label(String(localized: "Accessibility granted"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text(String(localized: "Accessibility is required. Enable this app in System Settings -> Privacy & Security -> Accessibility."))
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button(String(localized: "Open Accessibility Settings")) {
                    model.requestAccessibility()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer(minLength: 12)

            HStack {
                Spacer()
                Button(String(localized: "Get Started")) {
                    model.completeOnboarding()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { model.refreshAccessibility() }
    }
}
