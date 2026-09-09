import AppKit
import CoreGraphics
import ScreenCaptureKit

@MainActor
public final class CaptureEngine: @unchecked Sendable {
    public static let shared = CaptureEngine()

    public init() {}

    // MARK: - Display Capture

    /// Captures the primary or active display and returns the image
    public func captureMainDisplay() -> CGImage? {
        let mainDisplayID = CGMainDisplayID()
        return captureDisplay(displayID: mainDisplayID)
    }

    /// Captures a specific display by its direct display ID
    public func captureDisplay(displayID: CGDirectDisplayID) -> CGImage? {
        return CGDisplayCreateImage(displayID)
    }

    /// Captures the main display and writes it directly to the system clipboard
    @discardableResult
    public func captureDisplayToClipboard(displayID: CGDirectDisplayID = CGMainDisplayID()) -> Bool {
        guard let image = captureDisplay(displayID: displayID) else {
            return false
        }
        return ClipboardManager.shared.copyToClipboard(cgImage: image)
    }

    // MARK: - Window Capture

    /// Captures a specific on-screen window by its CGWindowID
    public func captureWindow(windowID: CGWindowID) -> CGImage? {
        let imageOption: CGWindowImageOption = [.bestResolution, .boundsIgnoreFraming]
        let listOption: CGWindowListOption = [.optionIncludingWindow]

        guard let image = CGWindowListCreateImage(.null, listOption, windowID, imageOption) else {
            return CGWindowListCreateImage(.null, listOption, windowID, .nominalResolution)
        }
        return image
    }

    /// Captures a window by window ID and immediately copies to the system clipboard
    @discardableResult
    public func captureWindowToClipboard(windowID: CGWindowID) -> Bool {
        guard let image = captureWindow(windowID: windowID) else {
            return false
        }
        return ClipboardManager.shared.copyToClipboard(cgImage: image)
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
    public func captureRectToClipboard(_ rect: CGRect) -> Bool {
        guard let image = captureRect(rect) else {
            return false
        }
        return ClipboardManager.shared.copyToClipboard(cgImage: image)
    }
}
