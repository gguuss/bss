# Better Screen Shot (BSS) 📸🎯

**Better Screen Shot** is a lightweight, blazing-fast macOS menu bar utility designed specifically for knowledge workers, developers, and communicators. It streamlines capturing any window or full screen directly into your system clipboard, allowing you to instantly paste crisp screenshots into chat windows (Slack, Discord, Teams, Messages, Google Chat, etc.) with zero friction.

[![GitHub release](https://img.shields.io/github/v/release/gguuss/bss?color=blue)](https://github.com/gguuss/bss)
[![macOS](https://img.shields.io/badge/platform-macOS%2013.0%2B-lightgrey.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/swift-6.0%2B-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Key Features

- **Menu Bar Camera Icon**: Sits discreetly on the right side of the macOS menu bar (`LSUIElement` agent app).
- **Interactive Bullseye Window Selector**: Click or drag the Bullseye item onto any window on your desktop to instantly snap just that window. A real-time highlight border previews your selection before snapping.
- **Full Display Capture**: One click on the Display icon instantly captures your active monitor.
- **Direct-to-Clipboard**: Every capture automatically writes standard PNG and TIFF formats to `NSPasteboard`, ready for instant `Cmd + V` pasting into any chat, document, or email.
- **Configurable Global Keyboard Shortcuts**: Trigger window bullseye capture or screen capture from anywhere in macOS using customizable hotkeys.
- **First-Run Setup Wizard**: Intuitive setup wizard detecting macOS Screen Recording and Accessibility permissions, offering 1-click deep links to System Settings.
- **Branded Splash Screen**: Quick reference guide on launch highlighting active hotkeys and features.
- **Camera Shutter Audio**: Pleasant, subtle acoustic confirmation when a screenshot has been placed on the clipboard.

---

## Keyboard Shortcuts

| Action | Default Hotkey | Configurable |
| :--- | :--- | :--- |
| **Interactive Bullseye Window Capture** | `⌘ ⇧ 2` (`Cmd + Shift + 2`) | Yes (Preferences) |
| **Full Display Capture** | `⌘ ⇧ 1` (`Cmd + Shift + 1`) | Yes (Preferences) |
| **Cancel Capture Mode** | `Escape` | N/A |

> **Tip**: You can change the global hotkey at any time via the Menu Bar icon → **Preferences / Shortcuts**.

---

## How to Use

### 1. Window Capture with the Bullseye 🎯
1. Click the **Camera** icon in your macOS menu bar.
2. Click or drag the **Bullseye Window Capture** item.
3. Move your cursor over the window you want to capture. A vivid highlight frame outlines the targeted window.
4. Release the mouse button or click to capture.
5. Switch to Slack, Discord, or your chat app and press `Cmd + V` to paste!

### 2. Full Display Capture 🖥️
1. Click the **Camera** icon in your menu bar.
2. Click **Capture Entire Screen**.
3. Your screen is captured immediately and copied to the clipboard.

### 3. Using Global Hotkeys ⌨️
- Press `Cmd + Shift + 2` anytime from any application to enter Bullseye Window Selection mode without clicking the menu bar.

---

## Required macOS Permissions

macOS requires explicit user permissions for utilities that capture windows or track cursor coordinates:

1. **Screen & System Audio Recording** (`Privacy_ScreenCapture`):
   - **Why**: Allows Better Screen Shot to read pixel buffers of windows and displays using `ScreenCaptureKit`.
   - **How to Enable**: Open **System Settings** → **Privacy & Security** → **Screen & System Audio Recording** → Toggle **Better Screen Shot** ON.
2. **Accessibility** (`Privacy_Accessibility`):
   - **Why**: Allows tracking mouse movements and window IDs across other applications during Bullseye drag selection.
   - **How to Enable**: Open **System Settings** → **Privacy & Security** → **Accessibility** → Toggle **Better Screen Shot** ON.

The included **First-Run Wizard** detects these permissions automatically and provides direct buttons to launch System Settings.

---

## Architecture & Codebase Structure

Better Screen Shot is built natively in Swift using modern AppKit and ScreenCaptureKit:

```
bss/
├── .agents/skills/bss-engineering-discipline/  # Project engineering rigor skill
├── Assets/                                      # Application icons and branding assets
├── Sources/BetterScreenShot/
│   ├── App/                                    # Lifecycle (main.swift, AppDelegate.swift)
│   ├── Core/
│   │   ├── CaptureEngine.swift                 # ScreenCaptureKit & CGWindowList capture
│   │   ├── ClipboardManager.swift              # NSPasteboard writer & audio feedback
│   │   ├── WindowPicker.swift                  # Window geometry detection & highlight overlay
│   │   ├── HotkeyManager.swift                 # Carbon RegisterEventHotKey global shortcuts
│   │   └── PermissionsManager.swift            # macOS permission checking & deep links
│   └── UI/
│       ├── StatusBarController.swift           # Menu bar camera item & dropdown menu
│       ├── BullseyeControl.swift               # Interactive drag-to-window view
│       ├── FirstRunWizardView.swift            # SwiftUI onboarding wizard
│       └── SplashScreenView.swift              # Branded launch/about window
├── Tests/BetterScreenShotTests/                # Automated XCTest suite
├── scripts/
│   └── build_app.sh                            # App bundle packaging and ad-hoc code signing
├── ROADMAP.md                                  # Prioritized milestone roadmap
└── Package.swift                               # Swift package definition
```

---

## Building and Testing

### Prerequisites
- macOS 13.0 (Ventura) or newer
- Xcode 15.0+ or Swift 6.0+ toolchain

### Run Automated Tests
```bash
swift test
```

### Build and Package `.app` Bundle
```bash
./scripts/build_app.sh
```
The signed application will be generated in `dist/Better Screen Shot.app`.

---

## App Store Submission Checklist

To prepare Better Screen Shot for Mac App Store publication:
- [ ] Configure Apple Developer Team and App Store Provisioning Profile in Xcode.
- [ ] Enable App Sandbox with `com.apple.security.device.screen-recording` entitlement.
- [ ] Verify `Info.plist` entries:
  - `NSScreenCaptureUsageDescription`: "Better Screen Shot needs screen recording access to capture windows and displays."
  - `NSCameraUsageDescription`: Optional / not needed unless physical webcam is used.
- [ ] Add App Store marketing assets (1024x1024 icon, localized screenshots, privacy policy URL).
- [ ] Build with `xcodebuild archive` and notarize via `xcrun notarytool`.

---

## License

MIT License. Copyright (c) 2026 Gus Class.
