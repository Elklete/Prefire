import Foundation

enum ConfigPathBuilder {
    private static let configFileName = ".prefire.yml"

    /// Config is read only from the supplied target directories. The internal plugin tool never
    /// searches the current directory or user home, which makes its configuration scope explicit.
    static func possibleConfigPaths(for configPath: String?, testTargetPath: String?) -> [String] {
        [testTargetPath, configPath].compactMap { path in
            guard let path else { return nil }
            var url = URL(fileURLWithPath: path.removingPercentEncoding ?? path)
            if url.lastPathComponent != configFileName { url.appendPathComponent(configFileName) }
            return url.standardizedFileURL.path
        }
    }
}
