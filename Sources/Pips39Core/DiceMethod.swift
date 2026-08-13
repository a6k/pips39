import Foundation

/// Das Verfahren, mit dem aus Würfen Entropie wird.
///
/// Die Wahl gehört zum Ergebnis, nicht in die Einstellungen: Eine Wurffolge sagt
/// nicht, mit welchem Verfahren sie gerechnet wurde, und dieselbe Folge ergibt unter
/// beiden Verfahren verschiedene, jeweils gültige Mnemonics.
public enum DiceMethod: String, CaseIterable, Equatable {

    /// SHA-256 über die Wurffolge, wie sie gewürfelt wurde. Feste Wurfzahl.
    /// Standard. Nachprüfbar mit `printf '%s' "…" | shasum -a 256`.
    case sha256

    /// Colemans Bit-Tabelle, bitgenau nachgebaut. Keine feste Wurfzahl.
    /// Nachprüfbar durch direkte Eingabe der Wurffolge bei iancoleman.io/bip39.
    case coleman

    /// Das voreingestellte Verfahren.
    public static let standard: DiceMethod = .sha256

    /// Kurzer Name für die Oberfläche. Englisch — die Zielgruppe ist international.
    public var title: String {
        switch self {
        case .sha256:  return "SHA-256"
        case .coleman: return "Coleman"
        }
    }

    /// Ein Satz dazu, was das Verfahren tut.
    public var summary: String {
        switch self {
        case .sha256:
            return "Your dice sequence is hashed with SHA-256. Verify with shasum and any BIP39 tool."
        case .coleman:
            return "Bit-for-bit identical to iancoleman.io/bip39. Verify by entering the same rolls there."
        }
    }

    /// Was den Nutzer an Würfelarbeit erwartet. Verfahren A darf keine feste Zahl
    /// nennen — dort liefert jeder Wurf ein oder zwei Bit.
    public var rollCountHint: String {
        switch self {
        case .sha256:  return "Exactly 99 rolls."
        case .coleman: return "Around 154 rolls, but the exact number varies."
        }
    }
}
