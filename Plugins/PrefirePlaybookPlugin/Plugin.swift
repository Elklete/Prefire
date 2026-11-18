import Foundation
import PackagePlugin

@main
struct PrefirePlaybookPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let executable = try context.tool(named: "PrefireGeneratorTool").url

        let cachePath = context.pluginWorkDirectoryURL.appending(path: "Cache")
        let outputPath = context.pluginWorkDirectoryURL.appending(path: "Generated")
        let outputFile = outputPath.appending(path: "PreviewModels.generated.swift")
        let targetPath = String(describing: target.directory)

        var arguments: [String] = [
            "playbook",
            "--output", outputPath.path,
            "--target-path", targetPath,
            "--config", targetPath,
            "--cache-base-path", cachePath.path,
            "--verbose",
        ]

        let sources = (target as? SwiftSourceModuleTarget)?.sourceFiles.filter { $0.type == .source }.map(\.url.path)
        arguments.append(contentsOf: sources ?? [targetPath])

        let inputFiles = generatorInputs(
            sourceFiles: swiftSourceFiles(in: target),
            configurationRoots: [targetDirectoryURL(target)]
        )

        return [
            .buildCommand(
                displayName: "Running Prefire",
                executable: executable,
                arguments: arguments,
                inputFiles: inputFiles,
                outputFiles: [outputFile]
            ),
        ]
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension PrefirePlaybookPlugin: XcodeBuildToolPlugin {
        func createBuildCommands(context: XcodeProjectPlugin.XcodePluginContext, target: XcodeProjectPlugin.XcodeTarget) throws -> [PackagePlugin.Command] {
            let executable = try context.tool(named: "PrefireGeneratorTool").url

            let cachePath = context.pluginWorkDirectoryURL.appending(path: "Cache")
            let outputPath = context.pluginWorkDirectoryURL.appending(path: "Generated")
            let outputFile = outputPath.appending(path: "PreviewModels.generated.swift")
            let targetPath = context.xcodeProject.directoryURL.appending(path: target.displayName)

            var arguments: [String] = [
                "playbook",
                "--output", outputPath.path,
                "--target-path", targetPath.path,
                "--config", context.xcodeProject.directoryURL.path,
                "--cache-base-path", cachePath.path,
                "--verbose",
            ]

            let sources = target.inputFiles.filter { $0.type == .source }.map { $0.url.path }
            arguments.append(contentsOf: sources)

            let inputFiles = generatorInputs(
                sourceFiles: target.inputFiles.filter { $0.type == .source }.map(\.url),
                configurationRoots: [
                    context.xcodeProject.directoryURL,
                    targetPath,
                ]
            )

            return [
                .buildCommand(
                    displayName: "Running Prefire Playbook",
                    executable: executable,
                    arguments: arguments,
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
