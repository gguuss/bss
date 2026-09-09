import AppKit
import CoreGraphics

/// A transparent, floating border overlay that outlines the target window during Bullseye tracking.
@MainActor
public final class HighlightOverlayWindow: NSPanel, @unchecked Sendable {
    public static let shared = HighlightOverlayWindow()

    private let borderLayer = CALayer()
    private let titleBadge = CATextLayer()

    public init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        setupLayers()
    }

    private func setupLayers() {
        let rootLayer = CALayer()
        rootLayer.backgroundColor = NSColor.clear.cgColor

        borderLayer.borderWidth = 3.5
        borderLayer.borderColor = NSColor.systemRed.cgColor
        borderLayer.cornerRadius = 8.0
        borderLayer.shadowColor = NSColor.systemRed.cgColor
        borderLayer.shadowOpacity = 0.8
        borderLayer.shadowRadius = 8.0
        borderLayer.shadowOffset = .zero

        titleBadge.fontSize = 12
        titleBadge.foregroundColor = NSColor.white.cgColor
        titleBadge.backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        titleBadge.cornerRadius = 4.0
        titleBadge.alignmentMode = .center
        titleBadge.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0

        rootLayer.addSublayer(borderLayer)
        rootLayer.addSublayer(titleBadge)

        let contentView = NSView(frame: .zero)
        contentView.wantsLayer = true
        contentView.layer = rootLayer
        self.contentView = contentView
    }

    /// Highlights the specified rect and displays an optional label
    public func highlight(rect: CGRect, title: String? = nil) {
        guard let mainScreen = NSScreen.screens.first else { return }
        let screenHeight = mainScreen.frame.height

        let appKitRect = NSRect(
            x: rect.origin.x,
            y: screenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        self.setFrame(appKitRect, display: true)
        borderLayer.frame = NSRect(origin: .zero, size: appKitRect.size)

        if let title = title, !title.isEmpty {
            let badgeWidth = min(max(CGFloat(title.count * 8) + 16, 120), appKitRect.width - 20)
            titleBadge.string = title
            titleBadge.frame = CGRect(x: 10, y: appKitRect.height - 28, width: badgeWidth, height: 20)
            titleBadge.isHidden = false
        } else {
            titleBadge.isHidden = true
        }

        CATransaction.commit()

        if !self.isVisible {
            self.orderFront(nil)
        }
    }

    /// Hides the highlight border
    public func dismiss() {
        self.orderOut(nil)
    }
}
