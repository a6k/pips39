import XCTest
@testable import Pips39Core

final class BIP39ValidationTests: XCTestCase {

    private let validTwelve = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        .split(separator: " ").map(String.init)

    func testAcceptsKnownGoodMnemonic() {
        XCTAssertTrue(BIP39.isValid(mnemonic: validTwelve))
    }

    func testRejectsWrongChecksumWord() {
        var words = validTwelve
        words[11] = "abandon"   // "about" wäre korrekt
        XCTAssertFalse(BIP39.isValid(mnemonic: words))
    }

    func testRejectsUnknownWord() {
        var words = validTwelve
        words[3] = "nichtimwortschatz"
        XCTAssertFalse(BIP39.isValid(mnemonic: words))
    }

    func testRejectsWrongWordCount() {
        XCTAssertFalse(BIP39.isValid(mnemonic: Array(validTwelve.dropLast())))
        XCTAssertFalse(BIP39.isValid(mnemonic: []))
    }

    func testFirstMismatchReportsPosition() {
        var typed = validTwelve
        typed[5] = "zoo"
        XCTAssertEqual(BIP39.firstMismatch(between: validTwelve, and: typed), 5)
    }

    func testFirstMismatchReturnsNilWhenIdentical() {
        XCTAssertNil(BIP39.firstMismatch(between: validTwelve, and: validTwelve))
    }

    func testFirstMismatchReportsLengthDifference() {
        XCTAssertEqual(BIP39.firstMismatch(between: validTwelve,
                                           and: Array(validTwelve.dropLast())), 11)
    }
}
