import Carbon
import Foundation
import OSLog

enum InputSourceService {
    static func selectNext() {
        select(offset: 1)
    }

    static func selectPrevious() {
        select(offset: -1)
    }

    private static func select(offset: Int) {
        if Thread.isMainThread {
            performSelect(offset: offset)
        } else {
            DispatchQueue.main.async {
                performSelect(offset: offset)
            }
        }
    }

    private static func performSelect(offset: Int) {
        let sources = selectableSources()
        guard sources.count > 1 else {
            AppLog.remap.error("Input source switch skipped - found \(sources.count) selectable layout(s)")
            return
        }

        let current = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        let currentID = inputSourceID(current)
        let index = sources.firstIndex(where: { inputSourceID($0) == currentID }) ?? 0
        let count = sources.count
        let next = (index + offset % count + count) % count
        let status = TISSelectInputSource(sources[next])
        if status != noErr {
            AppLog.remap.error("TISSelectInputSource failed: \(status)")
        } else {
            AppLog.remap.info(
                "Input source \(currentID, privacy: .public) -> \(inputSourceID(sources[next]), privacy: .public)"
            )
        }
    }

    private static func selectableSources() -> [TISInputSource] {
        let keys = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String
        ] as CFDictionary
        guard let list = TISCreateInputSourceList(keys, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        return list.filter { source in
            guard boolProperty(source, kTISPropertyInputSourceIsEnabled),
                  boolProperty(source, kTISPropertyInputSourceIsSelectCapable)
            else { return false }
  
            let type = stringProperty(source, kTISPropertyInputSourceType)
            return type == (kTISTypeKeyboardLayout as String) || type == (kTISTypeKeyboardInputMode as String)
        }
    }

    private static func inputSourceID(_ source: TISInputSource) -> String {
        stringProperty(source, kTISPropertyInputSourceID)
    }

    private static func stringProperty(_ source: TISInputSource, _ key: CFString) -> String {
        guard let value = TISGetInputSourceProperty(source, key) else { return "" }
        return Unmanaged<CFString>.fromOpaque(value).takeUnretainedValue() as String
    }

    private static func boolProperty(_ source: TISInputSource, _ key: CFString) -> Bool {
        guard let value = TISGetInputSourceProperty(source, key) else { return false }
        return Unmanaged<CFBoolean>.fromOpaque(value).takeUnretainedValue() == kCFBooleanTrue
    }
}
