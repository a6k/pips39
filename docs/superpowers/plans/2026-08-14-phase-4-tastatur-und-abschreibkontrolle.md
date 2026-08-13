# Pips39 — Phase 4: BIP39-Tastatur und Abschreibkontrolle — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Der Nutzer tippt die notierten 24 Wörter zurück, die App sagt ihm Position für Position, ob sie stimmen — über eine eigene Tastatur, die nur BIP39-Wörter zulässt.

**Architecture:** Zwei neue Modelle im Swift Package (`WordEntry`, `TranscriptionCheck`), beide ohne UI und mit `swift test` prüfbar. Darüber zwei dumme SwiftUI-Ansichten im App-Target. Wie in Phase 3 liegt jede Entscheidung im Paket.

**Tech Stack:** SwiftUI, Combine, Swift 5.9, iOS 16.

**Spec:** `~/Documents/Doku/02 Projekte/Ideen und Tests/Pips39/würfel-tool-spec.md`, Abschnitte 2.2 und 2.3

**Vorhanden aus Phasen 1–3:** `WordList`, `BitStream`, `BIP39`, `SecretBytes`, `DiceMethod`, `ColemanEncoding`, `HashedEncoding`, `DiceEntropy`, `DiceProgress`, `DiceError`, `DiceSession`; App mit `MethodChoiceView`, `RollingView`, `WordsView`, `ScreenProtection`, `ContentView`. 90 Tests grün, App läuft im Simulator.

**Nicht in dieser Phase:** `EnvironmentProbe`, Nachrechnen-Bereich, Erklärseite (Phase 5).

---

## Warum es eine eigene Tastatur sein muss

Spec 2.3, nicht verhandelbar: Die iOS-Systemtastatur lernt getippte Wörter, hat
Autokorrektur und Diktat und lässt sich durch Dritt-Tastaturen ersetzen. Ein
Seed durch die Systemtastatur zu tippen wäre ein Leck mitten im Sicherheitskern.

Der Nebeneffekt ist angenehm: Wenn die Eingabe nur Buchstaben zulässt, die zu einem
BIP39-Wort führen, kann der Nutzer **gar kein** ungültiges Wort erzeugen.

## Was die Wortliste vorgibt — gemessen, nicht geschätzt

| Eigenschaft | Wert |
|---|---|
| Wörter | 2048 |
| Erste vier Buchstaben eindeutig | ja, für alle 2048 |
| Kürzeste Wörter | 3 Zeichen (103 Stück) |
| Anfangsbuchstaben | 25 — **`x` beginnt kein Wort** |
| Kandidaten nach 1 / 2 / 3 / 4 Buchstaben (max.) | 250 / 48 / 13 / 1 |

> [!danger] Die 49 Präfix-Wörter — hier geht eine naive Umsetzung kaputt
> **49 Wörter sind zugleich Präfix eines anderen Wortes:** `act` → `action`, `actor`;
> `add` → `address`, `addict`; ebenso `age`, `air`, `all`, `arm`, `art`, `bar`, `bus`,
> `can` und weitere.
>
> Wer nach drei Buchstaben automatisch übernimmt, sobald der Präfix selbst ein Wort
> ist, trägt bei `act` womöglich `action` ein — oder umgekehrt. Und diese Fälle lassen
> sich durch Weitertippen **nie** auflösen, denn `act` hat keinen vierten Buchstaben.
>
> Daraus folgt verbindlich: **Automatisch übernommen wird nur, wenn genau ein Kandidat
> übrig ist.** In allen anderen Fällen wählt der Nutzer aus der Kandidatenliste. Task 1
> hat dafür einen eigenen Test.

---

### Task 1: `WordEntry` — die Eingabe eines einzelnen Wortes

**Files:**
- Create: `Sources/Pips39Core/WordEntry.swift`
- Create: `Tests/Pips39CoreTests/WordEntryTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/WordEntryTests.swift`:

```swift
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
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `cannot find 'WordEntry' in scope`.

- [ ] **Step 3: `WordEntry.swift` schreiben**

```swift
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
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS. `testFourLettersAlwaysResolveToOneWord` prüft alle 2048 Wörter.

- [ ] **Step 5: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/WordEntry.swift Tests/Pips39CoreTests/WordEntryTests.swift
git commit -m "feat: WordEntry — Eingabe nur entlang der BIP39-Wortliste"
git push
```

---

### Task 2: `TranscriptionCheck` — der Abgleich

**Files:**
- Create: `Sources/Pips39Core/TranscriptionCheck.swift`
- Create: `Tests/Pips39CoreTests/TranscriptionCheckTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/TranscriptionCheckTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class TranscriptionCheckTests: XCTestCase {

    private let words = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        .split(separator: " ").map(String.init)

    func testStartsAtFirstPosition() {
        let check = TranscriptionCheck(expected: words)
        XCTAssertEqual(check.position, 0)
        XCTAssertEqual(check.total, 12)
        XCTAssertFalse(check.isComplete)
        XCTAssertNil(check.mismatch)
    }

    func testCorrectWordAdvances() {
        let check = TranscriptionCheck(expected: words)
        check.submit("abandon")
        XCTAssertEqual(check.position, 1)
        XCTAssertNil(check.mismatch)
    }

    func testWrongWordDoesNotAdvance() {
        let check = TranscriptionCheck(expected: words)
        check.submit("zoo")
        XCTAssertEqual(check.position, 0)
        XCTAssertEqual(check.mismatch, "zoo")
    }

    func testMismatchIsClearedOnNextAttempt() {
        let check = TranscriptionCheck(expected: words)
        check.submit("zoo")
        check.submit("abandon")
        XCTAssertNil(check.mismatch)
        XCTAssertEqual(check.position, 1)
    }

    func testMismatchAtLaterPositionReportsThatPosition() {
        let check = TranscriptionCheck(expected: words)
        for _ in 0..<5 { check.submit("abandon") }
        check.submit("zoo")
        XCTAssertEqual(check.position, 5, "Die Position bleibt stehen, wo es klemmt")
        XCTAssertEqual(check.mismatch, "zoo")
    }

    func testCompletesAfterAllWords() {
        let check = TranscriptionCheck(expected: words)
        for word in words { check.submit(word) }
        XCTAssertTrue(check.isComplete)
        XCTAssertEqual(check.position, 12)
    }

    func testSubmitAfterCompletionIsIgnored() {
        let check = TranscriptionCheck(expected: words)
        for word in words { check.submit(word) }
        check.submit("zoo")
        XCTAssertTrue(check.isComplete)
        XCTAssertNil(check.mismatch)
    }

    func testUndoStepsBackOnePosition() {
        let check = TranscriptionCheck(expected: words)
        check.submit("abandon")
        check.submit("abandon")
        check.undo()
        XCTAssertEqual(check.position, 1)
    }

    func testUndoAtStartDoesNothing() {
        let check = TranscriptionCheck(expected: words)
        check.undo()
        XCTAssertEqual(check.position, 0)
    }

    func testUndoClearsMismatch() {
        let check = TranscriptionCheck(expected: words)
        check.submit("abandon")
        check.submit("zoo")
        check.undo()
        XCTAssertNil(check.mismatch)
        XCTAssertEqual(check.position, 0)
    }

    func testResetStartsOver() {
        let check = TranscriptionCheck(expected: words)
        check.submit("abandon")
        check.submit("zoo")
        check.reset()
        XCTAssertEqual(check.position, 0)
        XCTAssertNil(check.mismatch)
        XCTAssertFalse(check.isComplete)
    }

    /// Die App verrät das richtige Wort nicht — sie sagt nur, dass es abweicht.
    /// Wer nachsehen will, geht zur Wortliste zurück.
    func testCheckExposesNoExpectedWord() {
        let check = TranscriptionCheck(expected: words)
        check.submit("zoo")
        XCTAssertEqual(check.mismatch, "zoo", "Nur das Getippte, nie das Erwartete")
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `cannot find 'TranscriptionCheck' in scope`.

- [ ] **Step 3: `TranscriptionCheck.swift` schreiben**

```swift
import Foundation
import Combine

/// Prüft, ob der Nutzer die Wörter richtig abgeschrieben hat.
///
/// Geht Position für Position vor und bleibt stehen, wo es klemmt — so weiß der
/// Nutzer genau, welche Zeile auf seinem Zettel falsch ist. Nichts wird gespeichert,
/// der Vergleich passiert im Speicher.
///
/// Die Prüfung nennt **nie** das erwartete Wort, nur das abweichende Getippte. Wer
/// nachsehen will, geht bewusst zur Wortanzeige zurück.
public final class TranscriptionCheck: ObservableObject {

    private let expected: [String]

    /// Wie viele Positionen bereits stimmen.
    @Published public private(set) var position: Int = 0

    /// Das zuletzt getippte Wort, wenn es nicht passte — sonst `nil`.
    @Published public private(set) var mismatch: String?

    public init(expected: [String]) {
        self.expected = expected
    }

    public var total: Int { expected.count }
    public var isComplete: Bool { position == expected.count }

    /// Nimmt ein Wort für die aktuelle Position entgegen.
    public func submit(_ word: String) {
        guard !isComplete else { return }
        if word == expected[position] {
            mismatch = nil
            position += 1
        } else {
            mismatch = word
        }
    }

    /// Geht eine Position zurück, etwa weil der Nutzer sich vertan hat.
    public func undo() {
        mismatch = nil
        if position > 0 {
            position -= 1
        }
    }

    public func reset() {
        position = 0
        mismatch = nil
    }
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/TranscriptionCheck.swift Tests/Pips39CoreTests/TranscriptionCheckTests.swift
git commit -m "feat: TranscriptionCheck — Abgleich Position für Position"
git push
```

---

### Task 3: Die Buchstabentastatur

**Files:**
- Create: `Pips39/Pips39/WordKeyboardView.swift`

Neue Dateien in `Pips39/Pips39/` werden durch die synchronisierten Ordner automatisch
mitgebaut — `project.pbxproj` bleibt unangetastet.

- [ ] **Step 1: Die Ansicht schreiben**

```swift
import SwiftUI
import Pips39Core

/// Eine Tastatur, die nur Buchstaben anbietet, die zu einem BIP39-Wort führen.
///
/// Ersetzt die iOS-Systemtastatur, weil die getippte Wörter lernt, Autokorrektur und
/// Diktat mitbringt und durch Dritt-Tastaturen austauschbar ist (Spec 2.3).
struct WordKeyboardView: View {

    let allowed: Set<Character>
    let canDelete: Bool
    let onLetter: (Character) -> Void
    let onDelete: () -> Void

    /// `x` beginnt kein BIP39-Wort und taucht deshalb gar nicht erst auf.
    private let rows: [[Character]] = [
        Array("qwertyuiop"),
        Array("asdfghjkl"),
        Array("zcvbnm")
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 5) {
                    ForEach(rows[index], id: \.self) { letter in
                        key(letter)
                    }
                    if index == rows.count - 1 {
                        deleteKey
                    }
                }
            }
        }
    }

    private func key(_ letter: Character) -> some View {
        let enabled = allowed.contains(letter)
        return Button {
            onLetter(letter)
        } label: {
            Text(String(letter).uppercased())
                .font(.title3.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.secondary.opacity(enabled ? 0.18 : 0.05))
                .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var deleteKey: some View {
        Button(action: onDelete) {
            Image(systemName: "delete.left")
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.secondary.opacity(canDelete ? 0.18 : 0.05))
                .foregroundStyle(canDelete ? Color.primary : Color.secondary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(!canDelete)
    }
}

#Preview {
    WordKeyboardView(allowed: Set("abcdefg"), canDelete: true, onLetter: { _ in }, onDelete: { })
        .padding()
}
```

- [ ] **Step 2: Prüfen**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -4
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Pips39/Pips39/WordKeyboardView.swift
git commit -m "feat: eigene Buchstabentastatur statt der Systemtastatur"
git push
```

---

### Task 4: Die Prüfansicht

**Files:**
- Create: `Pips39/Pips39/TranscriptionView.swift`

- [ ] **Step 1: Die Ansicht schreiben**

```swift
import SwiftUI
import Pips39Core

/// Der Nutzer tippt seine notierten Wörter zurück, die App bestätigt Position
/// für Position.
struct TranscriptionView: View {

    @ObservedObject var check: TranscriptionCheck
    let onFinished: () -> Void
    let onShowWordsAgain: () -> Void

    @State private var entry = WordEntry()

    var body: some View {
        VStack(spacing: 16) {
            header

            if check.isComplete {
                success
            } else {
                candidates
                Spacer(minLength: 0)
                WordKeyboardView(
                    allowed: entry.allowedNextLetters,
                    canDelete: !entry.isEmpty,
                    onLetter: { entry.append($0) },
                    onDelete: { entry.deleteLast() }
                )
            }
        }
        .padding()
        .screenProtected()
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(check.isComplete ? "All 24 match"
                                  : "Word \(check.position + 1) of \(check.total)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()

            Text(entry.prefix.uppercased())
                .font(.system(.title, design: .monospaced))
                .frame(minHeight: 34)

            if let typed = check.mismatch {
                VStack(spacing: 6) {
                    Text("\(typed) does not match position \(check.position + 1). Check your paper.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    Button("Show the words again", action: onShowWordsAgain)
                        .font(.footnote)
                }
            }
        }
    }

    private var candidates: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(entry.candidates, id: \.self) { word in
                    Button {
                        check.submit(word)
                        entry.reset()
                    } label: {
                        Text(word)
                            .font(.body.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: 44)
    }

    private var success: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Your paper matches all 24 words.")
                .multilineTextAlignment(.center)
            Button("Done") { onFinished() }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}

private func previewCheck() -> TranscriptionCheck {
    TranscriptionCheck(expected: Array(repeating: "abandon", count: 23) + ["art"])
}

#Preview {
    TranscriptionView(check: previewCheck(), onFinished: { }, onShowWordsAgain: { })
}
```

> [!note] Warum die Kandidatenliste immer sichtbar ist
> Auch wenn nur ein Kandidat übrig ist, wird er nicht automatisch übernommen. Grund
> sind die 49 Präfix-Wörter aus Task 1: Bei `act` bleiben `act`, `action`, `actor`
> stehen, und keine Automatik kann raten, welches gemeint war. Ein einheitliches
> „immer antippen" ist ehrlicher als eine Regel, die manchmal greift und manchmal
> nicht.

- [ ] **Step 2: Prüfen**

Build wie in Task 3.
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Pips39/Pips39/TranscriptionView.swift
git commit -m "feat: Prüfansicht für die Abschreibkontrolle"
git push
```

---

### Task 5: In den Ablauf einhängen

**Files:**
- Modify: `Pips39/Pips39/WordsView.swift`
- Modify: `Pips39/Pips39/ContentView.swift`

- [ ] **Step 1: `WordsView` um einen zweiten Knopf ergänzen**

Den bestehenden „Discard and start over"-Knopf ersetzen durch:

```swift
                VStack(spacing: 10) {
                    Button {
                        onCheck()
                    } label: {
                        Text("I wrote them down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        onDiscard()
                    } label: {
                        Text("Discard and start over")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top)
```

Das `session.discard()` im Knopf **entfällt** — `ContentView.startOver()` erledigt das
jetzt für beide Wege (Verwerfen und Fertig nach der Prüfung). Zweimal verwerfen wäre
harmlos, aber zwei Stellen mit derselben Zuständigkeit sind eine Einladung, später
eine davon zu vergessen.

Und die Eigenschaft dazu, direkt unter `let onDiscard: () -> Void`:

```swift
    let onCheck: () -> Void
```

Die Vorschau am Dateiende entsprechend anpassen:

```swift
#Preview {
    WordsView(session: previewSession(), onDiscard: { }, onCheck: { })
}
```

- [ ] **Step 2: `ContentView.swift` ersetzen**

```swift
import SwiftUI
import Pips39Core

/// Der Ablauf: Verfahren wählen → würfeln → Wörter → abschreiben prüfen → verwerfen.
struct ContentView: View {

    private enum Step {
        case rolling
        case words
        case checking(TranscriptionCheck)
    }

    @State private var session: DiceSession?
    @State private var step: Step = .rolling

    var body: some View {
        if let session {
            switch step {
            case .rolling:
                RollingView(session: session) {
                    step = .words
                }
            case .words:
                WordsView(session: session) {
                    startOver()
                } onCheck: {
                    step = .checking(TranscriptionCheck(expected: session.words))
                }
            case let .checking(check):
                TranscriptionView(check: check) {
                    startOver()
                } onShowWordsAgain: {
                    step = .words
                }
            }
        } else {
            MethodChoiceView { method in
                session = DiceSession(method: method)
                step = .rolling
            }
        }
    }

    private func startOver() {
        session?.discard()
        session = nil
        step = .rolling
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 3: Prüfen**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -4
cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **` und alle Paket-Tests grün.

- [ ] **Step 4: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Pips39/Pips39/WordsView.swift Pips39/Pips39/ContentView.swift
git commit -m "feat: Abschreibkontrolle in den Ablauf eingehängt"
git push
```

---

## Abschluss der Phase

- [ ] **Sichtprüfung im Simulator** — macht der Auftraggeber. Würfeln bis zu den
      Wörtern, „I wrote them down", ein paar Wörter richtig eintippen, dann absichtlich
      ein falsches wählen und prüfen, dass die Position stehen bleibt und die Meldung
      erscheint.

- [ ] **Spec nachziehen:** Bausteintabelle um `WordEntry`, `TranscriptionCheck`,
      `WordKeyboardView` und `TranscriptionView` ergänzen; `MnemonicKeyboard` gilt
      damit als erledigt.

## Was danach kommt (nicht Teil dieses Plans)

- **Phase 5:** `EnvironmentProbe` (Netzstatus, nie ein grünes „sicher"),
  Nachrechnen-Bereich mit Wurffolge und Hex-Entropie, Erklärseite mit der
  Geräte-Checkliste
- **Später:** Lokalisierung, 12-Wort-Option, Bias-Warnung, App-Store-Vorbereitung
