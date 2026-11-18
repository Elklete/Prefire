import XCTest
@testable import PluginFixtureApp

final class PluginFixtureAppTests: XCTestCase {
    func testFixtureLinks() {
        XCTAssertEqual(PluginFixture.name, "source-built-plugin")
    }
}
