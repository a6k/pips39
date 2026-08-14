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

    /// Die Würfelanleitung von Shift Crypto, der Weg, der ohne diese App auskommt.
    ///
    /// Am 2026-08-14 geprüft, antwortet mit 200. Der Artikel liegt nur auf Deutsch vor;
    /// unter `/en/` mit demselben und mit übersetztem Slug antwortet der Server mit 404.
    /// Die englische Oberfläche verweist deshalb ebenfalls hierher.
    public static let bitboxGuide = "https://blog.bitbox.swiss/de/wurfle-deine-eigene-bitcoin-wallet/"
}
