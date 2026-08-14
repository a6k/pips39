import XCTest
@testable import Pips39Core

final class SeedLengthTests: XCTestCase {

    func testWordCounts() {
        XCTAssertEqual(SeedLength.twelve.wordCount, 12)
        XCTAssertEqual(SeedLength.twentyFour.wordCount, 24)
    }

    func testEntropyBitsFollowBIP39() {
        XCTAssertEqual(SeedLength.twelve.entropyBits, 128)
        XCTAssertEqual(SeedLength.twentyFour.entropyBits, 256)
    }

    func testEntropyBitsAreValidBIP39Sizes() {
        for length in SeedLength.allCases {
            XCTAssertTrue(BIP39.allowedEntropyBits.contains(length.entropyBits))
        }
    }

    func testHashedRollCounts() {
        XCTAssertEqual(SeedLength.twelve.rollsForHashedMethod, 50)
        XCTAssertEqual(SeedLength.twentyFour.rollsForHashedMethod, 99)
    }

    /// Genug Würfelentropie für die Zielgröße: jeder Wurf trägt log2(6) = 2,585 bit.
    func testHashedRollCountsCarryEnoughEntropy() {
        for length in SeedLength.allCases {
            let bits = Double(length.rollsForHashedMethod) * 2.5849625
            XCTAssertGreaterThan(bits, Double(length.entropyBits) - 1,
                                 "Zu wenige Würfe für \(length.wordCount) Wörter")
        }
    }

    func testApproximateColemanRolls() {
        XCTAssertEqual(SeedLength.twelve.approximateColemanRolls, 77)
        XCTAssertEqual(SeedLength.twentyFour.approximateColemanRolls, 154)
    }

    func testTwentyFourIsTheDefault() {
        XCTAssertEqual(SeedLength.standard, .twentyFour)
    }

    func testTitlesNameTheWordCount() {
        XCTAssertTrue(SeedLength.twelve.title.contains("12"))
        XCTAssertTrue(SeedLength.twentyFour.title.contains("24"))
    }

    func testAllCasesAreDistinct() {
        XCTAssertEqual(Set(SeedLength.allCases.map(\.wordCount)).count,
                       SeedLength.allCases.count)
    }
}
