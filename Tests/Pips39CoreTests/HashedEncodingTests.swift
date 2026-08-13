import XCTest
@testable import Pips39Core

final class HashedEncodingTests: XCTestCase {

    private func rolls(_ text: String) -> [UInt8] {
        text.compactMap { $0.wholeNumberValue.map(UInt8.init) }
    }

    private func hexString(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// Werte erzeugt mit `printf '%s' "<Folge>" | shasum -a 256`.
    func testHashMatchesShasumForNinetyNineOnes() {
        let entropy = HashedEncoding.entropy(from: rolls(String(repeating: "1", count: 99)))
        XCTAssertEqual(hexString(entropy),
                       "fa098eb852b2660348b21bb00ad03a49cc177ea07ebe34f46b40baa85313525e")
    }

    func testHashMatchesShasumForNinetyNineSixes() {
        let entropy = HashedEncoding.entropy(from: rolls(String(repeating: "6", count: 99)))
        XCTAssertEqual(hexString(entropy),
                       "7efb8e5d1353a90137755f711e1763fd7301a033fbb854889e127ff79c389131")
    }

    func testHashMatchesShasumForMixedSequence() {
        let mixed = String(String(repeating: "142536", count: 17).prefix(99))
        let entropy = HashedEncoding.entropy(from: rolls(mixed))
        XCTAssertEqual(hexString(entropy),
                       "fa8ee59f391c1d8cd485f88a29dfee82ddbac1012bf695b8dfd513b7fcafa5b7")
    }

    func testHashMatchesShasumForShortSequence() {
        let entropy = HashedEncoding.entropy(from: rolls("123456"))
        XCTAssertEqual(hexString(entropy),
                       "8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92")
    }

    func testAlwaysProduces32Bytes() {
        XCTAssertEqual(HashedEncoding.entropy(from: rolls("1")).count, 32)
        XCTAssertEqual(HashedEncoding.entropy(from: []).count, 32)
    }

    /// Die 6 wird NICHT zur 0 — anders als bei Verfahren A.
    func testSixIsHashedAsSixNotZero() {
        let asSix = HashedEncoding.entropy(from: rolls("666"))
        let asZero = HashedEncoding.entropy(from: [0, 0, 0])
        XCTAssertNotEqual(asSix, asZero)
    }

    func testProducesTwentyFourWordsFromNinetyNineRolls() throws {
        let entropy = HashedEncoding.entropy(from: rolls(String(repeating: "1", count: 99)))
        let words = try BIP39.mnemonic(from: entropy)
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(words.joined(separator: " "),
                       "wheel erase puppy pistol chapter accuse carpet drop quote final attend near scrap satisfy limit style crunch person south inspire lunch meadow enact tattoo")
    }
}
