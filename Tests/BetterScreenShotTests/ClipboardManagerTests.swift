import XCTest
import AppKit
@testable import BetterScreenShotCore

@MainActor
final class ClipboardManagerTests: XCTestCase {
    func testCopyToClipboardWithNSImage() {
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.systemRed.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        let success = ClipboardManager.shared.copyToClipboard(image: image, playSound: false)
        XCTAssertTrue(success, "Should successfully copy image to pasteboard")

        let pasteboard = NSPasteboard.general
        let types = pasteboard.types ?? []

        XCTAssertTrue(types.contains(.png) || types.contains(.tiff), "Pasteboard should contain PNG or TIFF representation")
        XCTAssertTrue(ClipboardManager.shared.hasImageInClipboard, "hasImageInClipboard should report true")
    }

    func testCopyToClipboardWithCGImage() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: 50,
            height: 50,
            bitsPerComponent: 8,
            bytesPerRow: 50 * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            XCTFail("Failed to create CGContext")
            return
        }

        context.setFillColor(NSColor.systemBlue.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 50, height: 50))

        guard let cgImage = context.makeImage() else {
            XCTFail("Failed to create CGImage")
            return
        }

        let success = ClipboardManager.shared.copyToClipboard(cgImage: cgImage, playSound: false)
        XCTAssertTrue(success, "Should successfully copy CGImage to pasteboard")
        XCTAssertTrue(ClipboardManager.shared.hasImageInClipboard)
    }
}
