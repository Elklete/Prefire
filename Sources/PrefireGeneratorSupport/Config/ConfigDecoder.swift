import Foundation
import PrefireCore

/// A deliberately small, data-only parser for the supported `.prefire.yml` subset.
/// It accepts scalar values and indented lists; it neither evaluates YAML tags nor executes shell.
final class ConfigDecoder {
    func decode(from source: String) throws -> Config {
        var config = Config()
        var section: Config.Section?
        let lines = source.components(separatedBy: .newlines)

        for index in lines.indices {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "\(Config.Section.tests.rawValue):" { section = .tests; continue }
            if trimmed == "\(Config.Section.playbook.rawValue):" { section = .playbook; continue }
            guard let section, let colon = trimmed.firstIndex(of: ":") else { continue }

            let key = normalizedKey(String(trimmed[..<colon]))
            let tail = String(trimmed[trimmed.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            let values = listValue(tail: tail, following: lines[(index + 1)...])
            let value = scalar(tail)

            switch section {
            case .tests:
                try applyTest(key: key, value: value, values: values, config: &config)
            case .playbook:
                try applyPlaybook(key: key, value: value, values: values, config: &config)
            }
        }
        return config
    }

    private func applyTest(key: String, value: String?, values: [String]?, config: inout Config) throws {
        switch key {
        case "target": config.tests.target = value
        case "simulator_device": config.tests.device = value
        case "required_os": config.tests.osVersion = value
        case "snapshot_devices": config.tests.snapshotDevices = values ?? inlineList(value)
        case "preview_default_enabled": config.tests.previewDefaultEnabled = bool(value, key: key)
        case "imports": config.tests.imports = values ?? inlineList(value)
        case "testable_imports": config.tests.testableImports = values ?? inlineList(value)
        case "use_grouped_snapshots": config.tests.useGroupedSnapshots = bool(value, key: key)
        case "split_snapshot_directories": config.tests.splitSnapshotDirectories = bool(value, key: key)
        case "draw_hierarchy_in_key_window_default_enabled": config.tests.drawHierarchyInKeyWindowDefaultEnabled = bool(value, key: key)
        case "snapshot_wait_for_idle": config.tests.snapshotWaitForIdle = bool(value, key: key)
        case "snapshot_wait_timeout":
            guard let value, let timeout = Double(value), timeout.isFinite, timeout > 0 else {
                throw ConfigError.invalidValue(key: key, value: value ?? "")
            }
            config.tests.snapshotWaitTimeout = timeout
        case "full_page_snapshots": config.tests.fullPageSnapshots = bool(value, key: key)
        case "voiceover_snapshots": config.tests.voiceOverSnapshots = voiceOver(values ?? inlineList(value))
        case "": break
        default: Logger.warning("⚠️ Unknown test config key: '\(key)'")
        }
    }

    private func applyPlaybook(key: String, value: String?, values: [String]?, config: inout Config) throws {
        switch key {
        case "preview_default_enabled": config.playbook.previewDefaultEnabled = bool(value, key: key)
        case "imports": config.playbook.imports = values ?? inlineList(value)
        case "testable_imports": config.playbook.testableImports = values ?? inlineList(value)
        case "": break
        default: Logger.warning("⚠️ Unknown playbook config key: '\(key)'")
        }
    }

    private func normalizedKey(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .trimmingCharacters(in: .whitespaces)
    }

    private func listValue(tail: String, following: ArraySlice<String>) -> [String]? {
        guard tail.isEmpty else { return nil }
        var values: [String] = []
        for rawLine in following {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("- ") else { break }
            let item = String(line.dropFirst(2))
            // A sibling mapping entry has the same list-item indentation in the
            // compact YAML form used by existing Prefire configs. Do not absorb
            // it into the preceding list (which could otherwise turn a key into
            // an import/module name).
            guard !item.contains(":") else { break }
            values.append(item.trimmingCharacters(in: CharacterSet(charactersIn: "\"' ")))
        }
        return values
    }

    private func inlineList(_ value: String?) -> [String]? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
        return trimmed.isEmpty ? [] : trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func scalar(_ value: String) -> String? {
        guard !value.isEmpty else { return nil }
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
    }

    private func bool(_ value: String?, key: String) -> Bool? {
        guard let value else { return nil }
        guard ["true", "false"].contains(value) else {
            Logger.warning("⚠️ `\(key)` must be true or false, ignoring '\(value)'")
            return nil
        }
        return value == "true"
    }

    private func voiceOver(_ values: [String]?) -> [String]? {
        guard let values else { return nil }
        if values.contains("none") { return [] }
        let known = values.filter { TestsConfig.voiceOverSnapshotStrategies.contains($0) }
        return known.isEmpty && !values.isEmpty ? nil : known
    }
}
