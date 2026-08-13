import XCTest
@testable import Pips39Core

final class SmokeTests: XCTestCase {
    func testPackageBuilds() {
        XCTAssertTrue(Pips39CorePlaceholder.ready)
    }
}
