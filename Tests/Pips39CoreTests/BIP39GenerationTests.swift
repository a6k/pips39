import XCTest
@testable import Pips39Core

final class BIP39GenerationTests: XCTestCase {

    private func entropy(_ hex: String) -> [UInt8] {
        var bytes = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            bytes.append(UInt8(hex[index..<next], radix: 16)!)
            index = next
        }
        return bytes
    }

    func testTwelveWordsAllZeroEntropy() throws {
        let words = try BIP39.mnemonic(from: entropy("00000000000000000000000000000000"))
        XCTAssertEqual(words.count, 12)
        XCTAssertEqual(words.joined(separator: " "),
                       "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")
    }

    func testTwelveWordsAllOnesEntropy() throws {
        let words = try BIP39.mnemonic(from: entropy("ffffffffffffffffffffffffffffffff"))
        XCTAssertEqual(words.joined(separator: " "),
                       "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong")
    }

    func testTwentyFourWordsAllZeroEntropy() throws {
        let words = try BIP39.mnemonic(
            from: entropy("0000000000000000000000000000000000000000000000000000000000000000"))
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(words.last, "art")
        XCTAssertEqual(Set(words.dropLast()), ["abandon"])
    }

    func testTwentyFourWordsAllOnesEntropy() throws {
        let words = try BIP39.mnemonic(
            from: entropy("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(words.last, "vote")
        XCTAssertEqual(Set(words.dropLast()), ["zoo"])
    }

    func testRejectsEntropyOfWrongLength() {
        XCTAssertThrowsError(try BIP39.mnemonic(from: [UInt8](repeating: 0, count: 15))) { error in
            XCTAssertEqual(error as? BIP39Error, .invalidEntropyLength(120))
        }
    }

    /// Für 21 Wörter gibt es keinen offiziellen Vektor, und über die Würfelverfahren
    /// ist diese Länge nicht erreichbar. Der Pfad war deshalb ungeprüft, obwohl
    /// `allowedWordCounts` ihn zulässt.
    func testTwentyOneWordsFromTwoHundredTwentyFourBits() throws {
        let entropy = [UInt8](repeating: 0x5A, count: 28)
        let words = try BIP39.mnemonic(from: entropy)
        XCTAssertEqual(words.count, 21)
        XCTAssertTrue(BIP39.isValid(mnemonic: words))
    }

    func testEveryAllowedWordCountCanBeGenerated() throws {
        for count in BIP39.allowedWordCounts {
            let entropyBytes = count * 11 * 32 / 33 / 8
            let words = try BIP39.mnemonic(from: [UInt8](repeating: 0x3C, count: entropyBytes))
            XCTAssertEqual(words.count, count, "\(entropyBytes) Byte ergaben nicht \(count) Wörter")
            XCTAssertTrue(BIP39.isValid(mnemonic: words))
        }
    }

    func testRejectsEmptyEntropy() {
        XCTAssertThrowsError(try BIP39.mnemonic(from: [])) { error in
            XCTAssertEqual(error as? BIP39Error, .invalidEntropyLength(0))
        }
    }
}
