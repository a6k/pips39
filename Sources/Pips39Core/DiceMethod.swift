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
    public func rollCountHint(for length: SeedLength) -> String {
        switch self {
        case .sha256:
            return "Exactly \(length.rollsForHashedMethod) rolls."
        case .coleman:
            return "Around \(length.approximateColemanRolls) rolls, but the exact number varies."
        }
    }

    /// Die Schritte, mit denen der Nutzer das Ergebnis unabhängig nachrechnet.
    public func verificationSteps(for length: SeedLength) -> [String] {
        switch self {
        case .sha256:
            var steps = [
                "Run: printf '%s' \"<your rolls>\" | shasum -a 256"
            ]
            if length == .twelve {
                steps.append("Take only the first 32 hex characters — 12 words use 128 of the 256 bits.")
            }
            steps.append("Open iancoleman.io/bip39 and paste the hex into the Entropy field.")
            steps.append("Set Entropy type to Hex, then compare the words.")
            return steps
        case .coleman:
            return [
                "Open iancoleman.io/bip39.",
                "Select the Dice entropy type first — otherwise a sequence of only 1s is read as binary.",
                "Leave Mnemonic Length on Use Raw Entropy — a fixed word count hashes instead and truncates the other way.",
                "Enter exactly the rolls shown here, no more, and compare the words."
            ]
        }
    }

    /// Der Satz, ohne den der Nachrechnen-Bereich mehr schadet als nützt.
    public var verificationWarning: String {
        "Use a throwaway sequence to try this out. Never type your real rolls into a browser."
    }
}
