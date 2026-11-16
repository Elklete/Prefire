@preconcurrency import ArgumentParser
import Foundation

public struct PrefireCommand: ParsableCommand {
    public init() {}

    public static let configuration: CommandConfiguration = .init(
        commandName: "prefire",
        abstract: "Internal source-built generator for Prefire SwiftPM plugins.",
        version: Version.value,
        subcommands: [
            Playbook.self,
            Tests.self
        ]
    )
}
