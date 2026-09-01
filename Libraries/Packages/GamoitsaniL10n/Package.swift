// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GamoitsaniL10n",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "GamoitsaniL10n", targets: ["GamoitsaniL10n"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GamoitsaniL10n",
            dependencies: [],
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GamoitsaniL10nTests",
            dependencies: ["GamoitsaniL10n"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
