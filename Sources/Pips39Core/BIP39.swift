import Foundation

public enum BIP39Error: Error, Equatable {
    /// Entropie hat nicht 128, 160, 192, 224 oder 256 Bit. Der Wert ist die tatsächliche Bitzahl.
    case invalidEntropyLength(Int)
}

/// Umsetzung von BIP39, Teil „Entropie → Mnemonic".
///
/// Nicht enthalten: die Ableitung des 512-Bit-Seeds per PBKDF2. Die macht die Wallet,
/// nicht dieses Werkzeug.
public enum BIP39 {

    /// Erlaubte Entropiegrößen in Bit, nach BIP39.
    public static let allowedEntropyBits = [128, 160, 192, 224, 256]

    /// Erzeugt die Mnemonic-Wörter zu einer gegebenen Entropie.
    public static func mnemonic(from entropy: [UInt8]) throws -> [String] {
        let entropyBits = entropy.count * 8
        guard allowedEntropyBits.contains(entropyBits) else {
            throw BIP39Error.invalidEntropyLength(entropyBits)
        }

        let checksumLength = entropyBits / 32
        let allBits = BitStream.bits(from: entropy)
            + BitStream.checksumBits(for: entropy, count: checksumLength)

        return BitStream.groupsOfEleven(allBits).map { WordList.english[$0] }
    }
}
