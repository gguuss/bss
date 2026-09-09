import AppKit
import CoreGraphics
import ApplicationServices

@MainActor
public final class PermissionsManager: ObservableObject, @unchecked Sendable {
    public static let shared = PermissionsManager()

    @Published public private(set) var hasScreenRecordingPermission: Bool = false
    @Published public private(set) var hasAccessibilityPermission: Bool = false

    public init() {
        refreshPermissions()
    }

    /// Refreshes the cached state of permissions
    @discardableResult
    public func refreshPermissions() -> (screen: Bool, accessibility: Bool) {
        let screen = checkScreenRecordingPermission()
        let accessibility = checkAccessibilityPermission()

        self.hasScreenRecordingPermission = screen
        self.hasAccessibilityPermission = accessibility

        return (screen, accessibility)
    }

    /// Checks if Screen Recording permission is currently granted
    public func checkScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }

    /// Requests Screen Recording permission from macOS
    @discardableResult
    public func requestScreenRecordingPermission() -> Bool {
        return CGRequestScreenCaptureAccess()
    }

    /// Checks if Accessibility permission is granted
    public func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Prompts the user for Accessibility permission with system prompt
    @discardableResult
    public func requestAccessibilityPermission() -> Bool {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings directly to the Screen Recording permission pane
    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Opens System Settings directly to the Accessibility permission pane
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Returns true if all required permissions are granted
    public var isFullyConfigured: Bool {
        return checkScreenRecordingPermission()
    }
}
