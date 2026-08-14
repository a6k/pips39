import XCTest
@testable import Pips39Core

final class TranscriptionCheckTests: XCTestCase {

    private let words = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        .split(separator: " ").map(String.init)

    func testStartsAtFirstPosition() {
        let check = TranscriptionCheck(expected: words)
        XCTAssertEqual(check.position, 0)
        XCTAssertEqual(check.total, 12)
        XCTAssertFalse(check.isComplete)
        XCTAssertNil(check.mismatch)
    }

    func testCorrectWordAdvances() {
        let check = TranscriptionCheck(expected: words)
        check.submit("abandon")
        XCTAssertEqual(check.position, 1)
        XCTAssertNil(check.mismatch)
    }

    func testWrongWordDoesNotAdvance() {
        let check = TranscriptionCheck(expected: words)
        check.submit("zoo")
        XCTAssertEqual(check.position, 0)
        XCTAssertEqual(check.mismatch, "zoo")
    }

    func testMismatchIsClearedOnNextAttempt() {
        let check = TranscriptionCheck(expected: words)
        check.submit("zoo")
        check.submit("abandon")
        XCTAssertNil(check.mismatch)
        XCTAssertEqual(check.position, 1)
    }

    func testMismatchAtLaterPositionReportsThatPosition() {
        let check = TranscriptionCheck(expected: words)
        for _ in 0..<5 { check.submit("abandon") }
        check.submit("zoo")
        XCTAssertEqual(check.position, 5, "Die Position bleibt stehen, wo es klemmt")
        XCTAssertEqual(check.mismatch, "zoo")
    }

    func testCompletesAfterAllWords() {
        let check = TranscriptionCheck(expected: words)
        for word in words { check.submit(word) }
        XCTAssertTrue(check.isComplete)
        XCTAssertEqual(check.position, 12)
    }

    func testSubmitAfterCompletionIsIgnored() {
        let check = TranscriptionCheck(expected: words)
        for word in words { check.submit(word) }
        check.submit("zoo")
        XCTAssertTrue(check.isComplete)
        XCTAssertNil(check.mismatch)
    }

    func testUndoStepsBackOnePosition() {
        let check = TranscriptionCheck(expected: words)
        check.submit("abandon")
        check.submit("abandon")
        check.undo()
        XCTAssertEqual(check.position, 1)
    }

    func testUndoAtStartDoesNothing() {
        let check = TranscriptionCheck(expected: words)
        check.undo()
        XCTAssertEqual(check.position, 0)
    }

    func testUndoClearsMismatch() {
        let check = TranscriptionCheck(expected: words)
        check.submit("abandon")
        check.submit("zoo")
        check.undo()
        XCTAssertNil(check.mismatch)
        XCTAssertEqual(check.position, 0)
    }

    /// Die Ansicht ruft das beim ersten Buchstaben der nächsten Eingabe auf, damit die
    /// Meldung nicht neben einem Wort stehen bleibt, auf das sie sich nicht bezieht.
    func testClearMismatchLeavesThePositionAlone() {
        let check = TranscriptionCheck(expected: words)
        check.submit("abandon")
        check.submit("zoo")
        XCTAssertEqual(check.mismatch, "zoo")

        check.clearMismatch()
        XCTAssertNil(check.mismatch)
        XCTAssertEqual(check.position, 1, "Nur die Meldung geht weg, nicht der Fortschritt")
    }

    func testResetStartsOver() {
        let check = TranscriptionCheck(expected: words)
        check.submit("abandon")
        check.submit("zoo")
        check.reset()
        XCTAssertEqual(check.position, 0)
        XCTAssertNil(check.mismatch)
        XCTAssertFalse(check.isComplete)
    }

    /// Die App verrät das richtige Wort nicht — sie sagt nur, dass es abweicht.
    /// Wer nachsehen will, geht zur Wortliste zurück.
    func testCheckExposesNoExpectedWord() {
        let check = TranscriptionCheck(expected: words)
        check.submit("zoo")
        XCTAssertEqual(check.mismatch, "zoo", "Nur das Getippte, nie das Erwartete")
    }
}
