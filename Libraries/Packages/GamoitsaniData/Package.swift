// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GamoitsaniData",
    platforms: [.iOS(.v18)],
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
            // .copy, not .process — the databases must reach the bundle byte-identical.
            // The whole directory, so a new language is a file drop and nothing else.
            // Not named "Resources": that collides with the bundle's own layout and
            // codesign rejects the result as a malformed bundle.
            resources: [.copy("WordFiles")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GamoitsaniDataTests",
            dependencies: ["GamoitsaniData"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
