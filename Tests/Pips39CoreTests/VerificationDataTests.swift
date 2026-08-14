import XCTest
@testable import Pips39Core

final class VerificationDataTests: XCTestCase {

    private func session(_ method: DiceMethod, face: UInt8, times: Int) -> DiceSession {
        let session = DiceSession(method: method)
        for _ in 0..<times { session.roll(face) }
        return session
    }

    // MARK: Hex-Entropie

    func testNoHexBeforeCompletion() {
        XCTAssertNil(session(.sha256, face: 1, times: 50).entropyHex)
    }

    func testHexMatchesShasumForHashedMethod() {
        let hex = session(.sha256, face: 1, times: 99).entropyHex
        XCTAssertEqual(hex, "fa098eb852b2660348b21bb00ad03a49cc177ea07ebe34f46b40baa85313525e")
    }

    func testHexIsSixtyFourCharactersForColeman() throws {
        let hex = try XCTUnwrap(session(.coleman, face: 1, times: 128).entropyHex)
        XCTAssertEqual(hex.count, 64)
        XCTAssertTrue(hex.allSatisfy { $0.isHexDigit })
    }

    func testRollSequenceIsTheTypedDigits() {
        XCTAssertEqual(session(.sha256, face: 6, times: 5).rollSequence, "66666")
    }

    // MARK: Anleitung je Verfahren

    func testEveryMethodHasVerificationSteps() {
        for method in DiceMethod.allCases {
            XCTAssertFalse(method.verificationSteps.isEmpty, "Keine Schritte für \(method)")
            for step in method.verificationSteps {
                XCTAssertFalse(step.isEmpty)
            }
        }
    }

    func testHashedStepsMentionShasum() {
        let joined = DiceMethod.sha256.verificationSteps.joined(separator: " ")
        XCTAssertTrue(joined.contains("shasum"))
    }

    /// Die beiden Stolperstellen aus Spec 2.6 müssen in der Anleitung stehen,
    /// sonst produziert der Verifikationsweg Fehlalarme — und ein Fehlalarm bei
    /// korrektem Seed ist genau das, was Vertrauen zerstört.
    func testColemanStepsWarnAboutBothPitfalls() {
        let joined = DiceMethod.coleman.verificationSteps.joined(separator: " ")
        XCTAssertTrue(joined.contains("Dice"), "Hinweis auf den Radio-Button Dice fehlt")
        XCTAssertTrue(joined.contains("Raw Entropy"), "Hinweis auf Use Raw Entropy fehlt")
    }

    func testEveryMethodWarnsAboutThrowawaySequences() {
        for method in DiceMethod.allCases {
            XCTAssertTrue(method.verificationWarning.lowercased().contains("throwaway"),
                          "Wegwerf-Hinweis fehlt bei \(method)")
        }
    }
}
