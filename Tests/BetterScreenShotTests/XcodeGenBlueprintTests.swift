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
        XCTAssertTrue(content.contains("INFOPLIST_FILE"), "Blueprint must specify INFOPLIST_FILE")

        XCTAssertTrue(content.contains("bundleIdPrefix: And-Friends"), "Blueprint must specify bundleIdPrefix as And-Friends")
        XCTAssertTrue(content.contains("And-Friends.Better-Screen-Shot"), "Blueprint must specify And-Friends.Better-Screen-Shot")
        XCTAssertTrue(content.contains("Screenshot to Copy and Paste"), "Blueprint must specify unique App Store title Screenshot to Copy and Paste")

        let infoPlistPath = (root as NSString).appendingPathComponent("Sources/BetterScreenShot/Info.plist")
        guard FileManager.default.fileExists(atPath: infoPlistPath),
              let plistContent = try? String(contentsOfFile: infoPlistPath, encoding: .utf8) else {
            XCTFail("Info.plist must exist at \(infoPlistPath)")
            return
        }

        XCTAssertTrue(plistContent.contains("LSApplicationCategoryType"), "Info.plist must contain LSApplicationCategoryType")
        XCTAssertTrue(plistContent.contains("public.app-category.utilities"), "Category must be public.app-category.utilities")
        XCTAssertTrue(plistContent.contains("LSUIElement"), "Info.plist must contain LSUIElement")

        let buildScriptPath = (root as NSString).appendingPathComponent("scripts/build_app.sh")
        if let scriptContent = try? String(contentsOfFile: buildScriptPath, encoding: .utf8) {
            XCTAssertTrue(scriptContent.contains("BUNDLE_ID=\"And-Friends.Better-Screen-Shot\""), "build_app.sh must use And-Friends.Better-Screen-Shot bundle ID")
        }
    }

    func testXcodeProjectExists() {
        let root = projectRootPath()
        let xcodeprojPath = (root as NSString).appendingPathComponent("BetterScreenShot.xcodeproj")
        XCTAssertTrue(FileManager.default.fileExists(atPath: xcodeprojPath), "BetterScreenShot.xcodeproj must be generated and present")
    }
}
