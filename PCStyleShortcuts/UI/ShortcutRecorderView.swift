import AppKit
import SwiftUI

struct ShortcutRecorderView: View {
    @Binding var chord: KeyChord

    @State private var isRecording = false

    var body: some View {
        Button {
            isRecording = true
        } label: {
            Text(isRecording ? String(localized: "Listening...") : chord.displayString)
                .frame(minWidth: 88, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(String(localized: "Click then press a new key combination"))
        .background(
            ShortcutRecorderRepresentable(isRecording: $isRecording) { captured in
                chord = captured
                isRecording = false
            }
        )
    }
}

private struct ShortcutRecorderRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onCapture: (KeyChord) -> Void

    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.onCapture = onCapture
        return view
    }

    func updateNSView(_ nsView: RecorderView, context: Context) {
        nsView.onCapture = onCapture
        nsView.isRecording = isRecording
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class RecorderView: NSView {
        var onCapture: ((KeyChord) -> Void)?
        var isRecording = false
        private var lastModifiers: ModifierSet = []

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            guard isRecording else { return }
            let keyCode = UInt16(event.keyCode)
            let pureModifiers: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
            guard !pureModifiers.contains(keyCode) else { return }

            onCapture?(KeyChord(keyCode: keyCode, modifiers: modifierSet(from: event.modifierFlags)))
        }

        override func flagsChanged(with event: NSEvent) {
            guard isRecording else { return }
            let mods = modifierSet(from: event.modifierFlags)
            defer { lastModifiers = mods }

            guard mods.rawValue.nonzeroBitCount >= 2, mods != lastModifiers, mods.isSuperset(of: lastModifiers) || lastModifiers.isEmpty
            else { return }

            onCapture?(KeyChord(keyCode: KeyCodes.modifiersOnly, modifiers: mods))
        }

        private func modifierSet(from flags: NSEvent.ModifierFlags) -> ModifierSet {
            var mods = ModifierSet()
            if flags.contains(.control) { mods.insert(.control) }
            if flags.contains(.option) { mods.insert(.option) }
            if flags.contains(.shift) { mods.insert(.shift) }
            if flags.contains(.command) { mods.insert(.command) }
            return mods
        }
    }
}
