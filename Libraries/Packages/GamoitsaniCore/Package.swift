// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GamoitsaniCore",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "GamoitsaniCore", targets: ["GamoitsaniCore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GamoitsaniCore",
            dependencies: [],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GamoitsaniCoreTests",
            dependencies: ["GamoitsaniCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
