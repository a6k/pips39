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

    // MARK: Der Hinweis während des Würfelns

    /// Unter zwanzig Würfen schweigt die Prüfung — dort wären drei oder fünf gleiche
    /// Würfe hintereinander noch gewöhnlich.
    func testLivePatternStaysSilentBelowTwenty() {
        XCTAssertNil(session(face: 1, times: 19).livePattern)
    }

    func testLivePatternAppearsAtTwenty() {
        XCTAssertEqual(session(face: 1, times: 20).livePattern, .singleFace)
    }

    /// Der Hinweis ist eine Feststellung über den aktuellen Stand, kein Urteil, das
    /// stehen bleibt: Sobald die Folge nicht mehr auffällig ist, verschwindet er.
    func testLivePatternDisappearsWhenTheSequenceRecovers() {
        let session = session(face: 1, times: 20)
        session.roll(2)
        XCTAssertEqual(session.livePattern, .twoFacesOnly)
        session.roll(3)
        XCTAssertNil(session.livePattern)
    }

    /// Die Wortanzeige zeigt weiterhin erst zum Ergebnis.
    func testRollPatternStillWaitsForCompletion() {
        let session = session(face: 1, times: 20)
        XCTAssertNotNil(session.livePattern)
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
