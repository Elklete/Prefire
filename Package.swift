// swift-tools-version: 6.0

import PackageDescription

// This is the only production build graph. `PrefireGeneratorTool` is an internal
// executable target whose command is `prefire`. Its distinct target name avoids
// a case-insensitive build-path collision with the public `Prefire` module.
let package = Package(
    name: "Prefire",
    platforms: [.iOS(.v14), .macOS(.v13), .watchOS(.v7)],
    products: [
        .library(name: "Prefire", targets: ["Prefire"]),
        .plugin(name: "PrefirePlaybookPlugin", targets: ["PrefirePlaybookPlugin"]),
        .plugin(name: "PrefireTestsPlugin", targets: ["PrefireTestsPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.2.3"),
        .package(url: "https://github.com/kylef/PathKit.git", exact: "1.0.1"),
        .package(url: "https://github.com/stencilproject/Stencil.git", exact: "0.15.1"),
        .package(url: "https://github.com/SwiftGen/StencilSwiftKit.git", exact: "2.10.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", exact: "1.19.6"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "600.0.1"),
    ],
    targets: [
        .target(name: "Prefire"),
        .target(
            name: "PrefireCore",
            dependencies: [
                "PathKit",
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "StencilSwiftKit", package: "StencilSwiftKit"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .executableTarget(
            name: "PrefireGeneratorTool",
            dependencies: ["PrefireGeneratorSupport"],
            path: "Sources/PrefireGeneratorTool",
            packageAccess: false
        ),
        .target(
            name: "PrefireGeneratorSupport",
            dependencies: [
                "PrefireCore",
                "PathKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .plugin(
            name: "PrefirePlaybookPlugin",
            capability: .buildTool(),
            dependencies: ["PrefireGeneratorTool"]
        ),
        .plugin(
            name: "PrefireTestsPlugin",
            capability: .buildTool(),
            dependencies: ["PrefireGeneratorTool"]
        ),
        .testTarget(
            name: "PrefireGeneratorTests",
            dependencies: ["PrefireCore", "PrefireGeneratorSupport"]
        ),
        // This local fixture runs both plugins through SwiftPM without adding a
        // consumer package or a second dependency graph to the repository.
        .target(
            name: "PluginFixtureApp",
            dependencies: ["Prefire"],
            path: "Fixtures/PluginIntegration/Sources/FixtureApp",
            plugins: [.plugin(name: "PrefirePlaybookPlugin")]
        ),
        .testTarget(
            name: "PluginFixtureTests",
            dependencies: [
                "PluginFixtureApp",
                "Prefire",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Fixtures/PluginIntegration/Tests/FixtureAppTests",
            plugins: [.plugin(name: "PrefireTestsPlugin")]
        ),
    ]
)
