import AppKit
import CoreGraphics

public struct DetectedWindow: Equatable, Sendable {
    public let windowID: CGWindowID
    public let ownerName: String
    public let title: String
    public let bounds: CGRect
    public let layer: Int

    public init(windowID: CGWindowID, ownerName: String, title: String, bounds: CGRect, layer: Int) {
        self.windowID = windowID
        self.ownerName = ownerName
        self.title = title
        self.bounds = bounds
        self.layer = layer
    }
}

@MainActor
public final class WindowPicker: @unchecked Sendable {
    public static let shared = WindowPicker()

    public private(set) var isPicking = false
    public private(set) var currentHighlightedWindow: DetectedWindow?
    private var completionHandler: ((CGImage?) -> Void)?
    private var cachedWindows: [DetectedWindow] = []

    public init() {}

    // MARK: - Query Windows

    /// Retrieves all visible standard application windows on screen, ordered front-to-back
    public func getVisibleWindows(excludingPID: pid_t = ProcessInfo.processInfo.processIdentifier) -> [DetectedWindow] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var results: [DetectedWindow] = []

        for info in windowInfoList {
            guard let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0 else {
                continue
            }

            guard let windowID = (info[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? (info[kCGWindowNumber as String] as? CGWindowID) else {
                continue
            }

            if let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid == excludingPID {
                continue
            }

            guard let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else {
                continue
            }

            // Filter out tiny windows (e.g., hidden helpers, 1x1 rects)
            guard bounds.width > 30 && bounds.height > 30 else {
                continue
            }

            let owner = info[kCGWindowOwnerName as String] as? String ?? "App"
            let title = info[kCGWindowName as String] as? String ?? ""

            results.append(DetectedWindow(
                windowID: windowID,
                ownerName: owner,
                title: title,
                bounds: bounds,
                layer: layer
            ))
        }

        return results
    }

    /// Finds the topmost visible window containing the specified point in screen coordinates (Quartz / top-left origin)
    public func findWindow(at quartzPoint: CGPoint, excludingPID: pid_t = ProcessInfo.processInfo.processIdentifier) -> DetectedWindow? {
        let windows = cachedWindows.isEmpty ? getVisibleWindows(excludingPID: excludingPID) : cachedWindows
        return windows.first { $0.bounds.contains(quartzPoint) }
    }

    // MARK: - Interactive Bullseye Tracking

    /// Starts interactive bullseye tracking.
    /// Can be initiated via drag from menubar, click from menubar, or triggered via global hotkey.
    public func startBullseyeSession(
        initialPoint: CGPoint? = nil,
        isDrag: Bool = false,
        completion: @escaping (CGImage?) -> Void
    ) {
        guard !isPicking else { return }
        isPicking = true
        completionHandler = completion

        // Refresh cached visible windows for the session
        cachedWindows = getVisibleWindows()

        let overlay = BullseyeTrackingOverlayWindow.shared
        overlay.onMouseMoved = { [weak self] quartzPoint in
            self?.handleMouseMoved(at: quartzPoint)
        }
        overlay.onWindowSelected = { [weak self] quartzPoint in
            self?.handleWindowSelected(at: quartzPoint)
        }
        overlay.onDragReleased = { [weak self] quartzPoint, isDragging in
            self?.handleDragReleased(at: quartzPoint, isDragging: isDragging)
        }
        overlay.onCancel = { [weak self] in
            self?.cancelBullseyeSession()
        }

        overlay.show(initialPoint: initialPoint, isDrag: isDrag)

        // Immediately highlight window under initial cursor position if available
        let initialQuartz = quartzPointFromMouseLocation()
        handleMouseMoved(at: initialQuartz)
    }

    /// Overload for backwards compatibility
    public func startBullseyeSession(completion: @escaping (CGImage?) -> Void) {
        startBullseyeSession(initialPoint: nil, isDrag: false, completion: completion)
    }

    public func handleMouseMoved(at quartzPoint: CGPoint) {
        guard isPicking else { return }

        if let window = findWindow(at: quartzPoint) {
            if currentHighlightedWindow != window {
                currentHighlightedWindow = window
                let displayTitle = window.title.isEmpty ? window.ownerName : "\(window.ownerName) — \(window.title)"
                HighlightOverlayWindow.shared.highlight(rect: window.bounds, title: displayTitle)
            }
        } else {
            currentHighlightedWindow = nil
            HighlightOverlayWindow.shared.dismiss()
        }
    }

    public func handleWindowSelected(at quartzPoint: CGPoint) {
        guard isPicking else { return }
        let target = currentHighlightedWindow ?? findWindow(at: quartzPoint)
        if let target = target {
            finishWithWindow(target)
        } else {
            cancelBullseyeSession()
        }
    }

    public func handleDragReleased(at quartzPoint: CGPoint, isDragging: Bool) {
        guard isPicking else { return }
        if isDragging {
            let target = currentHighlightedWindow ?? findWindow(at: quartzPoint)
            if let target = target {
                finishWithWindow(target)
                return
            }
        }
        // If not a significant drag, user stays in interactive click mode
    }

    /// Captures the specified window, dismisses overlays, copies to clipboard, and notifies completion
    public func finishWithWindow(_ window: DetectedWindow) {
        guard isPicking else { return }
        tearDownTracking()

        // Delay allows the macOS window server to completely remove the highlight overlay from the frame buffer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            Task { @MainActor in
                let image = await CaptureEngine.shared.captureWindow(windowID: window.windowID)
                if let image = image {
                    ClipboardManager.shared.copyToClipboard(cgImage: image)
                }
                self?.completionHandler?(image)
                self?.completionHandler = nil
            }
        }
    }

    /// Concludes the session with the currently highlighted window if available
    public func finishBullseyeSession() {
        guard isPicking else { return }
        if let target = currentHighlightedWindow {
            finishWithWindow(target)
        } else {
            cancelBullseyeSession()
        }
    }

    /// Cancels active picker session without taking a screenshot
    public func cancelBullseyeSession() {
        guard isPicking else { return }
        tearDownTracking()
        completionHandler?(nil)
        completionHandler = nil
    }

    private func tearDownTracking() {
        isPicking = false
        BullseyeTrackingOverlayWindow.shared.dismiss()
        HighlightOverlayWindow.shared.dismiss()
        currentHighlightedWindow = nil
        cachedWindows = []
    }

    private func quartzPointFromMouseLocation() -> CGPoint {
        let appKitPoint = NSEvent.mouseLocation
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        return CGPoint(x: appKitPoint.x, y: primaryHeight - appKitPoint.y)
    }
}
