import XCTest
@testable import Pips39Core

final class ColemanEncodingTests: XCTestCase {

    // MARK: Bit-Tabelle

    func testTwoBitRolls() {
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 1), [false, true])   // 01
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 2), [true, false])   // 10
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 3), [true, true])    // 11
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 6), [false, false])  // 00, die 6 wird zur 0
    }

    func testOneBitRolls() {
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 4), [false])
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 5), [true])
    }

    func testRawBitsConcatenatesInRollOrder() {
        // 1 -> 01, 4 -> 0, 2 -> 10  ergibt  01 0 10
        XCTAssertEqual(ColemanEncoding.rawBits(for: [1, 4, 2]),
                       [false, true, false, true, false])
    }

    func testRawBitsOfEmptyInputIsEmpty() {
        XCTAssertEqual(ColemanEncoding.rawBits(for: []), [])
    }

    // MARK: gegen Colemans echte Ausgabe

    func testRawBitsMatchColemanVectors() throws {
        for vector in try ColemanVectors.load() {
            let bits = ColemanEncoding.rawBits(for: vector.rollDigits)
            XCTAssertEqual(bitString(bits), vector.rohBinaer,
                           "Rohbits weichen ab bei: \(vector.name)")
            XCTAssertEqual(bits.count, vector.rohBits,
                           "Bitanzahl weicht ab bei: \(vector.name)")
        }
    }

    private func bitString(_ bits: [Bool]) -> String {
        String(bits.map { $0 ? "1" : "0" })
    }
}
