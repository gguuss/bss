import AppKit
import UniformTypeIdentifiers

@MainActor
public final class ClipboardManager: @unchecked Sendable {
    public static let shared = ClipboardManager()

    public init() {}

    /// Copies an NSImage to the specified pasteboard (defaults to .general) as both TIFF and PNG representations.
    @discardableResult
    public func copyToClipboard(image: NSImage, to pasteboard: NSPasteboard = .general, playSound: Bool = true) -> Bool {
        pasteboard.clearContents()

        var didWrite = false

        // 1. Write PNG representation if available
        if let tiffData = image.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            pasteboard.setData(pngData, forType: .png)
            didWrite = true
        }

        // 2. Write TIFF representation
        if let tiffData = image.tiffRepresentation {
            pasteboard.setData(tiffData, forType: .tiff)
            didWrite = true
        }

        // 3. Fallback writing using writeObjects
        if !didWrite {
            didWrite = pasteboard.writeObjects([image])
        }

        if didWrite && playSound && pasteboard == .general {
            playCaptureSound()
        }

        return didWrite
    }

    /// Copies a CGImage to the specified pasteboard (defaults to .general)
    @discardableResult
    public func copyToClipboard(cgImage: CGImage, to pasteboard: NSPasteboard = .general, playSound: Bool = true) -> Bool {
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        return copyToClipboard(image: nsImage, to: pasteboard, playSound: playSound)
    }

    /// Plays the standard macOS screen capture shutter sound
    public func playCaptureSound() {
        if let sound = NSSound(named: "Screen Capture") {
            sound.play()
        } else if let sound = NSSound(named: "Tink") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    /// Checks if the specified pasteboard contains image data
    public func hasImageInClipboard(in pasteboard: NSPasteboard = .general) -> Bool {
        return pasteboard.canReadItem(withDataConformingToTypes: [
            NSPasteboard.PasteboardType.png.rawValue,
            NSPasteboard.PasteboardType.tiff.rawValue
        ])
    }

    /// Convenience getter checking the general pasteboard
    public var hasImageInClipboard: Bool {
        return hasImageInClipboard(in: .general)
    }
}
