import XCTest
import Carbon
@testable import BetterScreenShotCore

@MainActor
final class HotkeyManagerTests: XCTestCase {
    func testDefaultHotkeyCombinations() {
        let windowCombo = HotkeyCombination.defaultWindowCapture
        XCTAssertEqual(windowCombo.keyCode, 19, "Window capture default keycode should be 19 ('2')")
        XCTAssertEqual(windowCombo.modifiers, UInt32(cmdKey | shiftKey))
        XCTAssertTrue(windowCombo.displayString.contains("⌘"))
        XCTAssertTrue(windowCombo.displayString.contains("⇧"))
        XCTAssertTrue(windowCombo.displayString.contains("2"))

        let displayCombo = HotkeyCombination.defaultDisplayCapture
        XCTAssertEqual(displayCombo.keyCode, 18, "Display capture default keycode should be 18 ('1')")
        XCTAssertEqual(displayCombo.modifiers, UInt32(cmdKey | shiftKey))
        XCTAssertTrue(displayCombo.displayString.contains("⌘"))
        XCTAssertTrue(displayCombo.displayString.contains("⇧"))
        XCTAssertTrue(displayCombo.displayString.contains("1"))
    }

    func testHotkeySerialization() throws {
        let custom = HotkeyCombination(keyCode: 20, modifiers: UInt32(cmdKey | optionKey))
        let encoder = JSONEncoder()
        let data = try encoder.encode(custom)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HotkeyCombination.self, from: data)

        XCTAssertEqual(custom, decoded)
    }

    func testHotkeyRegistrationLifecycle() {
        let manager = HotkeyManager.shared
        manager.registerWindowCapture()
        manager.registerDisplayCapture()
        manager.unregisterAll()
        manager.registerWindowCapture()
        manager.unregisterAll()
    }
}
