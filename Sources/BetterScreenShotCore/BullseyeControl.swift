import AppKit

public final class BullseyeMenuItemView: NSView {
    public var onSelect: ((CGPoint) -> Void)?

    private let titleLabel = NSTextField(labelWithString: "Bullseye Window Capture")
    private let hintLabel = NSTextField(labelWithString: "Drag onto window or click")
    private let shortcutLabel = NSTextField(labelWithString: "⌘⇧2")
    private let iconImageView = NSImageView()
    private var isHighlighted = false

    public override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 44))
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true

        // Bullseye Icon: concentric circles target
        if let targetImage = NSImage(systemSymbolName: "target", accessibilityDescription: "Bullseye Target") {
            let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            iconImageView.image = targetImage.withSymbolConfiguration(config)
            iconImageView.contentTintColor = .systemRed
        }
        iconImageView.frame = NSRect(x: 14, y: 12, width: 20, height: 20)
        addSubview(iconImageView)

        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.frame = NSRect(x: 44, y: 22, width: 160, height: 16)
        addSubview(titleLabel)

        // Hint / Subtitle
        hintLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.frame = NSRect(x: 44, y: 6, width: 160, height: 14)
        addSubview(hintLabel)

        // Shortcut
        shortcutLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        shortcutLabel.textColor = .secondaryLabelColor
        shortcutLabel.alignment = .right
        shortcutLabel.frame = NSRect(x: 200, y: 14, width: 48, height: 16)
        addSubview(shortcutLabel)

        // Tracking area for hover highlight
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    public override func mouseEntered(with event: NSEvent) {
        isHighlighted = true
        needsDisplay = true
        titleLabel.textColor = .selectedMenuItemTextColor
        hintLabel.textColor = .selectedMenuItemTextColor.withAlphaComponent(0.8)
        shortcutLabel.textColor = .selectedMenuItemTextColor.withAlphaComponent(0.8)
    }

    public override func mouseExited(with event: NSEvent) {
        isHighlighted = false
        needsDisplay = true
        titleLabel.textColor = .labelColor
        hintLabel.textColor = .secondaryLabelColor
        shortcutLabel.textColor = .secondaryLabelColor
    }

    public override func draw(_ dirtyRect: NSRect) {
        if isHighlighted {
            NSColor.selectedContentBackgroundColor.setFill()
            bounds.fill()
        } else {
            super.draw(dirtyRect)
        }
    }

    // Support click or drag directly from the menu item
    public override func mouseDown(with event: NSEvent) {
        let clickPoint = NSEvent.mouseLocation
        // Dismiss the menu and start the bullseye session immediately
        if let menu = enclosingMenuItem?.menu {
            menu.cancelTracking()
        }
        onSelect?(clickPoint)
    }
}
