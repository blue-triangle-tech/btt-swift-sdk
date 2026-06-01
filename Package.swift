// swift-tools-version:5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "blue-triangle",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "BlueTriangle",
            targets: ["BlueTriangle"]
        ),
        // ── Plugin exposed to app developers ──────────────────────
        .plugin(
            name: "BTTInstrumentorPlugin",
            targets: ["BTTInstrumentorPlugin"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "509.0.0"
        )
    ],
    targets: [
        .macro(
            name: "BTTMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "BTTMacros",
            dependencies: ["BTTMacrosPlugin"]
        ),
        .target(
            name: "BlueTriangle",
            dependencies: ["Backtrace", "AppEventLogger", "BTTMacros"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .binaryTarget(
            name: "BTTInstrumentor",
            path: "Sources/Artifacts/BTTInstrumentor.artifactbundle"
        ),
        .plugin(
            name: "BTTInstrumentorPlugin",
            capability: .command(
                intent: .custom(
                    verb: "btt-inject",
                    description: "Inject @BTTTrackScreen into SwiftUI views for automatic screen tracking"
                ),
                permissions: [
                    .writeToPackageDirectory(
                        reason: "BTTInstrumentor needs to inject @BTTTrackScreen into SwiftUI source files"
                    )
                ]
            ),
            dependencies: ["BTTInstrumentor"]
        ),
        .target(name: "Backtrace"),
        .target(name: "AppEventLogger"),
        .testTarget(name: "BlueTriangleTests", dependencies: ["BlueTriangle"]),
        .testTarget(name: "ObjcCompatibilityTests", dependencies: ["BlueTriangle"])
    ]
)
