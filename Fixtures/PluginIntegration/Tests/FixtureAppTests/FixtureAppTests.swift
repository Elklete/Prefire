import XCTest
@testable import PluginFixtureApp

final class FixtureAppTests: XCTestCase {
    func testFixtureLinks() {
        XCTAssertEqual(Fixture.name, "plugin-integration")
    }
}
