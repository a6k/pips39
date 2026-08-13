import XCTest
@testable import Pips39Core

final class OfficialVectorTests: XCTestCase {

    private struct VectorFile: Decodable {
        let english: [[String]]
    }

    private func loadVectors() throws -> [(entropyHex: String, mnemonic: String)] {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "vectors", withExtension: "json"),
            "vectors.json fehlt im Test-Bundle"
        )
        let file = try JSONDecoder().decode(VectorFile.self, from: Data(contentsOf: url))
        return file.english.map { (entropyHex: $0[0], mnemonic: $0[1]) }
    }

    private func bytes(fromHex hex: String) -> [UInt8] {
        var result = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            result.append(UInt8(hex[index..<next], radix: 16)!)
            index = next
        }
        return result
    }

    func testVectorFileIsNotEmpty() throws {
        XCTAssertGreaterThan(try loadVectors().count, 10)
    }

    func testAllOfficialVectorsProduceExpectedMnemonic() throws {
        for vector in try loadVectors() {
            let produced = try BIP39.mnemonic(from: bytes(fromHex: vector.entropyHex))
            XCTAssertEqual(produced.joined(separator: " "), vector.mnemonic,
                           "Abweichung bei Entropie \(vector.entropyHex)")
        }
    }

    func testAllOfficialVectorsRoundTripThroughValidation() throws {
        throw XCTSkip("BIP39.isValid entsteht in Task 6")
    }
}
