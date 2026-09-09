import AppKit
import BetterScreenShotCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure as accessory/agent app (menu bar only, no Dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Setup Menu Bar
        StatusBarController.shared.setupStatusBar()

        // Setup Global Hotkeys
        setupHotkeys()

        // First-run wizard or splash screen check
        let hasCompletedWizard = UserDefaults.standard.bool(forKey: "hasCompletedFirstRunWizard")
        let hasScreenPerm = PermissionsManager.shared.checkScreenRecordingPermission()

        if !hasCompletedWizard || !hasScreenPerm {
            StatusBarController.shared.showFirstRunWizard()
        } else {
            let showSplash = UserDefaults.standard.object(forKey: "showSplashOnLaunch") as? Bool ?? true
            if showSplash {
                StatusBarController.shared.showSplashScreen()
            }
        }
    }

    private func setupHotkeys() {
        HotkeyManager.shared.onWindowCaptureTriggered = {
            StatusBarController.shared.startBullseyeWindowCapture()
        }
        HotkeyManager.shared.onDisplayCaptureTriggered = {
            StatusBarController.shared.captureScreenAction()
        }

        HotkeyManager.shared.registerWindowCapture()
        HotkeyManager.shared.registerDisplayCapture()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregisterAll()
    }
}
