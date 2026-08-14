import Foundation

/// Erkennt Wurffolgen, die keine sein können.
///
/// **Bewusst keine Statistik.** Ein Test auf „sieht zufällig aus" hätte
/// mathematisch garantierte Fehlalarme — ein Chi-Quadrat-Test bei 1 % Schwelle
/// schlägt bei jedem hundertsten *korrekten* Durchlauf an. Und eine Warnung, die bei
/// richtigem Verhalten kommt, erzieht dazu, Warnungen wegzuklicken. Aus demselben
/// Grund gibt es hier keinen grünen „sicher"-Zustand.
///
/// Stattdessen werden nur Muster festgestellt, deren Wahrscheinlichkeit bei echtem
/// Würfeln verschwindet. Bei 50 Würfen — dem kürzesten Fall:
///
/// | Muster | Wahrscheinlichkeit |
/// |---|---|
/// | alle gleich | 6⁻⁴⁹ ≈ 10⁻³⁸ |
/// | Wiederholung eines Blocks ≤ 6 | ≈ 10⁻³⁵ |
/// | höchstens zwei Augenzahlen | ≈ 10⁻²³ |
///
/// `RollPatternTests.testRandomSequencesAreNeverFlagged` prüft das an 10 000 echten
/// Zufallsfolgen nach.
///
/// **Was nicht gefunden wird:** geladene Würfel und im Kopf ausgedachte Folgen.
/// Dafür bräuchte es wieder Statistik; die Lücke gehört auf die Erklärseite.
public enum RollPattern {

    /// Unter dieser Länge sind die Wahrscheinlichkeiten nicht mehr vernachlässigbar.
    private static let minimumLength = 20

    public enum Finding: Equatable {
        /// Alle Würfe zeigen dieselbe Augenzahl.
        case singleFace
        /// Die Folge ist die Wiederholung eines Blocks dieser Länge.
        case repeatingBlock(Int)
        /// Es kommen höchstens zwei verschiedene Augenzahlen vor.
        case twoFacesOnly
    }

    /// Die spezifischste Feststellung, oder `nil` wenn nichts auffällt.
    public static func finding(for rolls: [UInt8]) -> Finding? {
        guard rolls.count >= minimumLength else { return nil }

        let distinct = Set(rolls)
        if distinct.count == 1 { return .singleFace }
        if let period = shortestPeriod(of: rolls) { return .repeatingBlock(period) }
        if distinct.count <= 2 { return .twoFacesOnly }
        return nil
    }

    /// Die kürzeste Blocklänge bis 6, deren Wiederholung die ganze Folge ergibt.
    private static func shortestPeriod(of rolls: [UInt8]) -> Int? {
        for period in 2...6 where rolls.count > period {
            if rolls.indices.allSatisfy({ rolls[$0] == rolls[$0 % period] }) {
                return period
            }
        }
        return nil
    }

    /// Wo der Hinweis steht — und damit, welcher Weg hinaus genannt wird.
    ///
    /// Der Schlusssatz gehört zum Bildschirm, nicht zum Befund: Die Würfelansicht hat
    /// keinen Knopf „Verwerfen", dort führt der Weg über Zurück. Ein gemeinsamer Text
    /// würde auf einem der beiden Bildschirme eine Handlung nennen, die es dort nicht
    /// gibt — und wer eine Anweisung nicht befolgen kann, glaubt beim nächsten Mal
    /// auch der Feststellung nicht mehr.
    public enum Advice: String, CaseIterable {
        /// Würfelansicht: zurück zur Verfahrenswahl.
        case whileRolling = "pattern.advice.rolling"
        /// Wortanzeige: der Verwerfen-Knopf steht oben rechts.
        case atResult = "pattern.advice.result"
    }

    /// Was zu sehen ist. Eine Feststellung über die Folge, ohne zu behaupten, dass
    /// etwas kaputt sei — die Wörter sind gültig, wer tatsächlich so gewürfelt hat,
    /// darf sie behalten.
    public static func statement(for finding: Finding, locale: Locale = .current) -> String {
        switch finding {
        case .singleFace:      return Localized.string("pattern.singleFace", locale)
        case .repeatingBlock:  return Localized.string("pattern.repeating", locale)
        case .twoFacesOnly:    return Localized.string("pattern.twoFaces", locale)
        }
    }

    /// Die Feststellung mit dem Weg hinaus, der auf diesem Bildschirm auch existiert.
    public static func notice(for finding: Finding,
                              advice: Advice,
                              locale: Locale = .current) -> String {
        statement(for: finding, locale: locale) + " " + Localized.string(advice.rawValue, locale)
    }
}
