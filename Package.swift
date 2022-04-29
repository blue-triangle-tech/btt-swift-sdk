// swift-tools-version:5.5
import PackageDescription

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
            targets: ["BlueTriangle"])
    ],
    dependencies: [
      .package(
        url: "https://github.com/apple/swift-collections.git",
        .upToNextMajor(from: "1.0.0")
      )
    ],
    targets: [
        .target(
            name: "BlueTriangle",
            dependencies: [
              .product(name: "Collections", package: "swift-collections")
            ]),
        .testTarget(
            name: "BlueTriangleTests",
            dependencies: ["BlueTriangle"]),
        .testTarget(
            name: "ObjcCompatibilityTests",
            dependencies: ["BlueTriangle"])
    ]
)
