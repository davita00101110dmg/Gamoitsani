// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GamoitsaniEngine",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GamoitsaniEngine", targets: ["GamoitsaniEngine"])
    ],
    dependencies: [
        .package(path: "../GamoitsaniCore")],
    targets: [
        .target(
            name: "GamoitsaniEngine",
            dependencies: [
                .product(name: "GamoitsaniCore", package: "GamoitsaniCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GamoitsaniEngineTests",
            dependencies: ["GamoitsaniEngine"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
