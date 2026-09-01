// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GamoitsaniData",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GamoitsaniData", targets: ["GamoitsaniData"])
    ],
    dependencies: [
        .package(path: "../GamoitsaniCore")],
    targets: [
        .target(
            name: "GamoitsaniData",
            dependencies: [
                .product(name: "GamoitsaniCore", package: "GamoitsaniCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GamoitsaniDataTests",
            dependencies: ["GamoitsaniData"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
