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

    /// Regression Test: Ensures BullseyeTrackingOverlayWindow presents and dismisses cleanly
    func testBullseyeTrackingOverlayPresentationAndDismissal() {
        let overlay = BullseyeTrackingOverlayWindow.shared
        overlay.show(initialPoint: CGPoint(x: 100, y: 100), isDrag: false)
        XCTAssertTrue(overlay.isVisible, "Tracking overlay should be visible after show")

        overlay.dismiss()
        XCTAssertFalse(overlay.isVisible, "Tracking overlay must be non-visible after dismiss")
    }

    /// Regression Test: Ensures initial mouseUp from clicking menu item does not prematurely terminate Bullseye session
    func testBullseyeInitialMenuClickMouseUpDoesNotAbortSession() {
        let picker = WindowPicker.shared
        let clickPoint = CGPoint(x: 1200, y: 20)

        picker.startBullseyeSession(initialPoint: clickPoint, isDrag: false) { _ in }
        XCTAssertTrue(picker.isPicking, "WindowPicker must be actively picking after start")
        XCTAssertTrue(BullseyeTrackingOverlayWindow.shared.isVisible, "Tracking overlay must be visible")

        // Simulating release of the initial menu item click
        picker.handleDragReleased(at: clickPoint, isDragging: false)
        XCTAssertTrue(picker.isPicking, "Session must NOT abort on mouseUp if drag distance was minimal (click mode)")

        picker.cancelBullseyeSession()
        XCTAssertFalse(picker.isPicking, "Session must be inactive after cancel")
        XCTAssertFalse(BullseyeTrackingOverlayWindow.shared.isVisible, "Tracking overlay must be hidden after cancel")
    }

    /// Regression Test: Ensures selecting a window immediately dismisses all overlays and resets picker state
    func testBullseyeWindowSelectionDismissesOverlays() {
        let picker = WindowPicker.shared
        picker.startBullseyeSession { _ in }
        XCTAssertTrue(picker.isPicking)

        let mockWindow = DetectedWindow(
            windowID: 88888,
            ownerName: "TestApp",
            title: "TestWindow",
            bounds: CGRect(x: 100, y: 100, width: 400, height: 300),
            layer: 0
        )

        picker.finishWithWindow(mockWindow)
        XCTAssertFalse(picker.isPicking, "isPicking must be reset to false immediately on selection")
        XCTAssertFalse(BullseyeTrackingOverlayWindow.shared.isVisible, "Tracking overlay must be dismissed immediately")
        XCTAssertFalse(HighlightOverlayWindow.shared.isVisible, "Highlight overlay must be dismissed immediately")
    }

    /// Regression Test: Ensures Escape key cancels Bullseye session cleanly
    func testBullseyeCancelOnEscape() {
        let picker = WindowPicker.shared
        picker.startBullseyeSession { _ in }
        XCTAssertTrue(picker.isPicking)

        picker.cancelBullseyeSession()
        XCTAssertFalse(picker.isPicking, "isPicking must be false after cancel")
        XCTAssertFalse(BullseyeTrackingOverlayWindow.shared.isVisible)
        XCTAssertFalse(HighlightOverlayWindow.shared.isVisible)
    }

    /// Regression Test: Ensures PermissionsManager verifies Screen Recording via both preflight and ScreenCaptureKit
    func testScreenRecordingPermissionPreflightAndVerification() async {
        let permissions = PermissionsManager.shared
        let preflight = permissions.checkScreenRecordingPermission()
        
        let verified = await permissions.verifyScreenRecordingAccess()
        // If preflight is true, verification must also be true
        if preflight {
            XCTAssertTrue(verified, "verifyScreenRecordingAccess must return true when preflight is true")
        }
        XCTAssertEqual(permissions.hasScreenRecordingPermission, verified)
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
        XCTAssertTrue(content.contains("Bullseye Interaction & Event Shielding"), "SKILL.md must document Bullseye Interaction & Event Shielding")
        XCTAssertTrue(content.contains("Permissions Management & TCC Handling"), "SKILL.md must document Permissions Management & TCC Handling")
    }
}
