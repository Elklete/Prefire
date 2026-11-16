import Foundation
import PrefireCore
import PathKit

private enum Constants {
    static let defaultOutputName = "PreviewModels.generated.swift"
}

struct GeneratedPlaybookOptions {
    var sources: [Path]
    var output: Path
    var previewDefaultEnabled: Bool
    var cacheBasePath: Path
    var pluginWorkDirectory: Path
    var imports: [String]?
    var testableImports: [String]?

    init(sources: [String], output: String?, cacheBasePath: String?, config: Config?) throws {
        self.sources = sources.isEmpty ? [.current] : sources.compactMap({ Path($0) })
        guard let output else { throw GenerationInputError.missingPluginPath("--output") }
        guard let cacheBasePath else { throw GenerationInputError.missingPluginPath("--cache-base-path") }
        self.output = Path(output) + Constants.defaultOutputName
        self.cacheBasePath = Path(cacheBasePath)
        pluginWorkDirectory = try GenerationInputValidator.pluginWorkDirectory(output: Path(output), cache: self.cacheBasePath)

        previewDefaultEnabled = config?.playbook.previewDefaultEnabled ?? true

        imports = try GenerationInputValidator.moduleNames(config?.playbook.imports)
        testableImports = try GenerationInputValidator.moduleNames(config?.playbook.testableImports)
    }
}

enum GeneratePlaybookCommand {
    private enum Keys {
        static let imports = "imports"
        static let testableImports = "testableImports"
    }

    static func run(_ options: GeneratedPlaybookOptions) throws {
        try PrefireGenerator.generate(
            version: PrefireCommand.Version.value,
            sources: options.sources,
            output: options.output,
            arguments: makeArguments(for: options),
            inlineTemplate: EmbeddedTemplates.previewModels,
            defaultEnabled: options.previewDefaultEnabled,
            cacheDir: options.cacheBasePath,
            useGroupedSnapshots: true, // Playbooks are always grouped
            pluginWorkDirectory: options.pluginWorkDirectory,
            validateGeneratedSwift: true
        )
    }

    static func makeArguments(for options: GeneratedPlaybookOptions) -> [String: NSObject] {
        Logger.info(
            """
            Prefire configuration
                ➜ Generated models path: \(options.output)
                ➜ Preview default enabled: \(options.previewDefaultEnabled)
            """
        )

        return [
            Keys.imports: options.imports as? NSArray,
            Keys.testableImports: options.testableImports as? NSArray
        ].filter({ $0.value != nil }) as? [String: NSObject] ?? [:]
    }
}
