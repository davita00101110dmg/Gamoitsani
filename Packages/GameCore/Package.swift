// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GameCore",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "GameCore", targets: ["GameCore"])
    ],
    dependencies: [],
    targets: [
        // Foundation only, and no path dependencies. The rules of play have to build and
        // test anywhere Swift runs, Linux included, without a simulator or the app.
        .target(
            name: "GameCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GameCoreTests",
            dependencies: ["GameCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
