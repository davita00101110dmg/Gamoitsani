// swift-tools-version: 5.10

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "GamoitsaniMacros",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "GamoitsaniMacros",
            targets: ["GamoitsaniMacros"]
        ),
        .executable(
            name: "GamoitsaniMacrosClient",
            targets: ["GamoitsaniMacrosClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "510.0.0"),
    ],
    targets: [
        .macro(
            name: "GamoitsaniMacrosImpl",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        .target(name: "GamoitsaniMacros", dependencies: ["GamoitsaniMacrosImpl"]),

        .executableTarget(name: "GamoitsaniMacrosClient", dependencies: ["GamoitsaniMacros"]),

        .testTarget(
            name: "GamoitsaniMacrosTests",
            dependencies: [
                "GamoitsaniMacrosImpl",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
