import XCTest
@testable import Pips39Core

final class SeedLengthHintTests: XCTestCase {

    func testHashedHintNamesTheExactRollCount() {
        XCTAssertTrue(DiceMethod.sha256.rollCountHint(for: .twentyFour).contains("99"))
        XCTAssertTrue(DiceMethod.sha256.rollCountHint(for: .twelve).contains("50"))
    }

    /// Verfahren A darf für keine Wortzahl eine feste Zahl versprechen.
    func testColemanHintNeverPromisesAnExactCount() {
        for length in SeedLength.allCases {
            let hint = DiceMethod.coleman.rollCountHint(for: length)
            XCTAssertTrue(hint.lowercased().contains("varies"),
                          "Verfahren A muss die Schwankung nennen: \(hint)")
            XCTAssertFalse(hint.lowercased().contains("exactly"))
        }
    }

    func testColemanHintNamesTheApproximateCount() {
        XCTAssertTrue(DiceMethod.coleman.rollCountHint(for: .twelve).contains("77"))
        XCTAssertTrue(DiceMethod.coleman.rollCountHint(for: .twentyFour).contains("154"))
    }

    func testEveryCombinationHasANonEmptyHint() {
        for method in DiceMethod.allCases {
            for length in SeedLength.allCases {
                XCTAssertFalse(method.rollCountHint(for: length).isEmpty)
            }
        }
    }

    // MARK: Nachrechen-Anleitung

    /// Der Fehlalarm-Fänger: Bei 12 Wörtern gehören nur die ersten 32 Hex-Zeichen
    /// in Colemans Feld. Ohne diesen Hinweis bekommt der Nutzer 24 Wörter und
    /// glaubt, sein Seed sei falsch.
    func testHashedStepsExplainTheHexTruncationForTwelveWords() {
        let joined = DiceMethod.sha256.verificationSteps(for: .twelve).joined(separator: " ")
        XCTAssertTrue(joined.contains("32"), "Hinweis auf die ersten 32 Hex-Zeichen fehlt")
    }

    func testHashedStepsDoNotTruncateForTwentyFourWords() {
        let joined = DiceMethod.sha256.verificationSteps(for: .twentyFour).joined(separator: " ")
        XCTAssertFalse(joined.contains("first 32"))
    }

    func testColemanStepsStillWarnAboutBothPitfalls() {
        for length in SeedLength.allCases {
            let joined = DiceMethod.coleman.verificationSteps(for: length).joined(separator: " ")
            XCTAssertTrue(joined.contains("Dice"))
            XCTAssertTrue(joined.contains("Raw Entropy"))
        }
    }
}
