// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GamoitsaniL10n",
    // Required for the string catalogue to be compiled into per-language .lproj bundles.
    // Without it SPM ships the .xcstrings unlocalised, every language resolves to the
    // source text, and an in-app language picker silently does nothing.
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
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
