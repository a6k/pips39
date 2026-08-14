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
}
