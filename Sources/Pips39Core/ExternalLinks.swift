import Foundation

/// Die beiden Adressen, die das Onboarding anbietet.
///
/// Im Paket und nicht in der Ansicht, damit ein Test sie erwischt: Eine App, die zum
/// Abschotten anleitet, darf nirgends auf `http` verweisen.
public enum ExternalLinks {

    /// Ian Colemans BIP39-Werkzeug — die Referenz, gegen die geprüft wird.
    public static let colemanTool = "https://iancoleman.io/bip39/"

    /// Der Quelltext. „Open Source" heißt beim Store-Download geprüfter Quelltext,
    /// nicht geprüftes Binary — wer Gewissheit will, baut hier selbst.
    public static let sourceCode = "https://github.com/a6k/pips39"

    /// Die Würfelanleitung von Shift Crypto — der Weg, der ohne diese App auskommt.
    ///
    /// Bewusst die Startseite und kein tiefer Link: Eine Unterseite, die umzieht,
    /// schickt Leute ins Leere, und dieser Link steht an der Stelle mit der größten
    /// Reichweite. Wer eine stabile Direktadresse zur Anleitung hat, trägt sie hier
    /// ein — dann bitte vorher im Browser öffnen.
    public static let bitboxGuide = "https://bitbox.swiss"
}
