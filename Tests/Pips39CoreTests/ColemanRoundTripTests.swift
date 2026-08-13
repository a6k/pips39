import XCTest
@testable import Pips39Core

/// Der Beweis für Verfahren A: gleiche Würfe, gleiche Wörter wie bei Coleman.
final class ColemanRoundTripTests: XCTestCase {

    func testMnemonicMatchesColemanForEveryVector() throws {
        for vector in try ColemanVectors.load() {
            let entropy = ColemanEncoding.entropy(from: vector.rollDigits)

            guard !entropy.isEmpty else {
                XCTAssertEqual(vector.mnemonic, "",
                               "Coleman liefert Wörter, wir nicht: \(vector.name)")
                XCTAssertEqual(vector.woerter, 0, "Wortzahl passt nicht: \(vector.name)")
                continue
            }

            let words = try BIP39.mnemonic(from: entropy)
            XCTAssertEqual(words.joined(separator: " "), vector.mnemonic,
                           "Wörter weichen ab bei: \(vector.name)")
            XCTAssertEqual(words.count, vector.woerter,
                           "Wortzahl weicht ab bei: \(vector.name)")
        }
    }

    func testEveryProducedMnemonicIsValid() throws {
        for vector in try ColemanVectors.load() {
            let entropy = ColemanEncoding.entropy(from: vector.rollDigits)
            guard !entropy.isEmpty else { continue }
            let words = try BIP39.mnemonic(from: entropy)
            XCTAssertTrue(BIP39.isValid(mnemonic: words),
                          "Erzeugtes Mnemonic gilt als ungültig: \(vector.name)")
        }
    }
}
