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
    func testLivePatternStaysSilentBelowTwentyTwo() {
        XCTAssertNil(session(face: 1, times: 21).livePattern)
    }

    /// Zweiundzwanzig, nicht zwanzig. Die Zahl kommt von der schwächsten Prüfung:
    /// „nur zwei Augenzahlen" liegt bei zwanzig Würfen noch bei 4,3·10⁻⁹ und damit
    /// über der eigenen Grenze von 10⁻⁹.
    func testLivePatternAppearsAtTwentyTwo() {
        XCTAssertEqual(session(face: 1, times: 22).livePattern, .singleFace)
    }

    /// Der Hinweis ist eine Feststellung über den aktuellen Stand, kein Urteil, das
    /// stehen bleibt. Er wandert mit der Folge — und verschwindet, sobald sie
    /// insgesamt nicht mehr auffällt.
    ///
    /// Dass er nach dem 24. Wurf noch steht, ist richtig so: zweiundzwanzig gleiche
    /// Würfe und danach zwei einzelne sind drei Blöcke, und drei Blöcke auf
    /// vierundzwanzig Würfen bleiben unmöglich. Erst der unauffällige Rest hebt es auf.
    func testLivePatternFollowsTheSequenceAndClearsAgain() {
        let session = session(face: 1, times: 22)
        XCTAssertEqual(session.livePattern, .singleFace)

        session.roll(2)
        XCTAssertEqual(session.livePattern, .twoFacesOnly)

        session.roll(3)
        XCTAssertEqual(session.livePattern, .fewRuns(3))

        for face in "45445522546521432156615446" {
            session.roll(UInt8(face.wholeNumberValue!))
        }
        XCTAssertEqual(session.rollCount, 50)
        XCTAssertNil(session.livePattern)
    }

    /// Die Prüfung schaut auf die **ganze** Folge, nicht auf Ausschnitte. Ein
    /// auffälliger Anfang, der später untergeht, wird nicht mehr gemeldet — jedes
    /// Fenster einzeln zu prüfen würde die Zahl der Gelegenheiten für einen Fehlalarm
    /// vervielfachen. Der Hinweis kommt deshalb früh oder gar nicht.
    func testAStrikingStartIsNotRememberedOnceTheWholeLooksNormal() {
        let session = session(face: 1, times: 22)
        for face in "234544552254652143215661544665" {
            session.roll(UInt8(face.wholeNumberValue!))
        }
        XCTAssertNil(session.livePattern)
        XCTAssertNil(session.rollPattern)
    }

    /// Die Wortanzeige zeigt weiterhin erst zum Ergebnis.
    func testRollPatternStillWaitsForCompletion() {
        let session = session(face: 1, times: 22)
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
