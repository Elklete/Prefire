import Foundation
import PackagePlugin

@main
struct PrefirePlaybookPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let executable = try context.tool(named: "PrefireGeneratorTool").url

        let cachePath = context.pluginWorkDirectoryURL.appending(path: "Cache")
        let outputPath = context.pluginWorkDirectoryURL.appending(path: "Generated")
        var arguments: [String] = [
            "playbook",
            "--output", outputPath.path,
            "--config", String(describing: target.directory),
            "--cache-base-path", cachePath.path,
            "--verbose",
        ]

        let sources = (target as? SwiftSourceModuleTarget)?.sourceFiles.filter { $0.type == .source }.map(\.url.path)
        arguments.append(contentsOf: sources ?? [String(describing: target.directory)])

        return [
            .buildCommand(
                displayName: "Running Prefire",
                executable: executable,
                arguments: arguments,
                inputFiles: (sources ?? [String(describing: target.directory)]).map { URL(fileURLWithPath: $0) },
                outputFiles: [outputPath.appending(path: "PreviewModels.generated.swift")]
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
            var arguments: [String] = [
                "playbook",
                "--output", outputPath.path,
                "--config", context.xcodeProject.directoryURL.path,
                "--cache-base-path", cachePath.path,
                "--verbose",
            ]

            let sources = target.inputFiles.filter { $0.type == .source }.map { $0.url.path }
            arguments.append(contentsOf: sources)

            return [
                .buildCommand(
                    displayName: "Running Prefire Playbook",
                    executable: executable,
                    arguments: arguments,
                    inputFiles: sources.map { URL(fileURLWithPath: $0) },
                    outputFiles: [outputPath.appending(path: "PreviewModels.generated.swift")]
                ),
            ]
        }
    }
#endif
