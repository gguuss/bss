import XCTest

@MainActor
final class XcodeGenBlueprintTests: XCTestCase {
    private func projectRootPath() -> String {
        let testFilePath = #filePath
        let url = URL(fileURLWithPath: testFilePath)
        let root = url.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path
        if FileManager.default.fileExists(atPath: (root as NSString).appendingPathComponent("project.yml")) {
            return root
        }
        return FileManager.default.currentDirectoryPath
    }

    func testXcodeGenBlueprintExistsAndConfigured() throws {
        let root = projectRootPath()
        let blueprintPath = (root as NSString).appendingPathComponent("project.yml")

        guard FileManager.default.fileExists(atPath: blueprintPath),
              let content = try? String(contentsOfFile: blueprintPath, encoding: .utf8) else {
            XCTFail("project.yml XcodeGen blueprint must exist at \(blueprintPath)")
            return
        }

        XCTAssertTrue(content.contains("BetterScreenShot"), "Blueprint must define BetterScreenShot target")
        XCTAssertTrue(content.contains("BetterScreenShotCore"), "Blueprint must define BetterScreenShotCore framework")
        XCTAssertTrue(content.contains("BetterScreenShotTests"), "Blueprint must define BetterScreenShotTests target")
        XCTAssertTrue(content.contains("LSUIElement"), "Blueprint must configure LSUIElement for menubar app")
        XCTAssertTrue(content.contains("ScreenCaptureKit") || content.contains("deploymentTarget"), "Blueprint must configure deployment target")
    }

    func testXcodeProjectExists() {
        let root = projectRootPath()
        let xcodeprojPath = (root as NSString).appendingPathComponent("BetterScreenShot.xcodeproj")
        XCTAssertTrue(FileManager.default.fileExists(atPath: xcodeprojPath), "BetterScreenShot.xcodeproj must be generated and present")
    }
}
