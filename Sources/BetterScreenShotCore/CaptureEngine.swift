import AppKit
import CoreGraphics
import ScreenCaptureKit

@MainActor
public final class CaptureEngine: @unchecked Sendable {
    public static let shared = CaptureEngine()

    public init() {}

    // MARK: - Display Capture

    /// Captures the primary or active display using ScreenCaptureKit with CGDisplay fallback
    public func captureMainDisplay() async -> CGImage? {
        let mainDisplayID = CGMainDisplayID()
        return await captureDisplay(displayID: mainDisplayID)
    }

    /// Captures a specific display by its direct display ID using ScreenCaptureKit
    public func captureDisplay(displayID: CGDirectDisplayID) async -> CGImage? {
        if #available(macOS 14.0, *) {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                if let scDisplay = content.displays.first(where: { $0.displayID == displayID }) ?? content.displays.first {
                    let filter = SCContentFilter(display: scDisplay, excludingWindows: [])
                    let config = SCStreamConfiguration()
                    config.width = max(scDisplay.width * 2, 2)
                    config.height = max(scDisplay.height * 2, 2)
                    config.showsCursor = false
                    return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                }
            } catch {
                // Fallback to legacy CGDisplayCreateImage
            }
        }
        return CGDisplayCreateImage(displayID)
    }

    /// Synchronous fallback for display capture
    public func captureDisplaySync(displayID: CGDirectDisplayID = CGMainDisplayID()) -> CGImage? {
        return CGDisplayCreateImage(displayID)
    }

    /// Captures the main display and writes it directly to the system clipboard
    @discardableResult
    public func captureDisplayToClipboard(displayID: CGDirectDisplayID = CGMainDisplayID(), to pasteboard: NSPasteboard = .general) async -> Bool {
        guard let image = await captureDisplay(displayID: displayID) else {
            // Fallback to sync
            if let fallback = captureDisplaySync(displayID: displayID) {
                return ClipboardManager.shared.copyToClipboard(cgImage: fallback, to: pasteboard)
            }
            return false
        }
        return ClipboardManager.shared.copyToClipboard(cgImage: image, to: pasteboard)
    }

    // MARK: - Window Capture

    /// Captures a specific on-screen window by its CGWindowID using ScreenCaptureKit desktop-independent capture
    public func captureWindow(windowID: CGWindowID) async -> CGImage? {
        if #available(macOS 14.0, *) {
            do {
                var content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
                var targetWindow = content.windows.first(where: { $0.windowID == windowID })

                if targetWindow == nil {
                    content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                    targetWindow = content.windows.first(where: { $0.windowID == windowID })
                }

                if let scWindow = targetWindow {
                    let filter = SCContentFilter(desktopIndependentWindow: scWindow)
                    let config = SCStreamConfiguration()
                    let scale = NSScreen.main?.backingScaleFactor ?? 2.0
                    config.width = max(Int(scWindow.frame.width * scale), 2)
                    config.height = max(Int(scWindow.frame.height * scale), 2)
                    config.showsCursor = false
                    return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                }
            } catch {
                // Fallback to legacy CGWindowList
            }
        }

        let imageOption: CGWindowImageOption = [.bestResolution, .boundsIgnoreFraming]
        let listOption: CGWindowListOption = [.optionIncludingWindow]

        guard let image = CGWindowListCreateImage(.null, listOption, windowID, imageOption) else {
            return CGWindowListCreateImage(.null, listOption, windowID, .nominalResolution)
        }
        return image
    }

    /// Synchronous fallback for window capture
    public func captureWindowSync(windowID: CGWindowID) -> CGImage? {
        let imageOption: CGWindowImageOption = [.bestResolution, .boundsIgnoreFraming]
        let listOption: CGWindowListOption = [.optionIncludingWindow]
        return CGWindowListCreateImage(.null, listOption, windowID, imageOption)
    }

    /// Captures a window by window ID and immediately copies to the system clipboard
    @discardableResult
    public func captureWindowToClipboard(windowID: CGWindowID, to pasteboard: NSPasteboard = .general) async -> Bool {
        guard let image = await captureWindow(windowID: windowID) else {
            if let fallback = captureWindowSync(windowID: windowID) {
                return ClipboardManager.shared.copyToClipboard(cgImage: fallback, to: pasteboard)
            }
            return false
        }
        return ClipboardManager.shared.copyToClipboard(cgImage: image, to: pasteboard)
    }

    // MARK: - Region / Rect Capture

    /// Captures a specific bounding rectangle across displays
    public func captureRect(_ rect: CGRect) -> CGImage? {
        let imageOption: CGWindowImageOption = [.bestResolution]
        let listOption: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        return CGWindowListCreateImage(rect, listOption, kCGNullWindowID, imageOption)
    }

    /// Captures a specific bounding rectangle and writes directly to clipboard
    @discardableResult
    public func captureRectToClipboard(_ rect: CGRect, to pasteboard: NSPasteboard = .general) -> Bool {
        guard let image = captureRect(rect) else {
            return false
        }
        return ClipboardManager.shared.copyToClipboard(cgImage: image, to: pasteboard)
    }
}
