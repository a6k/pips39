import XCTest
@testable import Pips39Core

final class SeedLengthWiringTests: XCTestCase {

    private func session(_ method: DiceMethod, _ length: SeedLength,
                         face: UInt8, times: Int) -> DiceSession {
        let session = DiceSession(method: method, length: length)
        for _ in 0..<times { session.roll(face) }
        return session
    }

    // MARK: Verfahren B

    func testTwelveWordsCompleteAfterFiftyRolls() {
        let session = session(.sha256, .twelve, face: 1, times: 50)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.progress, .rolls(done: 50, needed: 50))
    }

    func testTwelveWordsRefuseRollFiftyOne() {
        let session = session(.sha256, .twelve, face: 1, times: 60)
        XCTAssertEqual(session.rollCount, 50)
    }

    /// Bei 12 Wörtern zählen nur die ersten 16 Byte des Hashes.
    func testTwelveWordEntropyIsSixteenBytes() {
        let session = session(.sha256, .twelve, face: 1, times: 50)
        XCTAssertEqual(session.entropyHex?.count, 32)
        XCTAssertEqual(session.entropyHex,
                       "3dac51a65ec9fcfc409a1b5f1defe92b")
    }

    /// Erzeugt mit `printf '%s' "111…" | shasum -a 256`, davon die ersten 32 Zeichen.
    func testTwelveWordsProduceExpectedMnemonic() {
        let session = session(.sha256, .twelve, face: 1, times: 50)
        session.reveal()
        XCTAssertEqual(session.words.count, 12)
        XCTAssertEqual(session.words.joined(separator: " "),
                       "diet glad hat rural panther lawsuit act drop gallery urge where fit")
    }

    // MARK: Verfahren A

    func testColemanTwelveWordsCompleteAt128Bits() {
        let session = session(.coleman, .twelve, face: 1, times: 64)
        XCTAssertEqual(session.progress, .bits(done: 128, needed: 128))
        XCTAssertTrue(session.isComplete)
    }

    func testColemanTwelveWordsProduceTwelveValidWords() {
        let session = session(.coleman, .twelve, face: 1, times: 64)
        session.reveal()
        XCTAssertEqual(session.words.count, 12)
        XCTAssertTrue(BIP39.isValid(mnemonic: session.words))
    }

    // MARK: Vorgabe und Beständigkeit

    func testDefaultIsStillTwentyFour() {
        XCTAssertEqual(DiceSession(method: .sha256).length, .twentyFour)
        XCTAssertEqual(DiceEntropy(method: .sha256).length, .twentyFour)
    }

    func testTwentyFourStillBehavesAsBefore() {
        let session = session(.sha256, .twentyFour, face: 1, times: 99)
        session.reveal()
        XCTAssertEqual(session.words.count, 24)
        XCTAssertEqual(session.entropyHex,
                       "fa098eb852b2660348b21bb00ad03a49cc177ea07ebe34f46b40baa85313525e")
    }

    /// Verwerfen darf die Wortzahl nicht verlieren.
    func testDiscardKeepsTheLength() {
        let session = session(.sha256, .twelve, face: 1, times: 50)
        session.discard()
        XCTAssertEqual(session.length, .twelve)
        XCTAssertEqual(session.progress, .rolls(done: 0, needed: 50))
    }
}
