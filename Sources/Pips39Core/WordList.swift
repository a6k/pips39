import Foundation

/// Die offizielle englische BIP39-Wortliste (2048 Wörter), aus der Ressourcendatei geladen.
public enum WordList {

    /// Alle 2048 Wörter in der normativen Reihenfolge. Der Index entspricht dem 11-Bit-Wert.
    public static let english: [String] = loadEnglish()

    private static let indexByWord: [String: Int] = {
        var map = [String: Int](minimumCapacity: 2048)
        for (index, word) in english.enumerated() {
            map[word] = index
        }
        return map
    }()

    /// Index eines Wortes, oder `nil` wenn es nicht zur Liste gehört.
    public static func index(of word: String) -> Int? {
        indexByWord[word]
    }

    private static func loadEnglish() -> [String] {
        guard let url = Bundle.module.url(forResource: "english", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            preconditionFailure("BIP39-Wortliste fehlt im Bundle — Paket ist defekt")
        }
        let words = raw
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        precondition(words.count == 2048, "BIP39-Wortliste hat \(words.count) statt 2048 Wörter")
        return words
    }
}
