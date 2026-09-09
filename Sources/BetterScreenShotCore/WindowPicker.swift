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

    private var isPicking = false
    private var trackingTimer: Timer?
    private var globalMouseUpMonitor: Any?
    private var localMouseUpMonitor: Any?
    private var keyMonitor: Any?
    private var currentHighlightedWindow: DetectedWindow?
    private var completionHandler: ((CGImage?) -> Void)?

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

            guard let windowID = info[kCGWindowNumber as String] as? CGWindowID else {
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
        let windows = getVisibleWindows(excludingPID: excludingPID)
        return windows.first { $0.bounds.contains(quartzPoint) }
    }

    // MARK: - Interactive Bullseye Tracking

    /// Starts interactive bullseye tracking.
    /// Can be initiated via drag from menubar or triggered via global hotkey.
    public func startBullseyeSession(completion: @escaping (CGImage?) -> Void) {
        guard !isPicking else { return }
        isPicking = true
        completionHandler = completion

        // Change cursor to crosshair/bullseye
        NSCursor.crosshair.push()

        // Track cursor position periodically at 60Hz
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateCursorHighlight()
            }
        }

        // Listen for mouse up (drag release or click)
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            Task { @MainActor in
                self?.finishBullseyeSession()
            }
        }

        localMouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            Task { @MainActor in
                self?.finishBullseyeSession()
            }
            return event
        }

        // Listen for Escape key to cancel
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 { // 53 is Escape
                Task { @MainActor in
                    self?.cancelBullseyeSession()
                }
                return nil
            }
            return event
        }
    }

    private func updateCursorHighlight() {
        guard isPicking else { return }

        // Quartz coordinates (0,0 is top-left of primary screen)
        let quartzPoint = CGEvent(source: nil)?.location ?? CGPoint.zero

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

    /// Concludes the session, captures the target window, and copies it to clipboard
    public func finishBullseyeSession() {
        guard isPicking else { return }
        HighlightOverlayWindow.shared.dismiss()
        let targetWindow = currentHighlightedWindow
        tearDownTracking()

        guard let selectedWindow = targetWindow else {
            completionHandler?(nil)
            completionHandler = nil
            return
        }

        // Delay to allow macOS window server to completely remove the highlight overlay from the frame buffer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            Task { @MainActor in
                let image = await CaptureEngine.shared.captureWindow(windowID: selectedWindow.windowID)
                if let image = image {
                    ClipboardManager.shared.copyToClipboard(cgImage: image)
                }
                self?.completionHandler?(image)
                self?.completionHandler = nil
            }
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
        trackingTimer?.invalidate()
        trackingTimer = nil

        if let gMonitor = globalMouseUpMonitor {
            NSEvent.removeMonitor(gMonitor)
            globalMouseUpMonitor = nil
        }
        if let lMonitor = localMouseUpMonitor {
            NSEvent.removeMonitor(lMonitor)
            localMouseUpMonitor = nil
        }
        if let kMonitor = keyMonitor {
            NSEvent.removeMonitor(kMonitor)
            keyMonitor = nil
        }

        NSCursor.pop()
        HighlightOverlayWindow.shared.dismiss()
        currentHighlightedWindow = nil
    }
}
