// swift-tools-version:5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "blue-triangle",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "BlueTriangle",
            targets: ["BlueTriangle"]
        ),
        .library(
            name: "BTTSwiftUITracker",
            targets: ["BTTSwiftUITracker", "BlueTriangle"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "509.0.0"
        )
    ],
    targets: [
        // macros support -----------------------------------------------------------
        .macro(
            name: "BTTMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/BTTSwiftUITracker/Plugins"
        ),
        .target(
            name: "BTTSwiftUITracker",
            dependencies: [
                "BTTMacrosPlugin",
                "BlueTriangle"
            ],
            path: "Sources/BTTSwiftUITracker/Source"
        ),
        .target(
            name: "BlueTriangle",
            dependencies: ["Backtrace", "AppEventLogger"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(name: "Backtrace"),
        .target(name: "AppEventLogger"),
        .testTarget(name: "BlueTriangleTests", dependencies: ["BlueTriangle"]),
        .testTarget(name: "ObjcCompatibilityTests", dependencies: ["BlueTriangle"])
    ]
)
