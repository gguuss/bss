# Better Screen Shot (BSS) — Project Roadmap

This roadmap governs the iterative development of **Better Screen Shot**, ensuring every feature is specified, prioritized, and tested prior to release.

---

## Release Milestones & Semantic Versioning

| Version | Status | Milestone Focus |
| :--- | :--- | :--- |
| **v0.1.0** | ✅ Completed | Core Capture Engine & Clipboard Integration |
| **v0.2.0** | ✅ Completed | Menubar UI, Bullseye Window Picker & Global Hotkeys |
| **v0.3.0** | ✅ Completed | First-Run Permissions Wizard, App Icon & Splash Screen |
| **v1.0.0** | ✅ Completed | Initial Stable Release (Core Features & Signing) |
| **v1.0.1** | 🚀 Submitted to Mac App Store | Production App Store Release as "Screenshot to Copy and Paste" |
| **v2.0.0** | 📋 Planned | Video Recording (Window & Screen) with System Audio |
| **v2.1.0** | 📋 Planned | Secure Screenshot & Video Vault / Gallery |

---

## Core Features (Milestones v0.1.0 – v1.0.1)

### 1. Core Capture Engine & Clipboard Buffer (v0.1.0)
- [x] High-performance display capture using modern macOS APIs (`ScreenCaptureKit` + AppKit fallbacks)
- [x] Targeted window capture by Window ID (`CGWindowID`)
- [x] Automatic clipboard integration (`NSPasteboard` writing PNG and TIFF bitmaps for universal chat app pasting)
- [x] Audio shutter feedback on capture
- [x] Automated unit tests covering clipboard serialization, bounds calculations, and image generation

### 2. Menu Bar Presence & Interactive Window Picker (v0.2.0)
- [x] Native macOS Status Bar item with camera icon
- [x] Bullseye interactive menu item: click-or-drag bullseye onto any target window to capture it
- [x] Visual highlight overlay window showing the detected window under cursor during picker mode
- [x] Display capture menu item with monitor icon
- [x] Global system-wide keyboard shortcut (configurable hotkey, e.g., `Cmd + Shift + 2`)
- [x] Tests covering hotkey parsing, modifier flags, and window picker geometry

### 3. Onboarding, Splash Screen & Branding (v0.3.0)
- [x] First-run configuration wizard guiding macOS permissions:
  - Screen Recording permission (`CGPreflightScreenCaptureAccess` / `CGRequestScreenCaptureAccess`)
  - Accessibility permission (for global mouse/window tracking)
  - One-click deep links to macOS System Settings
- [x] Branded splash screen on launch with hotkey reference and version info
- [x] Custom high-resolution macOS application icon ("Better Screen Shot" camera with optical bullseye lens)

### 4. Production Packaging & Release (v1.0.0 / v1.0.1)
- [x] Standalone macOS `.app` bundle assembly (`Screenshot to Copy and Paste.app`)
- [x] Developer ID code signing (`Developer ID Application: Gregory Class (Z2YEEZZZN6)`) with hardened runtime and sandboxing entitlements
- [x] Drag-to-Applications `.dmg` installer creation (`BetterScreenShot-v1.0.1.dmg`)
- [x] App Store submission validation passed ("Screenshot to Copy and Paste", Bundle ID `And-Friends.Better-Screen-Shot`)
- [x] Comprehensive documentation in `README.md`
- [x] Git repository tagged with releases (`v1.0.0`, `v1.0.1`) and published to `https://github.com/gguuss/bss`

---

## Nice-to-Have Features (Future Milestones)

### Milestone v2.0.0: Video Recording with System Audio
- [ ] Video bullseye menu item: drag onto a window to record a configurable 5–60 second clip
- [ ] Video display menu item: record a configurable 5–60 second clip of the active display
- [ ] System-wide audio capture integrated via `ScreenCaptureKit` audio stream
- [ ] Automated export to MP4/GIF with copy-to-clipboard option or quick drag-out

### Milestone v2.1.0: Secure Media Vault & Gallery
- [ ] Local in-app gallery displaying recent screenshots and recordings
- [ ] Secure sandboxed storage with privacy controls
- [ ] Quick search, preview, and one-click re-copy / export to disk
