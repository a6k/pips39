import XCTest
@testable import Pips39Core

final class BitStreamTests: XCTestCase {

    func testBitsFromSingleByteAreMostSignificantFirst() {
        XCTAssertEqual(BitStream.bits(from: [0b1000_0000]),
                       [true, false, false, false, false, false, false, false])
        XCTAssertEqual(BitStream.bits(from: [0b0000_0001]),
                       [false, false, false, false, false, false, false, true])
    }

    func testBitsFromTwoBytesKeepByteOrder() {
        XCTAssertEqual(BitStream.bits(from: [0x00, 0xFF]),
                       Array(repeating: false, count: 8) + Array(repeating: true, count: 8))
    }

    func testGroupsOfElevenSplitsExactly() {
        let bits = Array(repeating: false, count: 22)
        XCTAssertEqual(BitStream.groupsOfEleven(bits), [0, 0])
    }

    func testGroupsOfElevenComputesValue() {
        // 11 Bits, alle gesetzt -> 2047
        let bits = Array(repeating: true, count: 11)
        XCTAssertEqual(BitStream.groupsOfEleven(bits), [2047])
    }

    func testGroupsOfElevenIsBigEndianWithinGroup() {
        // 1000 0000 000 -> 1024
        var bits = Array(repeating: false, count: 11)
        bits[0] = true
        XCTAssertEqual(BitStream.groupsOfEleven(bits), [1024])
    }

    func testChecksumBitsForKnownEntropy() {
        // SHA-256 über 16 Nullbytes beginnt mit 0x37 = 0011 0111.
        // Bei 128 Bit Entropie sind 128/32 = 4 Prüfsummenbits zu nehmen: 0011.
        let entropy = [UInt8](repeating: 0x00, count: 16)
        XCTAssertEqual(BitStream.checksumBits(for: entropy, count: 4),
                       [false, false, true, true])
    }
}
