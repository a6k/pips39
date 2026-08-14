import Foundation

/// Nachschlagen im Paket-Bundle mit **erzwingbarer** Sprache.
///
/// > [!warning] `String(localized:locale:)` wählt die Sprache nicht aus
/// > Der `locale:`-Parameter dort steuert nur Formatierung — Zahlen, Daten,
/// > Pluralformen. Welches `.lproj` genommen wird, entscheiden die bevorzugten
/// > Sprachen des Prozesses. Auf einem deutschen Mac liefert eine Abfrage mit
/// > `locale: "en"` deshalb die **deutsche** Fassung.
/// >
/// > Für die Regeltests wäre das fatal: Sie würden zweimal dieselbe Sprache prüfen
/// > und trotzdem grün sein. Deshalb geht es hier über ein eigenes Bundle je Sprache.
/// >
/// > Gemessen und belegt in `docs/lokalisierung-mechanismus.md`.
enum Localized {

    static func string(_ key: String, _ locale: Locale = .current) -> String {
        NSLocalizedString(key, bundle: bundle(for: locale), comment: "")
    }

    static func string(_ key: String, _ locale: Locale = .current, _ number: Int) -> String {
        String(format: string(key, locale), number)
    }

    /// Sucht das passende `.lproj` — erst die vollständige Kennung („de_DE"), dann
    /// den Sprachcode („de"), zuletzt Englisch als Vorgabe.
    private static func bundle(for locale: Locale) -> Bundle {
        let candidates: [String?] = [
            locale.identifier,
            locale.language.languageCode?.identifier,
            "en"
        ]

        for code in candidates.compactMap({ $0 }) {
            if let path = Bundle.module.path(forResource: code, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return .module
    }
}
