import Foundation

/// Die Eingabe eines einzelnen BIP39-Wortes, Buchstabe für Buchstabe.
///
/// Lässt nur Buchstaben zu, die zu mindestens einem Wort der Liste führen — damit
/// kann gar kein ungültiges Wort entstehen. Ersetzt bewusst die iOS-Systemtastatur,
/// die getippte Wörter lernt und durch Dritt-Tastaturen austauschbar ist.
public struct WordEntry {

    /// Die bisher getippten Buchstaben, immer klein.
    public private(set) var prefix: String = ""

    public init() {}

    public var isEmpty: Bool { prefix.isEmpty }

    /// Alle Wörter, die mit dem bisherigen Präfix beginnen.
    /// Ohne Eingabe leer — die vollständige Liste anzubieten hülfe niemandem.
    public var candidates: [String] {
        guard !prefix.isEmpty else { return [] }
        return WordList.english.filter { $0.hasPrefix(prefix) }
    }

    /// Buchstaben, die zu mindestens einem weiteren Wort führen.
    public var allowedNextLetters: Set<Character> {
        let pool = prefix.isEmpty ? WordList.english : candidates
        let position = prefix.count
        return Set(pool.compactMap { word -> Character? in
            guard word.count > position else { return nil }
            return Array(word)[position]
        })
    }

    /// Das Wort, wenn genau eines übrig ist — sonst `nil`.
    ///
    /// Bewusst streng: 49 Wörter sind zugleich Präfix eines anderen (`act` in
    /// `action`), und bei denen wäre jede Automatik geraten. Der Nutzer wählt.
    public var uniqueMatch: String? {
        let matches = candidates
        return matches.count == 1 ? matches[0] : nil
    }

    /// Nimmt einen Buchstaben an, sofern er zu einem Wort führt. Alles andere
    /// wird ignoriert — ein Fehlerzustand hilft an dieser Stelle niemandem.
    ///
    /// `lowercased()` liefert eine Zeichenkette, die bei manchen Zeichen länger als
    /// eins ist. Deshalb über `first` statt über `Character(_:)`, das dabei abstürzen
    /// würde.
    public mutating func append(_ letter: Character) {
        guard let lower = letter.lowercased().first,
              letter.lowercased().count == 1,
              lower.isLetter,
              allowedNextLetters.contains(lower) else { return }
        prefix.append(lower)
    }

    public mutating func deleteLast() {
        if !prefix.isEmpty {
            prefix.removeLast()
        }
    }

    public mutating func reset() {
        prefix = ""
    }
}
