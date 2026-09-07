// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GamoitsaniCapture",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "GamoitsaniCapture", targets: ["GamoitsaniCapture"])
    ],
    dependencies: [],
    targets: [
        // Deliberately no dependency on AVFoundation, Photos or the app. This package
        // decides *what a clip contains and whether it is worth keeping*; the app owns the
        // camera, the exporter and the photo library. That is what makes the rules
        // testable without a device, a permission prompt or a running game.
        .target(
            name: "GamoitsaniCapture",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GamoitsaniCaptureTests",
            dependencies: ["GamoitsaniCapture"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
