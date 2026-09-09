import AppKit
import CoreGraphics

/// A transparent, borderless, non-activating fullscreen panel that intercepts mouse movements,
/// clicks, drags, and keyboard events during an active Bullseye capture session.
@MainActor
public final class BullseyeTrackingOverlayWindow: NSPanel, @unchecked Sendable {
    public static let shared = BullseyeTrackingOverlayWindow()

    public var onMouseMoved: ((CGPoint) -> Void)?
    public var onWindowSelected: ((CGPoint) -> Void)?
    public var onDragReleased: ((CGPoint, Bool) -> Void)?
    public var onCancel: (() -> Void)?

    private var initialMouseDownPoint: CGPoint?
    private var sessionStartTime: Date = Date()
    private var isDraggingSession = false

    private final class TrackingContentView: NSView {
        weak var overlay: BullseyeTrackingOverlayWindow?
        private var trackingAreaRef: NSTrackingArea?

        override var acceptsFirstResponder: Bool { true }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let existing = trackingAreaRef {
                removeTrackingArea(existing)
            }
            let options: NSTrackingArea.Options = [
                .mouseMoved,
                .mouseEnteredAndExited,
                .activeAlways,
                .inVisibleRect
            ]
            let newArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
            addTrackingArea(newArea)
            trackingAreaRef = newArea
        }

        override func resetCursorRects() {
            super.resetCursorRects()
            addCursorRect(bounds, cursor: .crosshair)
        }

        override func mouseMoved(with event: NSEvent) {
            overlay?.handleMouseMoved(event: event)
        }

        override func mouseDragged(with event: NSEvent) {
            overlay?.handleMouseDragged(event: event)
        }

        override func mouseDown(with event: NSEvent) {
            overlay?.handleMouseDown(event: event)
        }

        override func mouseUp(with event: NSEvent) {
            overlay?.handleMouseUp(event: event)
        }

        override func rightMouseDown(with event: NSEvent) {
            overlay?.onCancel?()
        }

        override func keyDown(with event: NSEvent) {
            if event.keyCode == 53 { // Escape
                overlay?.onCancel?()
            } else {
                super.keyDown(with: event)
            }
        }
    }

    public init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let trackingView = TrackingContentView(frame: .zero)
        trackingView.overlay = self
        self.contentView = trackingView
    }

    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }

    /// Presents the tracking overlay covering all screens
    public func show(initialPoint: CGPoint? = nil, isDrag: Bool = false) {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        // Compute union frame of all screens
        let unionFrame = screens.reduce(CGRect.null) { $0.union($1.frame) }
        self.setFrame(unionFrame, display: true)

        self.initialMouseDownPoint = initialPoint ?? NSEvent.mouseLocation
        self.sessionStartTime = Date()
        self.isDraggingSession = isDrag

        self.makeKeyAndOrderFront(nil)
        NSCursor.crosshair.push()
    }

    /// Dismisses the tracking overlay
    public func dismiss() {
        NSCursor.pop()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.orderOut(nil)
        CATransaction.commit()
        CATransaction.flush()

        initialMouseDownPoint = nil
        isDraggingSession = false
    }

    private func quartzPoint(for event: NSEvent) -> CGPoint {
        guard let primaryScreen = NSScreen.screens.first else {
            return event.locationInWindow
        }
        let mouseLocation = NSEvent.mouseLocation
        return CGPoint(
            x: mouseLocation.x,
            y: primaryScreen.frame.height - mouseLocation.y
        )
    }

    private func handleMouseMoved(event: NSEvent) {
        let qPoint = quartzPoint(for: event)
        onMouseMoved?(qPoint)
    }

    private func handleMouseDragged(event: NSEvent) {
        isDraggingSession = true
        let qPoint = quartzPoint(for: event)
        onMouseMoved?(qPoint)
    }

    private func handleMouseDown(event: NSEvent) {
        let qPoint = quartzPoint(for: event)
        onWindowSelected?(qPoint)
    }

    private func handleMouseUp(event: NSEvent) {
        let currentMouse = NSEvent.mouseLocation
        let elapsed = Date().timeIntervalSince(sessionStartTime)

        if let initial = initialMouseDownPoint {
            let dx = currentMouse.x - initial.x
            let dy = currentMouse.y - initial.y
            let distance = hypot(dx, dy)

            // If mouseUp occurs right where it started within 0.35s, it was the initial click
            // that opened the menu item, NOT a drag release over a target window.
            if distance < 20.0 && elapsed < 0.35 && !isDraggingSession {
                // Ignore initial click mouseUp so the user remains in interactive click mode
                return
            }
        }

        let qPoint = quartzPoint(for: event)
        onDragReleased?(qPoint, isDraggingSession)
    }
}
