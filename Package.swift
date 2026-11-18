// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Prefire",
    platforms: [.iOS(.v14), .macOS(.v13), .watchOS(.v7)],
    products: [
        .library(name: "PrefireVoiceOver", targets: ["PrefireVoiceOver"]),
        .library(
            name: "Prefire",
            targets: ["Prefire"]
        ),
        .plugin(
            name: "PrefirePlaybookPlugin",
            targets: ["PrefirePlaybookPlugin"]
        ),
        .plugin(
            name: "PrefireTestsPlugin",
            targets: ["PrefireTestsPlugin"]
        ),
        .executable(
            name: "prefire",
            targets: ["PrefireGeneratorTool"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.2.3")),
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMinor(from: "1.0.1")),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", .upToNextMinor(from: "600.0.0")),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.1"),
        .package(url: "https://github.com/SwiftGen/StencilSwiftKit.git", from: "2.10.1"),
    ],
    targets: [
        .target(
            name: "PrefireVoiceOver",
            dependencies: ["Prefire"]
        ),
        .target(
            name: "Prefire",
            dependencies: []
        ),
        .target(
            name: "PrefireCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "StencilSwiftKit", package: "StencilSwiftKit"),
                "PathKit",
            ]
        ),
        .executableTarget(
            name: "PrefireGeneratorTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "PrefireCore",
            ]
        ),
        .testTarget(
            name: "PrefireTests",
            dependencies: ["Prefire"]
        ),
        .testTarget(
            name: "PrefireGeneratorTests",
            dependencies: ["PrefireGeneratorTool", "PrefireCore"]
        ),
        .plugin(
            name: "PrefirePlaybookPlugin",
            capability: .buildTool(),
            dependencies: [
                "PrefireGeneratorTool",
            ]
        ),
        .plugin(
            name: "PrefireTestsPlugin",
            capability: .buildTool(),
            dependencies: [
                "PrefireGeneratorTool",
            ]
        ),
    ]
)
