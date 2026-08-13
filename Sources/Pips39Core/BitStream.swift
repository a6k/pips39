import Foundation
import CryptoKit

/// Bit-Werkzeuge für BIP39. Bewusst frei von Zustand und ohne Kenntnis der Wortliste.
enum BitStream {

    /// Zerlegt Bytes in Bits, höchstwertiges Bit zuerst.
    static func bits(from bytes: [UInt8]) -> [Bool] {
        var result = [Bool]()
        result.reserveCapacity(bytes.count * 8)
        for byte in bytes {
            for shift in stride(from: 7, through: 0, by: -1) {
                result.append((byte >> shift) & 1 == 1)
            }
        }
        return result
    }

    /// Bündelt Bits zu 11-Bit-Werten. Die Bitanzahl muss durch 11 teilbar sein.
    static func groupsOfEleven(_ bits: [Bool]) -> [Int] {
        precondition(bits.count % 11 == 0, "Bitanzahl \(bits.count) ist nicht durch 11 teilbar")
        var result = [Int]()
        result.reserveCapacity(bits.count / 11)
        var index = bits.startIndex
        while index < bits.endIndex {
            var value = 0
            for offset in 0..<11 {
                value = (value << 1) | (bits[index + offset] ? 1 : 0)
            }
            result.append(value)
            index += 11
        }
        return result
    }

    /// Die ersten `count` Bits des SHA-256 über die Entropie.
    static func checksumBits(for entropy: [UInt8], count: Int) -> [Bool] {
        let digest = SHA256.hash(data: Data(entropy))
        return Array(bits(from: Array(digest)).prefix(count))
    }
}
