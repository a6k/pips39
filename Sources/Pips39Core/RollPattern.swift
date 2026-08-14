import Foundation

/// Erkennt Wurffolgen, die keine sein können.
///
/// **Bewusst kein Signifikanztest.** Ein Chi-Quadrat-Test bei 1 % Schwelle schlägt bei
/// jedem hundertsten *korrekten* Durchlauf an — und eine Warnung, die bei richtigem
/// Verhalten kommt, erzieht dazu, Warnungen wegzuklicken. Aus demselben Grund gibt es
/// hier keinen grünen „sicher"-Zustand.
///
/// Stattdessen gilt für **jedes** Muster dieselbe Regel: Es wird nur gemeldet, wenn
/// seine Wahrscheinlichkeit bei echtem Würfeln unter `maximumProbability` liegt. Die
/// Schwellen unten sind keine gewählten Zahlen, sondern das, was diese Regel für die
/// jeweilige Folgenlänge hergibt.
///
/// | Muster | bei 50 Würfen |
/// |---|---|
/// | alle gleich | 6⁻⁴⁹ ≈ 10⁻³⁸ |
/// | Wiederholung eines Blocks | ≤ 10⁻¹⁰ (siehe `minimumRepeatedTail`) |
/// | höchstens zwei Augenzahlen | ≈ 10⁻²³ |
/// | höchstens drei Augenzahlen | ≈ 10⁻¹⁴ |
/// | zu wenige Läufe | ≤ 10⁻⁹ (exakt gerechnet) |
///
/// `RollPatternTests.testRandomSequencesAreNeverFlagged` prüft das an 15 000 echten
/// Zufallsfolgen über sechs Längen nach.
///
/// **Was nicht gefunden wird:** geladene Würfel und leichte Schieflagen. Dafür bräuchte
/// es einen Signifikanztest; die Lücke gehört auf die Erklärseite.
public enum RollPattern {

    /// Die gemeinsame Obergrenze. Alles, was häufiger vorkommen kann, wird nicht
    /// gemeldet — auch dann nicht, wenn es für einen Menschen „komisch aussieht".
    private static let maximumProbability = 1e-9

    /// Unter zweiundzwanzig Würfen reicht keine der Prüfungen unter die Grenze.
    ///
    /// Bestimmt wird die Zahl von der schwächsten Prüfung, „nur zwei Augenzahlen":
    /// 15 · ((1/3)ⁿ − 2 · 6⁻ⁿ) ergibt bei 20 Würfen 4,3·10⁻⁹, bei 21 noch 1,4·10⁻⁹
    /// und erst bei 22 mit 4,8·10⁻¹⁰ einen Wert unter der Grenze. Hier stand vorher
    /// 20, und damit meldete die Prüfung etwas, das nach der eigenen Regel zu häufig
    /// vorkommt.
    ///
    /// „Alle gleich" läge schon ab 13 Würfen darunter (4,6·10⁻¹⁰). Zwei getrennte
    /// Schwellen wären genauer, brächten aber nur bei sehr kurzen Folgen etwas, und
    /// gewürfelt werden mindestens 50.
    private static let minimumLength = 22

    /// Ab hier liegt „höchstens drei Augenzahlen" unter der Grenze: 20 · 2⁻³⁵ ≈ 6·10⁻¹⁰.
    /// Bei zwanzig Würfen wären es noch etwa 1 zu 50 000 — zu häufig.
    private static let minimumLengthForThreeFaces = 35

    /// So viele Würfe muss die Wiederholung mindestens umfassen, damit eine Periode
    /// gemeldet wird: 6⁻¹³ ≈ 8·10⁻¹¹, aufsummiert über alle in Frage kommenden
    /// Periodenlängen rund 10⁻¹⁰ — unabhängig davon, wie lang die Folge ist.
    private static let minimumRepeatedTail = 13

    public enum Finding: Equatable {
        /// Alle Würfe zeigen dieselbe Augenzahl.
        case singleFace
        /// Die Folge ist die Wiederholung eines Blocks dieser Länge.
        case repeatingBlock(Int)
        /// Es kommen höchstens zwei verschiedene Augenzahlen vor.
        case twoFacesOnly
        /// Es kommen höchstens drei verschiedene Augenzahlen vor.
        case threeFacesOnly
        /// Die Folge zerfällt in so wenige Blöcke gleicher Augenzahl, dass es kein
        /// Zufall sein kann — etwa 11111 22222 33333 …
        case fewRuns(Int)
    }

    /// Die spezifischste Feststellung, oder `nil` wenn nichts auffällt.
    ///
    /// Die Reihenfolge ist die von der genaueren zur allgemeineren Aussage: Eine Folge
    /// aus lauter Zweien erfüllt alle fünf Bedingungen, gemeldet wird die erste.
    public static func finding(for rolls: [UInt8]) -> Finding? {
        guard rolls.count >= minimumLength else { return nil }

        let distinct = Set(rolls)
        if distinct.count == 1 { return .singleFace }
        if let period = shortestPeriod(of: rolls) { return .repeatingBlock(period) }
        if distinct.count <= 2 { return .twoFacesOnly }
        if distinct.count <= 3, rolls.count >= minimumLengthForThreeFaces {
            return .threeFacesOnly
        }

        let runs = runCount(of: rolls)
        if probabilityOfAtMost(runs: runs, in: rolls.count) <= maximumProbability {
            return .fewRuns(runs)
        }
        return nil
    }

    /// Die kürzeste Blocklänge, deren Wiederholung die ganze Folge ergibt.
    ///
    /// Die Obergrenze wächst mit der Folge: Entscheidend ist nicht, wie lang der Block
    /// ist, sondern wie viele Würfe die Wiederholung erzwingt. Deshalb findet die
    /// Prüfung bei zwanzig Würfen Perioden bis 7 und bei fünfzig bis 37.
    private static func shortestPeriod(of rolls: [UInt8]) -> Int? {
        let longestPeriod = rolls.count - minimumRepeatedTail
        guard longestPeriod >= 2 else { return nil }

        for period in 2...longestPeriod {
            if rolls.indices.allSatisfy({ rolls[$0] == rolls[$0 % period] }) {
                return period
            }
        }
        return nil
    }

    /// Die Zahl der Blöcke gleicher Augenzahl. Bei echtem Würfeln liegt sie nahe
    /// 1 + (n−1)·⅚ — bei fünfzig Würfen also um 42.
    private static func runCount(of rolls: [UInt8]) -> Int {
        guard let first = rolls.first else { return 0 }
        var count = 1
        var previous = first
        for roll in rolls.dropFirst() where roll != previous {
            count += 1
            previous = roll
        }
        return count
    }

    /// Exakte Wahrscheinlichkeit für höchstens so wenige Läufe.
    ///
    /// Zwischen zwei Würfen wechselt die Augenzahl mit ⅚, deshalb ist die Zahl der
    /// Läufe binomialverteilt: `P(R = k) = C(n−1, k−1) · (⅚)^(k−1) · (⅙)^(n−k)`.
    /// Über Logarithmen gerechnet, weil Binomialkoeffizient und Potenz einzeln längst
    /// überliefen.
    ///
    /// Das ist eine Teststatistik — der Unterschied zum verworfenen Chi-Quadrat-Test
    /// liegt nicht in der Methode, sondern in der Schwelle: Sie kommt aus der exakten
    /// Verteilung bei 10⁻⁹ und nicht aus einem üblichen Signifikanzniveau.
    ///
    /// **Nur der untere Schwanz.** Zu *wenige* Wechsel werden gemeldet, zu *viele*
    /// nicht. Wer bewusst nie dieselbe Augenzahl zweimal hintereinander notiert,
    /// erzeugt die maximale Wechselzahl und bleibt unbemerkt. Das kostet Entropie
    /// (bei 99 Würfen 230 statt 256 Bit), fiele nach der 10⁻⁹-Regel aber ohnehin
    /// erst ab etwa 154 Würfen unter die Grenze und wäre hier also gar nicht
    /// meldbar.
    private static func probabilityOfAtMost(runs: Int, in length: Int) -> Double {
        // Rückgabe 1, nicht 0: Eine 0 hieße „unmöglich" und führte zur Meldung.
        // Erreichbar ist der Zweig nicht, `finding` bricht vorher ab. Als Vorgabe
        // gehört trotzdem „nicht melden" ans Ende, nicht „melden".
        guard length > 0, runs >= 1 else { return 1 }

        let logChange = log(5.0 / 6.0)
        let logStay = log(1.0 / 6.0)
        var total = 0.0
        for k in 1...min(runs, length) {
            let logTerm = logBinomial(length - 1, k - 1)
                + Double(k - 1) * logChange
                + Double(length - k) * logStay
            total += exp(logTerm)
        }
        return total
    }

    private static func logBinomial(_ n: Int, _ k: Int) -> Double {
        guard k >= 0, k <= n else { return -.infinity }
        return lgamma(Double(n) + 1) - lgamma(Double(k) + 1) - lgamma(Double(n - k) + 1)
    }

    // MARK: Texte

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
        case .threeFacesOnly:  return Localized.string("pattern.threeFaces", locale)
        case .fewRuns:         return Localized.string("pattern.fewRuns", locale)
        }
    }

    /// Die Feststellung mit dem Weg hinaus, der auf diesem Bildschirm auch existiert.
    public static func notice(for finding: Finding,
                              advice: Advice,
                              locale: Locale = .current) -> String {
        statement(for: finding, locale: locale) + " " + Localized.string(advice.rawValue, locale)
    }
}
