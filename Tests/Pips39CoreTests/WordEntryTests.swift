import XCTest
@testable import Pips39Core

final class WordEntryTests: XCTestCase {

    private func entry(_ letters: String) -> WordEntry {
        var entry = WordEntry()
        for letter in letters {
            entry.append(letter)
        }
        return entry
    }

    // MARK: Ausgangszustand

    func testStartsEmpty() {
        let entry = WordEntry()
        XCTAssertEqual(entry.prefix, "")
        XCTAssertTrue(entry.isEmpty)
        XCTAssertTrue(entry.candidates.isEmpty, "Ohne Eingabe werden keine 2048 Wörter angeboten")
        XCTAssertNil(entry.uniqueMatch)
    }

    func testAllowedFirstLettersExcludeX() {
        let entry = WordEntry()
        XCTAssertEqual(entry.allowedNextLetters.count, 25)
        XCTAssertFalse(entry.allowedNextLetters.contains("x"), "Kein BIP39-Wort beginnt mit x")
        XCTAssertTrue(entry.allowedNextLetters.contains("a"))
        XCTAssertTrue(entry.allowedNextLetters.contains("z"))
    }

    // MARK: Tippen

    func testCandidatesNarrowDown() {
        XCTAssertEqual(entry("zo").candidates, ["zone", "zoo"])
    }

    func testUniqueMatchAfterEnoughLetters() {
        let entry = entry("zone")
        XCTAssertEqual(entry.candidates, ["zone"])
        XCTAssertEqual(entry.uniqueMatch, "zone")
    }

    /// Gilt für alle Wörter ab vier Buchstaben. Die 49 Präfix-Wörter sind
    /// ausgenommen — sie sind alle dreibuchstabig und lassen sich per Definition
    /// nicht durch Tippen auflösen, siehe den Test weiter unten.
    func testFourLettersAlwaysResolveToOneWord() {
        for word in WordList.english where word.count >= 4 {
            let typed = entry(String(word.prefix(4)))
            XCTAssertEqual(typed.uniqueMatch, word, "Präfix von \(word) nicht eindeutig")
        }
    }

    /// Die Gegenprobe: Alle 49 Präfix-Wörter bleiben nach dem Tippen mehrdeutig
    /// und müssen ausgewählt werden. Wären es plötzlich weniger, hätte eine
    /// Automatik sich eingeschlichen.
    func testEveryPrefixWordStaysAmbiguous() {
        let all = Set(WordList.english)
        let prefixWords = WordList.english.filter { word in
            all.contains { $0 != word && $0.hasPrefix(word) }
        }
        XCTAssertEqual(prefixWords.count, 49)
        for word in prefixWords {
            XCTAssertNil(entry(word).uniqueMatch,
                         "\(word) darf nicht automatisch übernommen werden")
            XCTAssertTrue(entry(word).candidates.contains(word),
                          "\(word) muss trotzdem als Kandidat angeboten werden")
        }
    }

    func testImpossibleLetterIsIgnored() {
        var typed = entry("zo")
        typed.append("q")   // es gibt kein Wort "zoq…"
        XCTAssertEqual(typed.prefix, "zo", "Unmögliche Buchstaben dürfen nicht landen")
    }

    func testUppercaseIsAccepted() {
        XCTAssertEqual(entry("ZO").prefix, "zo")
    }

    func testNonLetterIsIgnored() {
        var typed = WordEntry()
        typed.append("1")
        typed.append("-")
        XCTAssertTrue(typed.isEmpty)
    }

    // MARK: Löschen und Zurücksetzen

    func testDeleteLastStepsBack() {
        var typed = entry("zon")
        typed.deleteLast()
        XCTAssertEqual(typed.prefix, "zo")
        XCTAssertEqual(typed.candidates, ["zone", "zoo"])
    }

    func testDeleteOnEmptyDoesNothing() {
        var typed = WordEntry()
        typed.deleteLast()
        XCTAssertTrue(typed.isEmpty)
    }

    func testResetClearsEverything() {
        var typed = entry("zone")
        typed.reset()
        XCTAssertTrue(typed.isEmpty)
        XCTAssertTrue(typed.candidates.isEmpty)
    }

    // MARK: Die 49 Präfix-Wörter

    /// `act` ist selbst ein Wort UND Präfix von `action` und `actor`.
    /// Hier darf nichts automatisch übernommen werden.
    func testWordThatIsAlsoAPrefixHasNoUniqueMatch() {
        let typed = entry("act")
        XCTAssertTrue(typed.candidates.contains("act"))
        XCTAssertGreaterThan(typed.candidates.count, 1)
        XCTAssertNil(typed.uniqueMatch, "act darf nicht automatisch übernommen werden")
    }

    func testShortWordIsStillOfferedAsCandidate() {
        XCTAssertTrue(entry("add").candidates.contains("add"))
        XCTAssertTrue(entry("age").candidates.contains("age"))
    }

    /// Es gibt genau 49 solcher Fälle. Ändert sich die Zahl, hat sich die
    /// Wortliste geändert — dann ist etwas faul.
    func testExactlyFortyNineWordsArePrefixOfAnother() {
        let all = Set(WordList.english)
        let prefixes = WordList.english.filter { word in
            all.contains { $0 != word && $0.hasPrefix(word) }
        }
        XCTAssertEqual(prefixes.count, 49)
    }

    // MARK: Nächste Buchstaben

    func testAllowedNextLettersAfterPrefix() {
        // Nach "zo" führen nur "n" (zone) und "o" (zoo) weiter.
        XCTAssertEqual(entry("zo").allowedNextLetters, ["n", "o"])
    }

    func testNoNextLettersWhenWordIsComplete() {
        XCTAssertTrue(entry("zoo").allowedNextLetters.isEmpty)
    }
}
