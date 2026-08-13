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

    // MARK: Kürzung auf ein Vielfaches von 32

    func testTruncationKeepsMultipleOf32AndDropsLeadingBits() {
        // 34 Bits: die ersten beiden fallen weg, 32 bleiben.
        var bits = Array(repeating: false, count: 34)
        bits[0] = true   // fällt weg
        bits[1] = true   // fällt weg
        bits[2] = true   // bleibt, wird zum höchstwertigen Bit
        let entropy = ColemanEncoding.entropy(fromRawBits: bits)
        XCTAssertEqual(entropy.count, 4)
        XCTAssertEqual(entropy[0], 0b1000_0000)
    }

    func testTruncationYieldsNothingBelow32Bits() {
        XCTAssertEqual(ColemanEncoding.entropy(fromRawBits: Array(repeating: true, count: 31)), [])
        XCTAssertEqual(ColemanEncoding.entropy(fromRawBits: []), [])
    }

    func testEntropyMatchesColemanVectors() throws {
        for vector in try ColemanVectors.load() {
            let entropy = ColemanEncoding.entropy(from: vector.rollDigits)
            XCTAssertEqual(hexString(entropy), vector.entropieHex,
                           "Entropie weicht ab bei: \(vector.name)")
            XCTAssertEqual(entropy.count * 8, vector.genutzteBits,
                           "Genutzte Bits weichen ab bei: \(vector.name)")
        }
    }

    private func hexString(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func bitString(_ bits: [Bool]) -> String {
        String(bits.map { $0 ? "1" : "0" })
    }
}
