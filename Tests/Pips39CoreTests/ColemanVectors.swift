import XCTest
@testable import Pips39Core

/// Zugriff auf die mit Colemans echtem JavaScript erzeugten Referenzvektoren.
enum ColemanVectors {

    struct Vector: Decodable {
        let name: String
        let wuerfe: String
        let entropieHex: String
        let mnemonic: String
        let rohBinaer: String
        let rohBits: Int
        let genutzteBits: Int
        let woerter: Int

        /// Die Wurffolge als Ziffern 1…6.
        var rollDigits: [UInt8] {
            wuerfe.compactMap { $0.wholeNumberValue.map(UInt8.init) }
        }
    }

    private struct File: Decodable {
        let vektoren: [Vector]
    }

    static func load() throws -> [Vector] {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "coleman-vectors", withExtension: "json"),
            "coleman-vectors.json fehlt im Test-Bundle"
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(File.self, from: Data(contentsOf: url)).vektoren
    }
}
