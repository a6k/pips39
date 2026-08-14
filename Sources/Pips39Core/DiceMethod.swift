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
    public func summary(locale: Locale = .current) -> String {
        switch self {
        case .sha256:  return Localized.string("method.sha256.summary", locale)
        case .coleman: return Localized.string("method.coleman.summary", locale)
        }
    }

    /// Was den Nutzer an Würfelarbeit erwartet. Verfahren A darf keine feste Zahl
    /// nennen — dort liefert jeder Wurf ein oder zwei Bit.
    public func rollCountHint(for length: SeedLength, locale: Locale = .current) -> String {
        switch self {
        case .sha256:
            return Localized.string("method.sha256.rollCount", locale, length.rollsForHashedMethod)
        case .coleman:
            return Localized.string("method.coleman.rollCount", locale, length.approximateColemanRolls)
        }
    }

    /// Die Schritte, mit denen der Nutzer das Ergebnis unabhängig nachrechnet.
    ///
    /// Der `shasum`-Befehl und Colemans Bedienelemente („Dice", „Use Raw Entropy")
    /// bleiben in **jeder** Sprache englisch — übersetzt zeigten sie auf Knöpfe, die
    /// es auf seiner Seite nicht gibt. `LocalizationRuleTests` nagelt das fest.
    public func verificationSteps(for length: SeedLength,
                                  locale: Locale = .current) -> [String] {
        switch self {
        case .sha256:
            var steps = [Localized.string("verify.sha256.step.hash", locale)]
            if length == .twelve {
                steps.append(Localized.string("verify.sha256.step.truncate", locale))
            }
            steps.append(Localized.string("verify.sha256.step.paste", locale))
            steps.append(Localized.string("verify.sha256.step.compare", locale))
            return steps
        case .coleman:
            return [
                Localized.string("verify.coleman.step.open", locale),
                Localized.string("verify.coleman.step.dice", locale),
                Localized.string("verify.coleman.step.raw", locale),
                Localized.string("verify.coleman.step.enter", locale)
            ]
        }
    }

    /// Der Satz, ohne den der Nachrechnen-Bereich mehr schadet als nützt.
    public func verificationWarning(locale: Locale = .current) -> String {
        Localized.string("verify.warning", locale)
    }
}
