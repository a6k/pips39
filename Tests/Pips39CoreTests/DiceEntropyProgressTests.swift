import XCTest
@testable import Pips39Core

final class DiceEntropyProgressTests: XCTestCase {

    private func filled(_ method: DiceMethod, with roll: UInt8, count: Int) throws -> DiceEntropy {
        var buffer = DiceEntropy(method: method)
        for _ in 0..<count {
            try buffer.append(roll)
        }
        return buffer
    }

    // MARK: Verfahren B — Würfe zählen

    func testHashedProgressCountsRolls() throws {
        let buffer = try filled(.sha256, with: 1, count: 37)
        XCTAssertEqual(buffer.progress, .rolls(done: 37, needed: 99))
    }

    func testHashedIsCompleteAfterExactly99Rolls() throws {
        let buffer = try filled(.sha256, with: 1, count: 99)
        XCTAssertTrue(buffer.isComplete)
        XCTAssertEqual(buffer.progress, .rolls(done: 99, needed: 99))
    }

    func testHashedRefusesRollNumber100() throws {
        var buffer = try filled(.sha256, with: 1, count: 99)
        XCTAssertThrowsError(try buffer.append(1)) { error in
            XCTAssertEqual(error as? DiceError, .alreadyComplete)
        }
        XCTAssertEqual(buffer.rolls.count, 99)
    }

    // MARK: Verfahren A — Bits zählen

    func testColemanProgressCountsBitsNotRolls() throws {
        // Zehn Einsen liefern je zwei Bit.
        let buffer = try filled(.coleman, with: 1, count: 10)
        XCTAssertEqual(buffer.progress, .bits(done: 20, needed: 256))
    }

    func testColemanCountsOneBitFacesAsOne() throws {
        // Zehn Vieren liefern je ein Bit.
        let buffer = try filled(.coleman, with: 4, count: 10)
        XCTAssertEqual(buffer.progress, .bits(done: 10, needed: 256))
    }

    func testColemanCompletesAt128RollsOfTwoBitFaces() throws {
        let buffer = try filled(.coleman, with: 1, count: 128)
        XCTAssertEqual(buffer.progress, .bits(done: 256, needed: 256))
        XCTAssertTrue(buffer.isComplete)
    }

    func testColemanNotCompleteOneRollEarlier() throws {
        let buffer = try filled(.coleman, with: 1, count: 127)
        XCTAssertFalse(buffer.isComplete)
    }

    func testColemanNeeds256RollsOfOneBitFaces() throws {
        let buffer = try filled(.coleman, with: 4, count: 256)
        XCTAssertTrue(buffer.isComplete)
    }

    func testColemanMayOvershootByOneBit() throws {
        var buffer = try filled(.coleman, with: 1, count: 127)   // 254 Bit
        try buffer.append(4)              // 255 Bit, noch nicht fertig
        XCTAssertFalse(buffer.isComplete)
        try buffer.append(1)              // 257 Bit
        XCTAssertTrue(buffer.isComplete)
        XCTAssertEqual(buffer.progress, .bits(done: 257, needed: 256))
    }

    /// Der Fortschritt sagt 257 von 256 Bit. Geprüft wurde bisher nur er, nie das
    /// Ergebnis. Genau hier greift Colemans Kürzung: Es bleiben die **letzten**
    /// 256 Bit, das erste fällt weg.
    func testColemanOvershootYieldsExactlyTheLast256Bits() throws {
        var buffer = try filled(.coleman, with: 1, count: 127)
        try buffer.append(4)
        try buffer.append(1)

        var entropy = try XCTUnwrap(buffer.entropy())
        defer { entropy.wipe() }
        XCTAssertEqual(entropy.bytes.count, 32)

        // 1 ergibt „01", 4 ergibt „0". Die Rohfolge ist also 254-mal „01", dann „0",
        // dann „01". Vorn fällt eine Null weg, übrig bleibt „1" gefolgt von 0101…01.
        let expected = [UInt8(0b1010_1010)] + [UInt8](repeating: 0b1010_1010, count: 30) + [0b1010_1001]
        XCTAssertEqual(entropy.bytes, expected)

        let words = try BIP39.mnemonic(from: entropy.bytes)
        XCTAssertEqual(words.count, 24)
        XCTAssertTrue(BIP39.isValid(mnemonic: words))
    }

    func testColemanRefusesFurtherRollsWhenComplete() throws {
        var buffer = try filled(.coleman, with: 1, count: 128)
        XCTAssertThrowsError(try buffer.append(1)) { error in
            XCTAssertEqual(error as? DiceError, .alreadyComplete)
        }
    }
}
