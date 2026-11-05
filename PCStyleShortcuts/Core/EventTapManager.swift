import CoreGraphics
import Foundation
import OSLog

nonisolated final class EventTapManager: @unchecked Sendable {
    private let engine: RemapEngine
    private let lock = NSLock()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    private var thread: Thread?
    private var wantsRunning = false

    init(engine: RemapEngine) {
        self.engine = engine
    }

    var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return eventTap != nil
    }

    func start() {
        lock.lock()
        wantsRunning = true
        if thread != nil {
            lock.unlock()
            return
        }
        lock.unlock()

        let thread = Thread { [weak self] in
            self?.threadMain()
        }
        thread.name = "PCStyleShortcuts.EventTap"
        thread.qualityOfService = .userInteractive

        lock.lock()
        self.thread = thread
        lock.unlock()

        thread.start()
        AppLog.tap.info("Event tap thread started")
    }

    func stop() {
        lock.lock()
        wantsRunning = false
        let loop = runLoop
        lock.unlock()

        if let loop {
            CFRunLoopStop(loop)
        }

        lock.lock()
        tearDownTapLocked()
        thread = nil
        runLoop = nil
        lock.unlock()
        AppLog.tap.info("Event tap stopped")
    }

    func restart() {
        stop()
        Thread.sleep(forTimeInterval: 0.05)
        start()
    }

    private func threadMain() {
        lock.lock()
        runLoop = CFRunLoopGetCurrent()
        let shouldRun = wantsRunning
        lock.unlock()

        guard shouldRun else { return }

        if !installTap() {
            AppLog.tap.error("Failed to create event tap - keyboard left untouched (fail-open)")
            lock.lock()
            thread = nil
            runLoop = nil
            lock.unlock()
            return
        }

        CFRunLoopRun()

        lock.lock()
        tearDownTapLocked()
        thread = nil
        runLoop = nil
        lock.unlock()
    }

    private func installTap() -> Bool {
        let mask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)

        let unmanagedSelf = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else {
                    return Unmanaged.passUnretained(event)
                }

                let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handle(type: type, event: event)
            },
            userInfo: unmanagedSelf
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        lock.lock()
        eventTap = tap
        runLoopSource = source
        lock.unlock()
        return true
    }

    private func tearDownTapLocked() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            if let loop = runLoop {
                CFRunLoopRemoveSource(loop, source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handle(
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            lock.lock()
            let tap = eventTap
            lock.unlock()
            if let tap {
                AppLog.tap.warning("Event tap disabled (\(String(describing: type))) - re-enabling")
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            
            return Unmanaged.passUnretained(event)
        }

        if let result = engine.handle(event: event, type: type) {
            return Unmanaged.passUnretained(result)
        }

        return nil
    }
}
