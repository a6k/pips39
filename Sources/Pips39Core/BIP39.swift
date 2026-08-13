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

    /// Erlaubte Wortanzahlen, abgeleitet aus den erlaubten Entropiegrößen.
    public static let allowedWordCounts = allowedEntropyBits.map { ($0 + $0 / 32) / 11 }

    /// Prüft, ob eine Wortfolge eine gültige BIP39-Mnemonic ist — bekannte Wörter,
    /// zulässige Länge und stimmige Prüfsumme.
    public static func isValid(mnemonic words: [String]) -> Bool {
        guard allowedWordCounts.contains(words.count) else { return false }

        var bits = [Bool]()
        bits.reserveCapacity(words.count * 11)
        for word in words {
            guard let index = WordList.index(of: word) else { return false }
            for shift in stride(from: 10, through: 0, by: -1) {
                bits.append((index >> shift) & 1 == 1)
            }
        }

        let entropyBits = words.count * 11 * 32 / 33
        let checksumLength = entropyBits / 32
        let entropy = bytes(fromBits: Array(bits.prefix(entropyBits)))
        let expected = BitStream.checksumBits(for: entropy, count: checksumLength)

        return Array(bits.suffix(checksumLength)) == expected
    }

    /// Position des ersten Unterschieds zwischen erzeugter und abgetippter Wortfolge,
    /// oder `nil` wenn beide gleich sind. Unterschiedliche Längen zählen ab der
    /// ersten fehlenden Position als Abweichung.
    public static func firstMismatch(between expected: [String], and typed: [String]) -> Int? {
        for position in 0..<Swift.min(expected.count, typed.count) where expected[position] != typed[position] {
            return position
        }
        return expected.count == typed.count ? nil : Swift.min(expected.count, typed.count)
    }

    private static func bytes(fromBits bits: [Bool]) -> [UInt8] {
        precondition(bits.count % 8 == 0, "Bitanzahl \(bits.count) ist nicht durch 8 teilbar")
        var result = [UInt8]()
        result.reserveCapacity(bits.count / 8)
        var index = bits.startIndex
        while index < bits.endIndex {
            var byte: UInt8 = 0
            for offset in 0..<8 {
                byte = (byte << 1) | (bits[index + offset] ? 1 : 0)
            }
            result.append(byte)
            index += 8
        }
        return result
    }
}
