import Foundation

/// Wie viele Wörter der Seed haben soll.
///
/// 128 bit sind nicht brechbar, gegen 12 Wörter spricht sicherheitstechnisch nichts.
/// Der Vorgabewert ist trotzdem 24, weil die Würfel-Community dogmatisch dazu neigt
/// und ein vorausgewähltes 12 als Lässigkeit gelesen würde.
public enum SeedLength: Int, CaseIterable, Identifiable, Equatable {

    case twelve = 12
    case twentyFour = 24

    public static let standard: SeedLength = .twentyFour

    public var id: Int { rawValue }
    public var wordCount: Int { rawValue }

    /// Die Entropiegröße nach BIP39: Wortzahl × 11 Bit, abzüglich der Prüfsumme.
    public var entropyBits: Int { wordCount * 11 * 32 / 33 }

    /// Feste Wurfzahl für Verfahren B.
    ///
    /// Konvention, keine Formel: 256 / log2(6) = 99,03 — aufgerundet wären es 100.
    /// 99 Würfe tragen 255,9 bit in einen 256-bit-Hash, der Unterschied ist belanglos,
    /// und 99 ist die Zahl, die auch ColdCard benutzt.
    public var rollsForHashedMethod: Int {
        switch self {
        case .twelve:     return 50
        case .twentyFour: return 99
        }
    }

    /// Grobe Erwartung für Verfahren A — dort steht die Wurfzahl nicht fest,
    /// jeder Wurf liefert ein oder zwei Bit (im Mittel 1,67).
    public var approximateColemanRolls: Int {
        switch self {
        case .twelve:     return 77
        case .twentyFour: return 154
        }
    }

    /// Beschriftung für den Schalter.
    public var title: String { "\(wordCount) words" }
}
