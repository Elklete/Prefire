// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PluginIntegration",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(name: "Prefire", path: "../.."),
    ],
    targets: [
        .target(
            name: "PluginFixtureApp",
            dependencies: ["Prefire"],
            plugins: [
                .plugin(name: "PrefirePlaybookPlugin", package: "Prefire"),
            ]
        ),
        .testTarget(
            name: "PluginFixtureAppTests",
            dependencies: ["PluginFixtureApp"],
            plugins: [
                .plugin(name: "PrefireTestsPlugin", package: "Prefire"),
            ]
        ),
    ]
)
