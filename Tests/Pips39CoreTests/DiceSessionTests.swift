import XCTest
@testable import Pips39Core

final class DiceSessionTests: XCTestCase {

    private func rolled(_ session: DiceSession, face: UInt8, times: Int) {
        for _ in 0..<times {
            session.roll(face)
        }
    }

    func testStartsEmptyAndNotComplete() {
        let session = DiceSession(method: .sha256)
        XCTAssertEqual(session.rollCount, 0)
        XCTAssertFalse(session.isComplete)
        XCTAssertFalse(session.canUndo)
        XCTAssertTrue(session.words.isEmpty)
    }

    func testRollingCountsUp() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 3, times: 5)
        XCTAssertEqual(session.rollCount, 5)
        XCTAssertTrue(session.canUndo)
    }

    func testInvalidFaceIsIgnored() {
        let session = DiceSession(method: .sha256)
        session.roll(0)
        session.roll(7)
        XCTAssertEqual(session.rollCount, 0)
    }

    func testUndoStepsBack() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 3, times: 2)
        session.undo()
        XCTAssertEqual(session.rollCount, 1)
    }

    func testRollsBeyondCompletionAreIgnored() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 120)
        XCTAssertEqual(session.rollCount, 99)
        XCTAssertTrue(session.isComplete)
    }

    func testProgressFollowsMethodForHashed() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 10)
        XCTAssertEqual(session.progress, .rolls(done: 10, needed: 99))
    }

    func testProgressFollowsMethodForColeman() {
        let session = DiceSession(method: .coleman)
        rolled(session, face: 1, times: 10)
        XCTAssertEqual(session.progress, .bits(done: 20, needed: 256))
    }

    // MARK: Aufdecken und Verwerfen

    func testRevealDoesNothingBeforeCompletion() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 98)
        session.reveal()
        XCTAssertTrue(session.words.isEmpty)
    }

    func testRevealProducesTwentyFourWords() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 99)
        session.reveal()
        XCTAssertEqual(session.words.count, 24)
        XCTAssertEqual(session.words.joined(separator: " "),
                       "wheel erase puppy pistol chapter accuse carpet drop quote final attend near scrap satisfy limit style crunch person south inspire lunch meadow enact tattoo")
    }

    func testRevealedWordsAreValid() {
        let session = DiceSession(method: .coleman)
        rolled(session, face: 1, times: 128)
        session.reveal()
        XCTAssertEqual(session.words.count, 24)
        XCTAssertTrue(BIP39.isValid(mnemonic: session.words))
    }

    func testDiscardClearsEverything() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 99)
        session.reveal()
        session.discard()
        XCTAssertTrue(session.words.isEmpty)
        XCTAssertEqual(session.rollCount, 0)
        XCTAssertFalse(session.isComplete)
    }

    /// Die Wurffolge, wie sie der Nachrechnen-Bereich später anzeigt.
    func testRollSequenceIsReadable() {
        let session = DiceSession(method: .sha256)
        session.roll(1)
        session.roll(4)
        session.roll(6)
        XCTAssertEqual(session.rollSequence, "146")
    }

    func testRollSequenceIsEmptyAtStart() {
        XCTAssertEqual(DiceSession(method: .sha256).rollSequence, "")
    }
}
