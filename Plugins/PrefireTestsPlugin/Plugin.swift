import Foundation
import PackagePlugin

@main
struct PrefireTestsPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let executable = try context.tool(named: "PrefireBinary").url

        let cachePath = context.pluginWorkDirectoryURL.appending(path: "Cache")
        let outputPath = context.pluginWorkDirectoryURL.appending(path: "Generated")
        let outputFile = outputPath.appending(path: "PreviewTests.generated.swift")

        guard let testedTarget = try TestedTargetFinder.findTestedTarget(for: target) else {
            throw "❌ Prefire error: Cannot find target for testing. Please use `.prefire.yml` and set `target:` field."
        }

        var arguments: [String] = [
            "tests",
            "--target", testedTarget.name,
            "--test-target", target.name,
            "--output", outputPath.path,
            "--plugin-output", outputFile.path,
            "--test-target-path", String(describing: target.directory),
            "--config", testedTarget.directoryURL.path,
            "--cache-base-path", cachePath.path,
            "--verbose",
        ]

        let sources = testedTarget.sourceFiles.filter { $0.type == .source }.map(\.url.path)
        arguments.append(contentsOf: sources)

        let inputFiles = generatorInputs(
            sourceFiles: testedTarget.sourceFiles.filter { $0.type == .source }.map(\.url)
                + swiftSourceFiles(in: target),
            configurationRoots: [testedTarget.directoryURL, targetDirectoryURL(target)]
        )

        let environment = [
            "TARGET_DIR": String(describing: target.directory),
            "PACKAGE_DIR": context.package.directoryURL.path(percentEncoded: false),
        ]

        return [
            .buildCommand(
                displayName: "Running Prefire",
                executable: executable,
                arguments: arguments,
                environment: environment,
                inputFiles: inputFiles,
                outputFiles: [outputFile]
            ),
        ]
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension PrefireTestsPlugin: XcodeBuildToolPlugin {
        func createBuildCommands(context: XcodeProjectPlugin.XcodePluginContext, target: XcodeProjectPlugin.XcodeTarget) throws -> [PackagePlugin.Command] {
            let executable = try context.tool(named: "PrefireBinary").url

            let cacheURL = context.pluginWorkDirectoryURL.appending(path: "Cache")
            let outputURL = context.pluginWorkDirectoryURL.appending(path: "Generated")
            let outputFile = outputURL.appending(path: "PreviewTests.generated.swift")
            let testTagetPath = context.xcodeProject.directoryURL.appending(path: target.displayName).path

            guard let testedTarget = try TestedTargetFinder.findTestedTarget(for: target, project: context.xcodeProject) else {
                throw "Prefire cannot find target for testing. Please, use `.prefire.yml` file, for providing `Target Name`"
            }

            var arguments: [String] = [
                "tests",
                "--target", testedTarget.displayName,
                "--test-target", target.displayName,
                "--output", outputURL.path,
                "--plugin-output", outputFile.path,
                "--test-target-path", testTagetPath,
                "--config", context.xcodeProject.directoryURL.path,
                "--cache-base-path", cacheURL.path,
                "--verbose",
            ]

            let sources = testedTarget.inputFiles.filter { $0.type == .source }.map(\.url.path)
            arguments.append(contentsOf: sources)

            let inputFiles = generatorInputs(
                sourceFiles: testedTarget.inputFiles.filter { $0.type == .source }.map(\.url)
                    + target.inputFiles.filter { $0.type == .source }.map(\.url),
                configurationRoots: [
                    context.xcodeProject.directoryURL,
                    context.xcodeProject.directoryURL.appending(path: target.displayName),
                ]
            )

            let environment = [
                "PROJECT_DIR": context.xcodeProject.directoryURL.path(percentEncoded: false),
            ]

            return [
                .buildCommand(
                    displayName: "Running Prefire Tests",
                    executable: executable,
                    arguments: arguments,
                    environment: environment,
                    inputFiles: inputFiles,
                    outputFiles: [outputFile]
                ),
            ]
        }
    }
#endif

private func swiftSourceFiles(in target: Target) -> [URL] {
    (target as? SwiftSourceModuleTarget)?.sourceFiles
        .filter { $0.type == .source }
        .map(\.url) ?? []
}

private func targetDirectoryURL(_ target: Target) -> URL {
    URL(filePath: String(describing: target.directory))
}

private func generatorInputs(sourceFiles: [URL], configurationRoots: [URL]) -> [URL] {
    var inputs = Set(sourceFiles)
    let fileManager = FileManager.default

    for root in configurationRoots {
        for configurationName in [".prefire.yml", ".prefire.yaml"] {
            let configuration = root.appending(path: configurationName)
            if fileManager.fileExists(atPath: configuration.path) {
                inputs.insert(configuration)
            }
        }

        guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: nil) else {
            continue
        }

        for case let file as URL in enumerator {
            if file.hasDirectoryPath, [".build", ".git", ".swiftpm"].contains(file.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }

            if ["stencil", "swift"].contains(file.pathExtension.lowercased()) {
                inputs.insert(file)
            }
        }
    }

    return inputs.sorted { $0.path < $1.path }
}

extension String: @retroactive LocalizedError {
    public var errorDescription: String? { return self }
}
