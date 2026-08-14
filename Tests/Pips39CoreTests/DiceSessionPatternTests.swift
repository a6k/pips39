import XCTest
@testable import Pips39Core

final class DiceSessionPatternTests: XCTestCase {

    private func session(face: UInt8, times: Int) -> DiceSession {
        let session = DiceSession(method: .sha256, length: .twelve)
        for _ in 0..<times { session.roll(face) }
        return session
    }

    /// Während des Würfelns wären drei gleiche Würfe hintereinander völlig normal.
    /// Eine Meldung dazu wäre genau der Fehlalarm, den diese Prüfung vermeidet.
    func testNoFindingWhileIncomplete() {
        XCTAssertNil(session(face: 1, times: 30).rollPattern)
    }

    func testFindingAppearsWhenComplete() {
        XCTAssertEqual(session(face: 1, times: 50).rollPattern, .singleFace)
    }

    func testMixedSequenceHasNoFinding() {
        let session = DiceSession(method: .sha256, length: .twelve)
        var rng = SeededGenerator(seed: 99)
        for _ in 0..<50 { session.roll(UInt8.random(in: 1...6, using: &rng)) }
        XCTAssertTrue(session.isComplete)
        XCTAssertNil(session.rollPattern)
    }

    func testDiscardClearsTheFinding() {
        let session = session(face: 1, times: 50)
        session.discard()
        XCTAssertNil(session.rollPattern)
    }

    /// Auch unter Verfahren A, wo die Wurfzahl nicht feststeht.
    func testColemanSingleFaceIsFound() {
        let session = DiceSession(method: .coleman, length: .twelve)
        for _ in 0..<64 { session.roll(1) }
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.rollPattern, .singleFace)
    }
}
