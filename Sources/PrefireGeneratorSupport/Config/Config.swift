import Foundation
import PrefireCore

struct Config {
    var tests = TestsConfig()
    var playbook = PlaybookConfig()

    enum Section: String {
        case tests = "test_configuration"
        case playbook = "playbook_configuration"
    }
}

struct TestsConfig {
    var target: String?
    var device: String?
    var osVersion: String?
    var snapshotDevices: [String]?
    var previewDefaultEnabled: Bool?
    var imports: [String]?
    var testableImports: [String]?
    var useGroupedSnapshots: Bool?
    var splitSnapshotDirectories: Bool?
    var drawHierarchyInKeyWindowDefaultEnabled: Bool?
    var snapshotWaitForIdle: Bool?
    var snapshotWaitTimeout: Double?
    var fullPageSnapshots: Bool?
    var voiceOverSnapshots: [String]?

    static let voiceOverSnapshotStrategies = ["image", "text"]
}

struct PlaybookConfig {
    var previewDefaultEnabled: Bool?
    var imports: [String]?
    var testableImports: [String]?
}

enum ConfigError: LocalizedError, Equatable {
    case unsupportedKey(String)
    case invalidValue(key: String, value: String)

    var errorDescription: String? {
        switch self {
        case let .unsupportedKey(key):
            return "`.prefire.yml` key '\(key)' is not supported by the sandboxed source-only generator."
        case let .invalidValue(key, value):
            return "Invalid `.prefire.yml` value for '\(key)': \(value)"
        }
    }
}

extension Config {
    /// These keys could redirect generator input/output, load an unreviewed template, or enable
    /// a removed CLI feature. Reject rather than silently accepting a less secure configuration.
    private static let rejectedKeys: Set<String> = [
        "template_file_path", "test_file_path", "test_target_path", "sources",
        "render_configuration", "xcodebuild_args", "output_dir", "workspace", "project",
        "scheme", "destination", "direct_launch", "own_derived_data"
    ]

    static func load(from configPath: String?, testTargetPath: String?) throws -> Config? {
        for path in ConfigPathBuilder.possibleConfigPaths(for: configPath, testTargetPath: testTargetPath) {
            let configURL = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: configURL.path) else { continue }

            let data = try String(contentsOf: configURL, encoding: .utf8)
            try rejectUnsupportedKeys(in: data)
            Logger.info("🟢 Using .prefire.yml at \(configURL.path)")
            return try ConfigDecoder().decode(from: data)
        }
        return nil
    }

    private static func rejectUnsupportedKeys(in source: String) throws {
        for rawLine in source.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.hasPrefix("#"), let separator = line.firstIndex(of: ":") else { continue }
            let key = line[..<separator]
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                .trimmingCharacters(in: .whitespaces)
            if rejectedKeys.contains(key) {
                throw ConfigError.unsupportedKey(key)
            }
        }
    }
}
