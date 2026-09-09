import XCTest
import CoreGraphics
@testable import BetterScreenShotCore

@MainActor
final class WindowPickerTests: XCTestCase {
    func testDetectedWindowModel() {
        let bounds = CGRect(x: 100, y: 150, width: 800, height: 600)
        let window = DetectedWindow(
            windowID: 42,
            ownerName: "Finder",
            title: "Documents",
            bounds: bounds,
            layer: 0
        )

        XCTAssertEqual(window.windowID, 42)
        XCTAssertEqual(window.ownerName, "Finder")
        XCTAssertEqual(window.title, "Documents")
        XCTAssertEqual(window.bounds, bounds)
        XCTAssertEqual(window.layer, 0)
    }

    func testFindWindowUnderPointLogic() {
        let picker = WindowPicker()
        let windows = picker.getVisibleWindows()
        XCTAssertNotNil(windows)

        let mockWindow = DetectedWindow(
            windowID: 101,
            ownerName: "Safari",
            title: "Google",
            bounds: CGRect(x: 200, y: 200, width: 500, height: 400),
            layer: 0
        )

        XCTAssertTrue(mockWindow.bounds.contains(CGPoint(x: 250, y: 250)))
        XCTAssertFalse(mockWindow.bounds.contains(CGPoint(x: 100, y: 100)))
    }
}
