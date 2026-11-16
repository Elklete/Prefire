@preconcurrency import ArgumentParser
import Foundation
import PrefireCore

extension PrefireCommand {
    struct Playbook: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Generate Playbook")

        @Argument(help: "Paths to a source swift files or directories.")
        var sources: [String] = [FileManager.default.currentDirectoryPath]

        @Option(help: "Path to a config `.prefire.yml`.")
        var config: String?
        @Option(help: "Path to generated file.")
        var output: String?
        @Option(help: "Base path to the cache directory.")
        var cacheBasePath: String?

        @Flag(help: "Display full info")
        var verbose = false

        func run() throws {
            Logger.level = verbose ? .verbose : .warnings
            let config = try Config.load(from: config, testTargetPath: nil)

            try GeneratePlaybookCommand.run(
                GeneratedPlaybookOptions(
                    sources: sources,
                    output: output,
                    cacheBasePath: cacheBasePath,
                    config: config
                )
            )
        }
    }
}
