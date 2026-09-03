// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GamoitsaniAds",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "GamoitsaniAds", targets: ["GamoitsaniAds"])
    ],
    dependencies: [],
    targets: [
        // Deliberately no dependency on any ad SDK. This package decides *whether* an ad
        // may show; the app owns the adapter that shows it. That is what makes the rules
        // testable without a network, a consent form or a simulator.
        .target(
            name: "GamoitsaniAds",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GamoitsaniAdsTests",
            dependencies: ["GamoitsaniAds"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
