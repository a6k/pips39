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

    /// Der umgekehrte Fall: Der Nutzer hat ein Wort **zu viel** getippt. Gemeldet wird
    /// die erste Stelle hinter dem Erwarteten, also 12 — dort steht in der Abschrift
    /// etwas, wofür es keine Vorlage gibt.
    ///
    /// Bisher war nur die zu *kurze* Abschrift geprüft. Der Unterschied ist keiner der
    /// Symmetrie: Die Schleife läuft über das kürzere der beiden Felder, und ein
    /// Rückgabewert, der auf das längere zeigt, würde beim Markieren in der Ansicht
    /// über den Rand greifen.
    func testFirstMismatchReportsExtraTypedWord() {
        let typed = validTwelve + ["zoo"]
        XCTAssertEqual(BIP39.firstMismatch(between: validTwelve, and: typed), 12)
    }

    /// Zu viel getippt **und** vorher schon falsch: Der frühere Fehler gewinnt, die
    /// überzähligen Wörter interessieren dann nicht mehr.
    func testEarlierMismatchWinsOverExtraWords() {
        var typed = validTwelve + ["zoo", "zoo"]
        typed[2] = "zebra"
        XCTAssertEqual(BIP39.firstMismatch(between: validTwelve, and: typed), 2)
    }

    /// Eine viel längere Abschrift meldet trotzdem die Länge der Vorlage, nicht ihre
    /// eigene.
    func testFirstMismatchWithMuchLongerInput() {
        let typed = validTwelve + Array(repeating: "abandon", count: 12)
        XCTAssertEqual(BIP39.firstMismatch(between: validTwelve, and: typed), 12)
    }

    /// Und die Gegenrichtung mit leerer Abschrift: Stelle 0, nicht `nil`.
    func testFirstMismatchWithEmptyInput() {
        XCTAssertEqual(BIP39.firstMismatch(between: validTwelve, and: []), 0)
    }
}
