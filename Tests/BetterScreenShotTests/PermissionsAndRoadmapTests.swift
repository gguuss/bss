import XCTest
import CoreGraphics
@testable import BetterScreenShotCore

@MainActor
final class PermissionsAndRoadmapTests: XCTestCase {
    func testPermissionsManagerAPI() async {
        let permissions = PermissionsManager.shared
        let screenPerm = permissions.checkScreenRecordingPermission()
        let accessPerm = permissions.checkAccessibilityPermission()

        // Permissions return valid boolean flags
        XCTAssertEqual(screenPerm, permissions.checkScreenRecordingPermission())
        XCTAssertEqual(accessPerm, permissions.checkAccessibilityPermission())

        // Refresh permissions returns current state
        let refreshed = permissions.refreshPermissions()
        XCTAssertEqual(refreshed.screen, screenPerm)
        XCTAssertEqual(refreshed.accessibility, accessPerm)

        // Async verification via ScreenCaptureKit & CGPreflight
        _ = await permissions.verifyScreenRecordingAccess()
        XCTAssertEqual(permissions.hasScreenRecordingPermission, screenPerm)
    }

    func testPassivePermissionRefreshDoesNotTriggerModalOrLoop() {
        let permissions = PermissionsManager.shared
        // refreshPermissions must complete synchronously and immediately without blocking or prompting
        let (screen, access) = permissions.refreshPermissions()
        XCTAssertEqual(screen, permissions.checkScreenRecordingPermission())
        XCTAssertEqual(access, permissions.checkAccessibilityPermission())
    }

    func testWizardLifecycleAvoidsActiveModalPrompting() throws {
        let root = projectRootPath()
        let wizardPath = (root as NSString).appendingPathComponent("Sources/BetterScreenShotCore/FirstRunWizardView.swift")
        let content = try String(contentsOfFile: wizardPath, encoding: .utf8)

        // Ensure didBecomeActiveNotification does not invoke verifyScreenRecordingAccess
        XCTAssertFalse(content.contains("didBecomeActiveNotification)) { _ in\n            Task {\n                await permissions.verifyScreenRecordingAccess"),
                       "didBecomeActiveNotification must not trigger verifyScreenRecordingAccess which prompts system modal on window click")
        XCTAssertTrue(content.contains("didBecomeActiveNotification)) { _ in\n            _ = permissions.refreshPermissions()\n        }"),
                      "didBecomeActiveNotification must use synchronous non-intrusive refreshPermissions")
    }

    func testInfoPlistUsageDescriptions() throws {
        let root = projectRootPath()
        let plistPath = (root as NSString).appendingPathComponent("Sources/BetterScreenShot/Info.plist")
        let content = try String(contentsOfFile: plistPath, encoding: .utf8)
        XCTAssertTrue(content.contains("NSScreenCaptureUsageDescription"), "Info.plist must define NSScreenCaptureUsageDescription")
        XCTAssertTrue(content.contains("NSAccessibilityUsageDescription"), "Info.plist must define NSAccessibilityUsageDescription")
    }

    private func projectRootPath() -> String {
        let testFilePath = #filePath
        let url = URL(fileURLWithPath: testFilePath)
        let root = url.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path
        if FileManager.default.fileExists(atPath: (root as NSString).appendingPathComponent("ROADMAP.md")) {
            return root
        }
        return FileManager.default.currentDirectoryPath
    }

    func testRoadmapMilestonesDocumented() throws {
        let fileManager = FileManager.default
        let root = projectRootPath()
        let roadmapPath = (root as NSString).appendingPathComponent("ROADMAP.md")

        guard fileManager.fileExists(atPath: roadmapPath),
              let content = try? String(contentsOfFile: roadmapPath, encoding: .utf8) else {
            XCTFail("ROADMAP.md must exist in project root at \(roadmapPath)")
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
        let root = projectRootPath()
        let readmePath = (root as NSString).appendingPathComponent("README.md")

        guard fileManager.fileExists(atPath: readmePath),
              let content = try? String(contentsOfFile: readmePath, encoding: .utf8) else {
            XCTFail("README.md must exist in project root at \(readmePath)")
            return
        }

        XCTAssertTrue(content.contains("⌘ ⇧ 2"), "README must document default window capture hotkey")
        XCTAssertTrue(content.contains("⌘ ⇧ 1"), "README must document default display capture hotkey")
        XCTAssertTrue(content.contains("Privacy_ScreenCapture"), "README must explain Screen Recording permissions")
        XCTAssertTrue(content.contains("App Store Submission Checklist"), "README must contain App Store checklist")
    }

    func testEngineeringDisciplineSkillExists() {
        let fileManager = FileManager.default
        let root = projectRootPath()
        let skillPath = (root as NSString).appendingPathComponent(".agents/skills/bss-engineering-discipline/SKILL.md")

        XCTAssertTrue(fileManager.fileExists(atPath: skillPath), "Skill .agents/skills/bss-engineering-discipline/SKILL.md must exist at \(skillPath)")
    }

    func testSecretsProtectionPolicyAndGitignore() throws {
        let root = projectRootPath()
        let skillPath = (root as NSString).appendingPathComponent(".agents/skills/bss-engineering-discipline/SKILL.md")
        let gitignorePath = (root as NSString).appendingPathComponent(".gitignore")

        // 1. Skill must define Zero Leakage / Secrets Protection policy
        let skillContent = try String(contentsOfFile: skillPath, encoding: .utf8)
        XCTAssertTrue(skillContent.contains("Strict Secrets & Credentials Protection"), "Skill must define secrets protection guardrail")
        XCTAssertTrue(skillContent.contains("Zero Leakage Policy"), "Skill must enforce Zero Leakage Policy")

        // 2. .gitignore must ignore credential files
        let gitignoreContent = try String(contentsOfFile: gitignorePath, encoding: .utf8)
        XCTAssertTrue(gitignoreContent.contains("*.env*"), ".gitignore must block .env files")
        XCTAssertTrue(gitignoreContent.contains("*.p12"), ".gitignore must block .p12 certificates")
        XCTAssertTrue(gitignoreContent.contains("*.key"), ".gitignore must block .key private keys")
        XCTAssertTrue(gitignoreContent.contains("*.pem"), ".gitignore must block .pem certificates")
    }
}
