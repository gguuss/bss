import AppKit
import Carbon

public struct HotkeyCombination: Codable, Equatable, Sendable {
    public var keyCode: UInt32
    public var modifiers: UInt32

    public init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// Default: Cmd + Shift + 2 (keyCode 19 for '2')
    public static let defaultWindowCapture = HotkeyCombination(
        keyCode: 19,
        modifiers: UInt32(cmdKey | shiftKey)
    )

    /// Default: Cmd + Shift + 1 (keyCode 18 for '1')
    public static let defaultDisplayCapture = HotkeyCombination(
        keyCode: 18,
        modifiers: UInt32(cmdKey | shiftKey)
    )

    public var displayString: String {
        var str = ""
        if (modifiers & UInt32(controlKey)) != 0 { str += "⌃ " }
        if (modifiers & UInt32(optionKey)) != 0 { str += "⌥ " }
        if (modifiers & UInt32(shiftKey)) != 0 { str += "⇧ " }
        if (modifiers & UInt32(cmdKey)) != 0 { str += "⌘ " }

        switch keyCode {
        case 18: str += "1"
        case 19: str += "2"
        case 20: str += "3"
        case 21: str += "4"
        case 23: str += "5"
        default: str += "Key(\(keyCode))"
        }
        return str
    }
}

@MainActor
public final class HotkeyManager: @unchecked Sendable {
    public static let shared = HotkeyManager()

    private var eventHandlerRef: EventHandlerRef?
    private var windowHotKeyRef: EventHotKeyRef?
    private var displayHotKeyRef: EventHotKeyRef?

    public var onWindowCaptureTriggered: (() -> Void)?
    public var onDisplayCaptureTriggered: (() -> Void)?

    private let windowHotKeyID = EventHotKeyID(signature: OSType(0x42535331), id: 1) // 'BSS1'
    private let displayHotKeyID = EventHotKeyID(signature: OSType(0x42535332), id: 2) // 'BSS2'

    public init() {
        installCarbonEventHandler()
    }

    private func installCarbonEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { _, inEvent, userData -> OSStatus in
            guard let inEvent = inEvent, let userData = userData else {
                return OSStatus(eventNotHandledErr)
            }

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                inEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr else { return OSStatus(eventNotHandledErr) }

            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

            DispatchQueue.main.async {
                if hotKeyID.id == 1 {
                    manager.onWindowCaptureTriggered?()
                } else if hotKeyID.id == 2 {
                    manager.onDisplayCaptureTriggered?()
                }
            }

            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )
    }

    /// Registers the global window capture shortcut
    public func registerWindowCapture(combination: HotkeyCombination = .defaultWindowCapture) {
        if let ref = windowHotKeyRef {
            UnregisterEventHotKey(ref)
            windowHotKeyRef = nil
        }

        RegisterEventHotKey(
            combination.keyCode,
            combination.modifiers,
            windowHotKeyID,
            GetApplicationEventTarget(),
            0,
            &windowHotKeyRef
        )
    }

    /// Registers the global display capture shortcut
    public func registerDisplayCapture(combination: HotkeyCombination = .defaultDisplayCapture) {
        if let ref = displayHotKeyRef {
            UnregisterEventHotKey(ref)
            displayHotKeyRef = nil
        }

        RegisterEventHotKey(
            combination.keyCode,
            combination.modifiers,
            displayHotKeyID,
            GetApplicationEventTarget(),
            0,
            &displayHotKeyRef
        )
    }

    /// Unregisters all registered hotkeys
    public func unregisterAll() {
        if let ref = windowHotKeyRef {
            UnregisterEventHotKey(ref)
            windowHotKeyRef = nil
        }
        if let ref = displayHotKeyRef {
            UnregisterEventHotKey(ref)
            displayHotKeyRef = nil
        }
    }
}
