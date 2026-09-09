import XCTest
import AppKit
import ScreenCaptureKit
@testable import BetterScreenShotCore

@MainActor
final class CaptureRegressionTests: XCTestCase {

    /// Regression Test: Ensures isolated pasteboard usage never touches NSPasteboard.general
    /// This directly prevents the bug where test artifacts (solid red test bitmaps) polluted the user's pasteboard.
    func testIsolatedPasteboardDoesNotPolluteGeneralPasteboard() {
        let generalPB = NSPasteboard.general
        let initialChangeCount = generalPB.changeCount
        
        let isolatedPB = NSPasteboard.withUniqueName()
        let size = NSSize(width: 50, height: 50)
        let redImage = NSImage(size: size)
        redImage.lockFocus()
        NSColor.systemRed.setFill()
        NSRect(origin: .zero, size: size).fill()
        redImage.unlockFocus()

        let success = ClipboardManager.shared.copyToClipboard(image: redImage, to: isolatedPB, playSound: false)
        XCTAssertTrue(success, "Writing to isolated pasteboard must succeed")
        
        // Ensure general pasteboard was untouched
        XCTAssertEqual(
            generalPB.changeCount,
            initialChangeCount,
            "Writing to isolated pasteboard must NEVER alter NSPasteboard.general changeCount"
        )
        XCTAssertTrue(ClipboardManager.shared.hasImageInClipboard(in: isolatedPB))
    }

    /// Regression Test: Ensures HighlightOverlayWindow dismisses immediately and leaves no visible trace
    func testHighlightOverlayWindowDismissal() {
        let overlay = HighlightOverlayWindow()
        let testRect = CGRect(x: 100, y: 100, width: 300, height: 200)
        
        overlay.highlight(rect: testRect)
        XCTAssertTrue(overlay.isVisible, "Overlay should be visible after highlight")
        
        overlay.dismiss()
        XCTAssertFalse(overlay.isVisible, "Overlay must immediately be non-visible after dismiss")
    }

    /// Regression Test: Ensures CaptureEngine ScreenCaptureKit integration APIs are functional
    func testCaptureEngineAPIs() async {
        let engine = CaptureEngine.shared
        
        // Window picker selection simulation
        let detectedWindow = DetectedWindow(
            windowID: 999999,
            ownerName: "TestApp",
            title: "Test Window",
            bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            layer: 0
        )
        
        // Capture call should not crash, returning either a valid image or nil if permissions/windows aren't active in headless CI
        _ = await engine.captureWindow(windowID: detectedWindow.windowID)
        _ = await engine.captureMainDisplay()
    }

    /// Regression Test: Verifies that Rule 7 (Bug Regression Guardrail) is documented in SKILL.md
    func testEngineeringDisciplineSkillRule7RegressionGuardrailExists() throws {
        let skillPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Tests/BetterScreenShotTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Repository Root
            .appendingPathComponent(".agents/skills/bss-engineering-discipline/SKILL.md")
        
        let content = try String(contentsOf: skillPath, encoding: .utf8)
        XCTAssertTrue(content.contains("### 7. Bug Regression Guardrail"), "SKILL.md must define Rule 7: Bug Regression Guardrail")
        XCTAssertTrue(content.contains("Clipboard Isolation"), "SKILL.md must document Clipboard Isolation requirement")
        XCTAssertTrue(content.contains("Capture Integrity & Sandboxing"), "SKILL.md must document ScreenCaptureKit capture integrity")
    }
}
