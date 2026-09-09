import AppKit
import CoreGraphics
import ApplicationServices
import ScreenCaptureKit

@MainActor
public final class PermissionsManager: ObservableObject, @unchecked Sendable {
    public static let shared = PermissionsManager()

    @Published public private(set) var hasScreenRecordingPermission: Bool = false
    @Published public private(set) var hasAccessibilityPermission: Bool = false

    public init() {
        refreshPermissions()
    }

    /// Refreshes the cached state of permissions synchronously
    @discardableResult
    public func refreshPermissions() -> (screen: Bool, accessibility: Bool) {
        let screen = checkScreenRecordingPermission()
        let accessibility = checkAccessibilityPermission()

        self.hasScreenRecordingPermission = screen
        self.hasAccessibilityPermission = accessibility

        return (screen, accessibility)
    }

    /// Asynchronously verifies Screen Recording access via ScreenCaptureKit as well as CGPreflight
    @discardableResult
    public func verifyScreenRecordingAccess() async -> Bool {
        if CGPreflightScreenCaptureAccess() {
            self.hasScreenRecordingPermission = true
            return true
        }

        if #available(macOS 14.0, *) {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                let granted = !content.displays.isEmpty
                if granted {
                    self.hasScreenRecordingPermission = true
                }
                return granted
            } catch {
                return false
            }
        }

        return false
    }

    /// Checks if Screen Recording permission is currently granted
    public func checkScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }

    /// Requests Screen Recording permission from macOS, triggering both CoreGraphics and ScreenCaptureKit
    @discardableResult
    public func requestScreenRecordingPermission() -> Bool {
        let cgResult = CGRequestScreenCaptureAccess()
        Task {
            if #available(macOS 14.0, *) {
                _ = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            }
        }
        return cgResult
    }

    /// Checks if Accessibility permission is granted
    public func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Prompts the user for Accessibility permission with system prompt
    @discardableResult
    public func requestAccessibilityPermission() -> Bool {
        let options = [("AXTrustedCheckOptionPrompt" as CFString): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings directly to the Screen Recording permission pane
    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            if !NSWorkspace.shared.open(url) {
                if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                    NSWorkspace.shared.open(fallback)
                }
            }
        }
    }

    /// Opens System Settings directly to the Accessibility permission pane
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            if !NSWorkspace.shared.open(url) {
                if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                    NSWorkspace.shared.open(fallback)
                }
            }
        }
    }

    /// Relaunches the application to apply newly granted macOS permissions
    public func relaunchApp() {
        let bundleURL = Bundle.main.bundleURL
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", bundleURL.path]
        try? process.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.terminate(nil)
        }
    }

    /// Returns true if all required permissions are granted
    public var isFullyConfigured: Bool {
        return checkScreenRecordingPermission()
    }
}
