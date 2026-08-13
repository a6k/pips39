import XCTest
@testable import Pips39Core

final class DiceEntropyResultTests: XCTestCase {

    private func filled(_ method: DiceMethod, with text: String) throws -> DiceEntropy {
        var buffer = DiceEntropy(method: method)
        for character in text {
            guard let value = character.wholeNumberValue else { continue }
            try buffer.append(UInt8(value))
        }
        return buffer
    }

    func testNoEntropyBeforeComplete() throws {
        let buffer = try filled(.sha256, with: String(repeating: "1", count: 98))
        XCTAssertNil(buffer.entropy())
    }

    func testHashedEntropyIs32Bytes() throws {
        let buffer = try filled(.sha256, with: String(repeating: "1", count: 99))
        let entropy = try XCTUnwrap(buffer.entropy())
        XCTAssertEqual(entropy.bytes.count, 32)
    }

    func testHashedProducesExpectedMnemonic() throws {
        let buffer = try filled(.sha256, with: String(repeating: "1", count: 99))
        let entropy = try XCTUnwrap(buffer.entropy())
        let words = try BIP39.mnemonic(from: entropy.bytes)
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(words.joined(separator: " "),
                       "wheel erase puppy pistol chapter accuse carpet drop quote final attend near scrap satisfy limit style crunch person south inspire lunch meadow enact tattoo")
    }

    func testColemanEntropyIsExactly32Bytes() throws {
        let buffer = try filled(.coleman, with: String(repeating: "1", count: 128))
        let entropy = try XCTUnwrap(buffer.entropy())
        XCTAssertEqual(entropy.bytes.count, 32)
    }

    func testColemanProducesTwentyFourValidWords() throws {
        let buffer = try filled(.coleman, with: String(repeating: "1", count: 128))
        let entropy = try XCTUnwrap(buffer.entropy())
        let words = try BIP39.mnemonic(from: entropy.bytes)
        XCTAssertEqual(words.count, 24)
        XCTAssertTrue(BIP39.isValid(mnemonic: words))
    }

    /// Der Kern der Sache: die beiden Verfahren liefern verschiedene Entropie.
    ///
    /// Ein Vergleich bei *identischer* Wurffolge ist nicht möglich — Verfahren B ist
    /// nach 99 Würfen fertig, Verfahren A braucht bei lauter Einsen 128. Genau
    /// deshalb muss das Verfahren neben dem Ergebnis stehen.
    func testMethodsProduceDifferentEntropy() throws {
        let hashed = try filled(.sha256, with: String(repeating: "1", count: 99))
        let coleman = try filled(.coleman, with: String(repeating: "1", count: 128))

        let a = try XCTUnwrap(coleman.entropy()).bytes
        let b = try XCTUnwrap(hashed.entropy()).bytes
        XCTAssertNotEqual(a, b, "Beide Verfahren dürfen nicht dasselbe liefern")
    }

    func testWipeClearsTheResult() throws {
        let buffer = try filled(.sha256, with: String(repeating: "1", count: 99))
        var entropy = try XCTUnwrap(buffer.entropy())
        entropy.wipe()
        XCTAssertEqual(entropy.bytes, [UInt8](repeating: 0, count: 32))
    }
}
