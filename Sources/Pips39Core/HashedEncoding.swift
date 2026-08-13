import Foundation
import CryptoKit

/// Verfahren B: SHA-256 über die Wurffolge, so wie sie gewürfelt wurde.
///
/// Die Ziffern werden als ASCII gehasst — die 6 bleibt eine 6. Das unterscheidet
/// dieses Verfahren von `ColemanEncoding`, wo die 6 vor der Umrechnung zur 0 wird.
///
/// Nachprüfbar mit `printf '%s' "<Wurffolge>" | shasum -a 256`; der Hex-Wert lässt
/// sich anschließend in jedes BIP39-Werkzeug als Entropie einsetzen.
enum HashedEncoding {

    /// Immer 32 Byte, unabhängig von der Wurfzahl.
    static func entropy(from rolls: [UInt8]) -> [UInt8] {
        let ascii = rolls.map { UInt8(ascii: "0") + $0 }
        return Array(SHA256.hash(data: Data(ascii)))
    }
}
