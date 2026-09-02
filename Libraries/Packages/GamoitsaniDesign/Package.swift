// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GamoitsaniDesign",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GamoitsaniDesign", targets: ["GamoitsaniDesign"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GamoitsaniDesign",
            dependencies: [],
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GamoitsaniDesignTests",
            dependencies: ["GamoitsaniDesign"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
