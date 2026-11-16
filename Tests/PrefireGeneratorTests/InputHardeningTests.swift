import Foundation
import PathKit
@testable import PrefireCore
@testable import PrefireGeneratorSupport
import XCTest

final class InputHardeningTests: XCTestCase {
    func testConfigurationRejectsTemplateAndOutputRedirection() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try "test_configuration:\n  - template_file_path: attacker.stencil\n".write(
            to: directory.appendingPathComponent(".prefire.yml"), atomically: true, encoding: .utf8
        )

        XCTAssertThrowsError(try Config.load(from: directory.path, testTargetPath: nil)) { error in
            XCTAssertEqual(error as? ConfigError, .unsupportedKey("template_file_path"))
        }
    }

    func testConfigurationValuesCannotInjectSwiftOrShellArguments() throws {
        var config = Config()
        config.tests.target = "Fixture; touch SHOULD_NOT_EXIST"

        XCTAssertThrowsError(try GeneratedTestsOptions(
            target: nil,
            testTarget: "FixtureTests",
            sources: [],
            output: "/tmp/prefire-input-test/Generated",
            testTargetPath: "/tmp/prefire-input-test/Tests",
            cacheBasePath: "/tmp/prefire-input-test/Cache",
            device: nil,
            osVersion: nil,
            config: config
        )) { error in
            XCTAssertEqual(error as? GenerationInputError, .unsafeModuleName("Fixture; touch SHOULD_NOT_EXIST"))
        }
    }

    func testPreviewNameIsEscapedBeforeItReachesGeneratedSwift() throws {
        let root = Path("/tmp/prefire-input-test-\(UUID().uuidString)")
        defer { try? root.delete() }
        try root.mkpath()
        let source = root + "Source.swift"
        let output = root + "Generated" + "PreviewTests.generated.swift"
        try source.write("""
        import SwiftUI
        #Preview("quote\\\"; ProcessInfo.processInfo.environment[\\\"PWN\\\"] = \\\"1\\\" //") {
            Text("Safe")
        }
        """)

        try PrefireGenerator.generate(
            version: "test",
            sources: [source],
            output: output,
            arguments: [:],
            inlineTemplate: EmbeddedTemplates.previewTests,
            defaultEnabled: true,
            cacheDir: root + "Cache",
            useGroupedSnapshots: true,
            pluginWorkDirectory: root,
            validateGeneratedSwift: true
        )

        let generated = try output.read(.utf8)
        XCTAssertTrue(generated.contains("ProcessInfo.processInfo.environment"))
        XCTAssertFalse(generated.contains(#"name: "quote"; ProcessInfo"#))
    }

    func testGeneratorRejectsOutputOrCacheOutsidePluginWorkDirectory() throws {
        let root = Path("/tmp/prefire-work-\(UUID().uuidString)")
        defer { try? root.delete() }
        try root.mkpath()
        let source = root + "Source.swift"
        try source.write("struct Source {}")

        do {
            try PrefireGenerator.generate(
                version: "test",
                sources: [source],
                output: root + "Generated" + "Output.swift",
                arguments: [:],
                inlineTemplate: "struct Generated {}",
                defaultEnabled: true,
                cacheDir: Path("/tmp/outside-prefire-cache"),
                useGroupedSnapshots: true,
                pluginWorkDirectory: root,
                validateGeneratedSwift: true
            )
            XCTFail("Expected plugin work directory confinement to fail")
        } catch let error as PrefireGeneratorError {
            XCTAssertEqual(error, .pluginPathEscape)
        }
    }
}
