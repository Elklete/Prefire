import XCTest
@testable import PrefireGeneratorSupport

final class ConfigDecoderTests: XCTestCase {
    func testCompactListsStopBeforeTheirNextMappingKey() throws {
        let config = try ConfigDecoder().decode(from: """
        test_configuration:
          - target: FixtureApp
          - snapshot_devices:
              - iPhone 15
              - iPad
          - imports:
              - UIKit
              - Foundation
          - voiceover_snapshots:
              - image
              - text
        """)

        XCTAssertEqual(config.tests.target, "FixtureApp")
        XCTAssertEqual(config.tests.snapshotDevices, ["iPhone 15", "iPad"])
        XCTAssertEqual(config.tests.imports, ["UIKit", "Foundation"])
        XCTAssertEqual(config.tests.voiceOverSnapshots, ["image", "text"])
    }

    func testConfigurationDoesNotExpandEnvironmentPlaceholders() throws {
        let config = try ConfigDecoder().decode(from: """
        test_configuration:
          target: ${TARGET_NAME}
        """)

        XCTAssertEqual(config.tests.target, "${TARGET_NAME}")
    }
}
