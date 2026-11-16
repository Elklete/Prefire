import Foundation
import PrefireCore
import PathKit

private enum Constants {
    static let snapshotFileName = "PreviewTests.generated.swift"
}

struct GeneratedTestsOptions {
    var target: String?
    var testTarget: String?
    var sources: [Path]
    var output: Path
    var prefireEnabledMarker: Bool
    var cacheBasePath: Path
    var pluginWorkDirectory: Path
    var device: String?
    var osVersion: String?
    var snapshotDevices: [String]?
    var imports: [String]?
    var testableImports: [String]?
    var drawHierarchyInKeyWindowDefaultEnabled: Bool?
    var snapshotWaitForIdle: Bool?
    var snapshotWaitTimeout: Double?
    var fullPageSnapshots: Bool
    var voiceOverSnapshots: [String]?

    init(
        target: String?,
        testTarget: String?,
        sources: [String],
        output: String?,
        testTargetPath _: String?,
        cacheBasePath: String?,
        device: String?,
        osVersion: String?,
        config: Config?
    ) throws {
        self.target = try GenerationInputValidator.moduleName(config?.tests.target ?? target)
        self.testTarget = try GenerationInputValidator.moduleName(testTarget)
        self.sources = sources.map { Path($0) }
        guard let output else { throw GenerationInputError.missingPluginPath("--output") }
        guard let cacheBasePath else { throw GenerationInputError.missingPluginPath("--cache-base-path") }
        self.output = Path(output)
        self.cacheBasePath = Path(cacheBasePath)
        pluginWorkDirectory = try GenerationInputValidator.pluginWorkDirectory(output: self.output, cache: self.cacheBasePath)
        prefireEnabledMarker = config?.tests.previewDefaultEnabled ?? true
        self.device = try GenerationInputValidator.plainText(config?.tests.device ?? device, key: "simulator_device")
        self.osVersion = try GenerationInputValidator.plainText(config?.tests.osVersion ?? osVersion, key: "required_os")
        guard config?.tests.useGroupedSnapshots != false,
              config?.tests.splitSnapshotDirectories != true else {
            throw ConfigError.unsupportedKey("use_grouped_snapshots: false / split_snapshot_directories")
        }
        snapshotDevices = try (config?.tests.snapshotDevices ?? []).map { try GenerationInputValidator.plainText($0, key: "snapshot_devices")! }
        imports = try GenerationInputValidator.moduleNames(config?.tests.imports)
        testableImports = try GenerationInputValidator.moduleNames(config?.tests.testableImports)
        drawHierarchyInKeyWindowDefaultEnabled = config?.tests.drawHierarchyInKeyWindowDefaultEnabled
        snapshotWaitForIdle = config?.tests.snapshotWaitForIdle
        snapshotWaitTimeout = config?.tests.snapshotWaitTimeout
        fullPageSnapshots = config?.tests.fullPageSnapshots ?? false
        voiceOverSnapshots = config?.tests.voiceOverSnapshots
    }
}

enum GenerateTestsCommand {
    private enum Keys {
        static let templates = "templates"
        static let sources = "sources"
        static let output = "output"
        static let cacheBasePath = "cacheBasePath"
        static let args = "args"

        static let simulatorOSVersion = "simulatorOSVersion"
        static let simulatorDevice = "simulatorDevice"
        static let snapshotDevices = "snapshotDevices"
        static let mainTarget = "mainTarget"
        static let file = "file"
        static let imports = "imports"
        static let testableImports = "testableImports"
        static let previewsMacros = "previewsMacros"
        static let previewsMacrosDict = "previewsMacrosDict"
        static let drawHierarchyInKeyWindowDefaultEnabled = "drawHierarchyInKeyWindowDefaultEnabled"
        static let snapshotWaitForIdle = "snapshotWaitForIdle"
        static let snapshotWaitTimeout = "snapshotWaitTimeout"
        static let fullPageSnapshots = "fullPageSnapshots"
        static let voiceOverSnapshots = "voiceOverSnapshots"
    }

    static func run(_ options: GeneratedTestsOptions) throws {
        try PrefireGenerator.generate(
            version: PrefireCommand.Version.value,
            sources: options.sources,
            output: options.output + Constants.snapshotFileName,
            arguments: GenerateTestsCommand.makeArguments(for: options),
            inlineTemplate: EmbeddedTemplates.previewTests,
            defaultEnabled: options.prefireEnabledMarker,
            cacheDir: options.cacheBasePath,
            useGroupedSnapshots: true,
            pluginWorkDirectory: options.pluginWorkDirectory,
            validateGeneratedSwift: true
        )
    }

    static func makeArguments(for options: GeneratedTestsOptions) -> [String: NSObject] {
        // SnapshotTesting receives the generated file under the plugin work directory as its
        // reference path. This keeps generator-related output out of the consumer checkout.
        let snapshotOutput = options.output + Constants.snapshotFileName

        Logger.info(
            """
            Prefire configuration
                ➜ Target used for tests: \(options.target ?? "nil")
                ➜ Tests target: \(options.testTarget ?? "nil")
                ➜ Generated test path: \(options.output)
                ➜ Snapshot resources path: \(snapshotOutput)
                ➜ Preview default enabled: \(options.prefireEnabledMarker)
                ➜ drawHierarchyInKeyWindow default enabled: \(options.drawHierarchyInKeyWindowDefaultEnabled?.description ?? "nil")
                ➜ Wait for idle by default: \(options.snapshotWaitForIdle?.description ?? "nil")
                ➜ Wait timeout: \(options.snapshotWaitTimeout?.description ?? "nil")
                ➜ Full page snapshots: \(options.fullPageSnapshots)
                ➜ VoiceOver snapshots: \(options.voiceOverSnapshots?.joined(separator: ", ") ?? "default")
            """
        )

        return [
            Keys.simulatorOSVersion: options.osVersion as? NSString,
            Keys.simulatorDevice: options.device as? NSString,
            Keys.snapshotDevices: options.snapshotDevices?.joined(separator: "|") as? NSString,
            Keys.imports: options.imports as? NSArray,
            Keys.testableImports: options.testableImports as? NSArray,
            Keys.mainTarget: options.target as? NSString,
            Keys.file: snapshotOutput.string as NSString,
            Keys.drawHierarchyInKeyWindowDefaultEnabled: options.drawHierarchyInKeyWindowDefaultEnabled?.description as? NSString,
            Keys.snapshotWaitForIdle: options.snapshotWaitForIdle?.description as? NSString,
            Keys.snapshotWaitTimeout: options.snapshotWaitTimeout?.description as? NSString,
            Keys.fullPageSnapshots: options.fullPageSnapshots ? "true" as NSString : nil,
            Keys.voiceOverSnapshots: options.voiceOverSnapshots
                .map { $0.isEmpty ? "none" : $0.joined(separator: "|") } as? NSString
        ].filter({ $0.value != nil }) as? [String: NSObject] ?? [:]
    }
}
