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
}
