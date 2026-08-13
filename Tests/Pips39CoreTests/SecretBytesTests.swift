import XCTest
@testable import Pips39Core

final class SecretBytesTests: XCTestCase {

    func testExposesItsBytes() {
        let secret = SecretBytes([1, 2, 3])
        XCTAssertEqual(secret.bytes, [1, 2, 3])
    }

    func testWipeOverwritesWithZeroes() {
        var secret = SecretBytes([9, 9, 9])
        secret.wipe()
        XCTAssertEqual(secret.bytes, [0, 0, 0])
    }

    func testWipeKeepsLength() {
        var secret = SecretBytes([UInt8](repeating: 7, count: 32))
        secret.wipe()
        XCTAssertEqual(secret.bytes.count, 32)
    }

    func testDescriptionDoesNotLeakContent() {
        let secret = SecretBytes([0xDE, 0xAD, 0xBE, 0xEF])
        XCTAssertEqual(String(describing: secret), "SecretBytes(4 Bytes)")
        XCTAssertFalse(String(describing: secret).contains("222"))
        XCTAssertFalse(String(describing: secret).contains("de"))
    }
}
