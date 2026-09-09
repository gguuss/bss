import XCTest
import CoreGraphics
@testable import BetterScreenShotCore

@MainActor
final class PermissionsAndRoadmapTests: XCTestCase {
    func testPermissionsManagerAPI() {
        let permissions = PermissionsManager.shared
        let screenPerm = permissions.checkScreenRecordingPermission()
        let accessPerm = permissions.checkAccessibilityPermission()

        // Permissions return valid boolean flags
        XCTAssertEqual(screenPerm, permissions.checkScreenRecordingPermission())
        XCTAssertEqual(accessPerm, permissions.checkAccessibilityPermission())
    }

    func testRoadmapMilestonesDocumented() throws {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let roadmapPath = (currentDir as NSString).appendingPathComponent("ROADMAP.md")

        guard fileManager.fileExists(atPath: roadmapPath),
              let content = try? String(contentsOfFile: roadmapPath, encoding: .utf8) else {
            XCTFail("ROADMAP.md must exist in project root")
            return
        }

        XCTAssertTrue(content.contains("v0.1.0"), "Roadmap must define v0.1.0 milestone")
        XCTAssertTrue(content.contains("v0.2.0"), "Roadmap must define v0.2.0 milestone")
        XCTAssertTrue(content.contains("v0.3.0"), "Roadmap must define v0.3.0 milestone")
        XCTAssertTrue(content.contains("v1.0.0"), "Roadmap must define v1.0.0 milestone")
        XCTAssertTrue(content.contains("v2.0.0"), "Roadmap must define v2.0.0 future milestone")
        XCTAssertTrue(content.contains("Bullseye"), "Roadmap must track Bullseye feature")
    }

    func testDocumentationIntegrity() throws {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let readmePath = (currentDir as NSString).appendingPathComponent("README.md")

        guard fileManager.fileExists(atPath: readmePath),
              let content = try? String(contentsOfFile: readmePath, encoding: .utf8) else {
            XCTFail("README.md must exist in project root")
            return
        }

        XCTAssertTrue(content.contains("⌘ ⇧ 2"), "README must document default window capture hotkey")
        XCTAssertTrue(content.contains("⌘ ⇧ 1"), "README must document default display capture hotkey")
        XCTAssertTrue(content.contains("Privacy_ScreenCapture"), "README must explain Screen Recording permissions")
        XCTAssertTrue(content.contains("App Store Submission Checklist"), "README must contain App Store checklist")
    }

    func testEngineeringDisciplineSkillExists() {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let skillPath = (currentDir as NSString).appendingPathComponent(".agents/skills/bss-engineering-discipline/SKILL.md")

        XCTAssertTrue(fileManager.fileExists(atPath: skillPath), "Skill .agents/skills/bss-engineering-discipline/SKILL.md must exist")
    }
}
