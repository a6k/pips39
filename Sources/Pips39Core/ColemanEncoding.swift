import Foundation

/// Colemans Umrechnung von Würfen in Entropie, bitgenau nachgebaut.
///
/// Belegt am Quelltext von `iancoleman/bip39`, siehe `docs/coleman-verfahren.md`.
/// Jeder Wurf liefert ein oder zwei Bit; die Ausbeute liegt bei 1,67 Bit pro Wurf
/// statt der 2,585 Bit einer ganzzahligen Base-6-Umrechnung. Dafür ist die Abbildung
/// bias-frei.
enum ColemanEncoding {

    /// Bits eines einzelnen Wurfs. Die 6 wird wie eine 0 behandelt.
    static func bits(forRoll roll: UInt8) -> [Bool] {
        switch roll {
        case 1: return [false, true]    // 01
        case 2: return [true, false]    // 10
        case 3: return [true, true]     // 11
        case 4: return [false]          // 0
        case 5: return [true]           // 1
        case 6: return [false, false]   // 00 — die 6 wird zur 0
        default: preconditionFailure("Ungültiger Wurf \(roll), erlaubt sind 1…6")
        }
    }

    /// Alle Bits einer Wurffolge, in Wurfreihenfolge aneinandergehängt.
    static func rawBits(for rolls: [UInt8]) -> [Bool] {
        rolls.flatMap { bits(forRoll: $0) }
    }

    /// Kürzt Rohbits auf das nächstkleinere Vielfache von 32 und macht Bytes daraus.
    ///
    /// Coleman verwirft dabei die **vordersten** Bits:
    /// `start = bits.length - Math.floor(bits.length/32)*32`. Sein eigener Kommentar
    /// „Discard trailing entropy" ist falsch — es fällt der Anfang weg.
    /// Unter 32 Rohbits bleibt nichts übrig.
    static func entropy(fromRawBits bits: [Bool]) -> [UInt8] {
        let usable = (bits.count / 32) * 32
        guard usable > 0 else { return [] }
        let kept = Array(bits.suffix(usable))

        var bytes = [UInt8]()
        bytes.reserveCapacity(usable / 8)
        var index = kept.startIndex
        while index < kept.endIndex {
            var byte: UInt8 = 0
            for offset in 0..<8 {
                byte = (byte << 1) | (kept[index + offset] ? 1 : 0)
            }
            bytes.append(byte)
            index += 8
        }
        return bytes
    }

    /// Entropie direkt aus einer Wurffolge.
    static func entropy(from rolls: [UInt8]) -> [UInt8] {
        entropy(fromRawBits: rawBits(for: rolls))
    }
}
