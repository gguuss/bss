import AppKit
import SwiftUI

@MainActor
public final class StatusBarController: NSObject, NSMenuDelegate, @unchecked Sendable {
    public static let shared = StatusBarController()

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()

    private var wizardWindow: NSWindow?
    private var splashWindow: NSWindow?

    public override init() {
        super.init()
    }

    public func setupStatusBar() {
        // Create Status Bar Item on right side of menubar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // Camera icon in menubar
        if let cameraImage = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Better Screen Shot") {
            cameraImage.isTemplate = true
            button.image = cameraImage
        } else {
            button.title = "📸"
        }
        button.toolTip = "Better Screen Shot"

        buildMenu()
        statusItem?.menu = menu
    }

    private func buildMenu() {
        menu.removeAllItems()
        menu.delegate = self

        // Header Item
        let headerItem = NSMenuItem(title: "Better Screen Shot v1.0.0", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // 1. Bullseye Window Item (Custom View with Drag / Click Support)
        let bullseyeItem = NSMenuItem()
        let bullseyeView = BullseyeMenuItemView()
        bullseyeView.onSelect = { [weak self] in
            self?.startBullseyeWindowCapture()
        }
        bullseyeItem.view = bullseyeView
        menu.addItem(bullseyeItem)

        // 2. Full Display Item
        let displayItem = NSMenuItem(
            title: "Capture Entire Screen",
            action: #selector(captureScreenAction),
            keyEquivalent: "1"
        )
        displayItem.keyEquivalentModifierMask = [.command, .shift]
        displayItem.target = self
        if let displayImg = NSImage(systemSymbolName: "display", accessibilityDescription: "Display") {
            displayItem.image = displayImg
        }
        menu.addItem(displayItem)

        menu.addItem(NSMenuItem.separator())

        // 3. Setup Wizard
        let wizardItem = NSMenuItem(
            title: "Permissions & Setup Wizard...",
            action: #selector(showFirstRunWizard),
            keyEquivalent: ""
        )
        wizardItem.target = self
        if let wrenchImg = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Setup") {
            wizardItem.image = wrenchImg
        }
        menu.addItem(wizardItem)

        // 4. Splash Screen / Shortcuts
        let splashItem = NSMenuItem(
            title: "Hotkeys & About...",
            action: #selector(showSplashScreen),
            keyEquivalent: ""
        )
        splashItem.target = self
        if let infoImg = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About") {
            splashItem.image = infoImg
        }
        menu.addItem(splashItem)

        menu.addItem(NSMenuItem.separator())

        // 5. Quit
        let quitItem = NSMenuItem(
            title: "Quit Better Screen Shot",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc public func startBullseyeWindowCapture() {
        WindowPicker.shared.startBullseyeSession { image in
            if image != nil {
                // Screenshot taken & copied to clipboard
            }
        }
    }

    @objc public func captureScreenAction() {
        Task { @MainActor in
            await CaptureEngine.shared.captureDisplayToClipboard()
        }
    }

    @objc public func showFirstRunWizard() {
        if wizardWindow == nil {
            let wizardView = FirstRunWizardView { [weak self] in
                self?.wizardWindow?.close()
                self?.wizardWindow = nil
            }
            let hostingController = NSHostingController(rootView: wizardView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Better Screen Shot — First-Run Setup"
            window.styleMask = [.titled, .closable]
            window.center()
            window.isReleasedWhenClosed = false
            wizardWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        wizardWindow?.makeKeyAndOrderFront(nil)
    }

    @objc public func showSplashScreen() {
        if splashWindow == nil {
            let splashView = SplashScreenView { [weak self] in
                self?.splashWindow?.close()
                self?.splashWindow = nil
            }
            let hostingController = NSHostingController(rootView: splashView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Better Screen Shot"
            window.styleMask = [.titled, .closable]
            window.center()
            window.isReleasedWhenClosed = false
            splashWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        splashWindow?.makeKeyAndOrderFront(nil)
    }

    @objc public func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
