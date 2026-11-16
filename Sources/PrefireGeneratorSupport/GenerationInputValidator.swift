import Foundation
import PathKit

enum GenerationInputError: LocalizedError, Equatable {
    case missingPluginPath(String)
    case unsafeModuleName(String)
    case unsafeText(key: String)
    case outsidePluginWorkDirectory(path: String)

    var errorDescription: String? {
        switch self {
        case let .missingPluginPath(name):
            return "The internal plugin tool requires \(name)."
        case let .unsafeModuleName(value):
            return "Unsafe Swift module name: \(value)"
        case let .unsafeText(key):
            return "Unsafe control character in \(key)."
        case let .outsidePluginWorkDirectory(path):
            return "Generator path escapes the SwiftPM plugin work directory: \(path)"
        }
    }
}

enum GenerationInputValidator {
    private static let moduleComponent = try! NSRegularExpression(pattern: "^[A-Za-z_][A-Za-z0-9_]*$")

    static func moduleName(_ value: String?) throws -> String? {
        guard let value, !value.isEmpty else { return nil }
        let components = value.split(separator: ".", omittingEmptySubsequences: false)
        guard !components.isEmpty, components.allSatisfy({ isModuleComponent(String($0)) }) else {
            throw GenerationInputError.unsafeModuleName(value)
        }
        return value
    }

    private static func isModuleComponent(_ value: String) -> Bool {
        let range = NSRange(value.startIndex..., in: value)
        return moduleComponent.firstMatch(in: value, range: range)?.range == range
    }

    static func moduleNames(_ values: [String]?) throws -> [String]? {
        try values?.map { try moduleName($0)! }
    }

    static func plainText(_ value: String?, key: String) throws -> String? {
        guard let value else { return nil }
        guard !value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
            throw GenerationInputError.unsafeText(key: key)
        }
        return value
    }

    static func pluginWorkDirectory(output: Path, cache: Path) throws -> Path {
        let outputURL = URL(fileURLWithPath: output.string).standardizedFileURL.resolvingSymlinksInPath()
        let cacheURL = URL(fileURLWithPath: cache.string).standardizedFileURL.resolvingSymlinksInPath()
        guard outputURL.deletingLastPathComponent() == cacheURL.deletingLastPathComponent() else {
            throw GenerationInputError.outsidePluginWorkDirectory(path: "output/cache do not share a work directory")
        }
        return Path(outputURL.deletingLastPathComponent().path)
    }
}
