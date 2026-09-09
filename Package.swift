// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BetterScreenShot",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "BetterScreenShot",
            targets: ["BetterScreenShot"]
        ),
        .library(
            name: "BetterScreenShotCore",
            targets: ["BetterScreenShotCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BetterScreenShotCore",
            dependencies: [],
            path: "Sources/BetterScreenShotCore"
        ),
        .executableTarget(
            name: "BetterScreenShot",
            dependencies: ["BetterScreenShotCore"],
            path: "Sources/BetterScreenShot"
        ),
        .testTarget(
            name: "BetterScreenShotTests",
            dependencies: ["BetterScreenShotCore"],
            path: "Tests/BetterScreenShotTests"
        )
    ]
)
