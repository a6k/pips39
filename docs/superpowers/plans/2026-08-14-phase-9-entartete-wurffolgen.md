# Pips39 — Phase 9: Entartete Wurffolgen erkennen — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wer die Würfe erfindet statt zu würfeln, bekommt es gesagt — ohne dass die App jemals bei einer echten Wurffolge Alarm schlägt.

**Vorhanden:** 170 Tests grün, acht Phasen umgesetzt, Repo öffentlich.

---

## Warum das lange offen stand, und was die Frage auflöst

Die gesamte Sicherheit hängt an den Würfeln. Die App sieht nur Zahlen und kann nicht
unterscheiden, ob wirklich gewürfelt wurde. Wer bei Wurf 60 die Geduld verliert und den
Rest durchtippt, bekommt einen vorhersagbaren Seed — und bisher sagt die App kein Wort.
Das ist dieselbe Sorte Versagen wie das falsch abgeschriebene Wort: nicht Bosheit,
sondern Nachlässigkeit im langweiligen Teil.

Der Einwand, der die Sache blockiert hat, betraf aber nur **eine** von zwei möglichen
Prüfungen:

| | Frage | Fehlalarme |
|---|---|---|
| **Statistischer Test** | „Sieht das zufällig aus?" | **Mathematisch garantiert.** Chi-Quadrat bei 1 % Schwelle schlägt bei jedem hundertsten *korrekten* Durchlauf an. |
| **Entartungsprüfung** | „Ist das überhaupt eine Wurffolge?" | Praktisch keine — die erkannten Muster haben bei echtem Würfeln Wahrscheinlichkeiten um 10⁻³⁵. |

> [!important] Nur die Entartungsprüfung wird gebaut
> Ein statistischer Test käme in dieser App nicht in Frage: Eine Warnung, die bei
> richtigem Verhalten anschlägt, erzieht dazu, Warnungen wegzuklicken. Aus genau dem
> Grund gibt es hier auch keinen grünen „sicher"-Zustand und keine Rückfrage auf
> leerem Puffer.

### Die Wahrscheinlichkeiten, nachgerechnet

Bei 50 Würfen (der kürzeste Fall, 12 Wörter mit Verfahren B):

| Muster | Wahrscheinlichkeit bei echten Würfeln |
|---|---|
| Alle Würfe gleich | 6⁻⁴⁹ ≈ 10⁻³⁸ |
| Folge ist Wiederholung eines Blocks der Länge ≤ 6 | ≈ 6⁻⁴⁴ ≈ 10⁻³⁵ |
| Höchstens zwei verschiedene Augenzahlen | 15 · (1/3)⁴⁹ ≈ 10⁻²³ |

Alle drei sind so klein, dass sie nie eintreten. Das ist der Unterschied zu einem
Wahrscheinlichkeitsurteil: Diese Prüfung stellt fest, sie schätzt nicht.

**Was sie nicht fängt:** geladene Würfel, und Folgen, die sich jemand im Kopf ausdenkt.
Menschen vermeiden dabei Wiederholungen, aber das zu erkennen bräuchte wieder Statistik.
Diese Lücke bleibt bewusst offen; der richtige Ort dafür ist die Erklärseite.

---

### Task 1: `RollPattern` — die Erkennung

**Files:**
- Create: `Sources/Pips39Core/RollPattern.swift`
- Create: `Tests/Pips39CoreTests/RollPatternTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

```swift
import XCTest
@testable import Pips39Core

final class RollPatternTests: XCTestCase {

    private let en = Locale(identifier: "en")

    private func rolls(_ text: String) -> [UInt8] {
        text.compactMap { $0.wholeNumberValue.map(UInt8.init) }
    }

    // MARK: Erkannte Entartungen

    func testAllRollsIdentical() {
        XCTAssertEqual(RollPattern.finding(for: rolls(String(repeating: "4", count: 50))),
                       .singleFace)
    }

    func testRepeatingBlockOfSix() {
        let sequence = String(String(repeating: "123456", count: 20).prefix(96))
        XCTAssertEqual(RollPattern.finding(for: rolls(sequence)), .repeatingBlock(6))
    }

    func testRepeatingBlockOfTwo() {
        XCTAssertEqual(RollPattern.finding(for: rolls(String(repeating: "13", count: 30))),
                       .repeatingBlock(2))
    }

    func testOnlyTwoDistinctFaces() {
        // Zwei Augenzahlen, aber nicht periodisch — soll trotzdem auffallen.
        let sequence = "52522252222552225222252222552252225222255555552222"
        XCTAssertEqual(rolls(sequence).count, 50)
        XCTAssertEqual(RollPattern.finding(for: rolls(sequence)), .twoFacesOnly)
    }

    /// Die spezifischste Feststellung gewinnt: Eine Folge aus lauter Vieren ist
    /// auch periodisch und hat auch nur zwei Augenzahlen.
    func testMostSpecificFindingWins() {
        XCTAssertEqual(RollPattern.finding(for: rolls(String(repeating: "2", count: 99))),
                       .singleFace)
    }

    // MARK: Der entscheidende Test — keine Fehlalarme

    /// Zehntausend echte Zufallsfolgen dürfen **keine** Meldung erzeugen. Das ist die
    /// Behauptung, auf der die ganze Entscheidung ruht, also wird sie geprüft und
    /// nicht geglaubt. Der Generator ist bewusst deterministisch, damit ein
    /// Fehlschlag reproduzierbar ist.
    func testRandomSequencesAreNeverFlagged() {
        var rng = SeededGenerator(seed: 20260814)
        for length in [50, 99, 128, 154] {
            for _ in 0..<2500 {
                let sequence = (0..<length).map { _ in UInt8.random(in: 1...6, using: &rng) }
                XCTAssertNil(RollPattern.finding(for: sequence),
                             "Fehlalarm bei Länge \(length): \(sequence.map(String.init).joined())")
            }
        }
    }

    // MARK: Kurze Folgen

    /// Unter 20 Würfen sind die Wahrscheinlichkeiten nicht mehr vernachlässigbar.
    /// Die Prüfung schweigt dann lieber.
    func testShortSequencesAreNotJudged() {
        XCTAssertNil(RollPattern.finding(for: rolls("111111")))
        XCTAssertNil(RollPattern.finding(for: rolls("121212121212121212")))
    }

    func testEmptyInput() {
        XCTAssertNil(RollPattern.finding(for: []))
    }

    // MARK: Texte

    func testEveryFindingHasANotice() {
        let findings: [RollPattern.Finding] = [.singleFace, .repeatingBlock(3), .twoFacesOnly]
        for finding in findings {
            XCTAssertFalse(RollPattern.notice(for: finding, locale: en).isEmpty)
        }
    }

    /// Feststellung, kein Alarm — wie überall in dieser App.
    func testNoticesAreStatementsNotAlarms() {
        let findings: [RollPattern.Finding] = [.singleFace, .repeatingBlock(3), .twoFacesOnly]
        for finding in findings {
            let text = RollPattern.notice(for: finding, locale: en)
            XCTAssertFalse(text.contains("!"))
            XCTAssertFalse(text.lowercased().contains("error"))
            XCTAssertFalse(text.lowercased().contains("invalid"))
        }
    }
}

/// Deterministischer Generator, damit ein Fehlschlag nachstellbar ist.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    /// splitmix64 — der Zaehler allein haette schwache untere Bits, und genau die
    /// benutzt `random(in: 1...6)`.
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "$REPO" && swift test`
Expected: FAIL, `cannot find 'RollPattern' in scope`.

- [ ] **Step 3: `RollPattern.swift` schreiben**

```swift
import Foundation

/// Erkennt Wurffolgen, die keine sein können.
///
/// **Bewusst keine Statistik.** Ein Test auf „sieht zufällig aus" hätte
/// mathematisch garantierte Fehlalarme, und eine Warnung, die bei richtigem
/// Verhalten anschlägt, erzieht dazu, Warnungen wegzuklicken. Hier werden nur
/// Muster festgestellt, deren Wahrscheinlichkeit bei echtem Würfeln bei 10⁻²³ und
/// darunter liegt — die treten nie ein.
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
            let isPeriodic = rolls.indices.allSatisfy { rolls[$0] == rolls[$0 % period] }
            if isPeriodic { return period }
        }
        return nil
    }

    /// Der Text zur Feststellung. Nennt, was zu sehen ist, und was zu tun wäre —
    /// ohne zu behaupten, dass etwas kaputt sei.
    public static func notice(for finding: Finding, locale: Locale = .current) -> String {
        switch finding {
        case .singleFace:
            return Localized.string("pattern.singleFace", locale)
        case .repeatingBlock:
            return Localized.string("pattern.repeating", locale)
        case .twoFacesOnly:
            return Localized.string("pattern.twoFaces", locale)
        }
    }
}
```

- [ ] **Step 4: Die Texte in beide Tabellen eintragen**

`Sources/Pips39Core/Localization/en.lproj/Localizable.strings`:

```
"pattern.singleFace" = "Every roll in this sequence is the same value. If you did not actually roll dice, discard and start over.";
"pattern.repeating" = "This sequence repeats a short pattern. If you did not actually roll dice, discard and start over.";
"pattern.twoFaces" = "This sequence uses only two of the six values. If you did not actually roll dice, discard and start over.";
```

`de.lproj`:

```
"pattern.singleFace" = "Alle Würfe dieser Folge zeigen dieselbe Zahl. Falls nicht wirklich gewürfelt wurde: verwerfen und neu beginnen.";
"pattern.repeating" = "Diese Folge wiederholt ein kurzes Muster. Falls nicht wirklich gewürfelt wurde: verwerfen und neu beginnen.";
"pattern.twoFaces" = "In dieser Folge kommen nur zwei der sechs Zahlen vor. Falls nicht wirklich gewürfelt wurde: verwerfen und neu beginnen.";
```

- [ ] **Step 5: Tests laufen lassen**

Run: `cd "$REPO" && swift test`
Expected: PASS. `testRandomSequencesAreNeverFlagged` prüft 10 000 Zufallsfolgen.

- [ ] **Step 6: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core Tests/Pips39CoreTests
git commit -m "feat: RollPattern erkennt entartete Wurffolgen ohne Fehlalarme"
git push
```

---

### Task 2: Die Feststellung durch `DiceSession` reichen

**Files:**
- Modify: `Sources/Pips39Core/DiceSession.swift`
- Create: `Tests/Pips39CoreTests/DiceSessionPatternTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

```swift
import XCTest
@testable import Pips39Core

final class DiceSessionPatternTests: XCTestCase {

    private func session(face: UInt8, times: Int) -> DiceSession {
        let session = DiceSession(method: .sha256, length: .twelve)
        for _ in 0..<times { session.roll(face) }
        return session
    }

    func testNoFindingWhileIncomplete() {
        XCTAssertNil(session(face: 1, times: 30).rollPattern)
    }

    func testFindingAppearsWhenComplete() {
        XCTAssertEqual(session(face: 1, times: 50).rollPattern, .singleFace)
    }

    func testMixedSequenceHasNoFinding() {
        let session = DiceSession(method: .sha256, length: .twelve)
        var rng = SeededGenerator(seed: 99)
        for _ in 0..<50 { session.roll(UInt8.random(in: 1...6, using: &rng)) }
        XCTAssertNil(session.rollPattern)
    }

    func testDiscardClearsTheFinding() {
        let session = session(face: 1, times: 50)
        session.discard()
        XCTAssertNil(session.rollPattern)
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Expected: FAIL, `value of type 'DiceSession' has no member 'rollPattern'`.

- [ ] **Step 3: `DiceSession.swift` erweitern**

Vor der schließenden Klammer einfügen:

```swift
    /// Auffälligkeit an der Wurffolge, sobald genug gewürfelt wurde.
    ///
    /// Erst bei vollständiger Folge — während des Würfelns wären drei gleiche Würfe
    /// hintereinander völlig normal, und eine Meldung dazu wäre der Fehlalarm, den
    /// diese Prüfung gerade vermeidet.
    public var rollPattern: RollPattern.Finding? {
        guard isComplete else { return nil }
        return RollPattern.finding(for: buffer.rolls)
    }
```

- [ ] **Step 4: Tests laufen lassen**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core/DiceSession.swift Tests/Pips39CoreTests/DiceSessionPatternTests.swift
git commit -m "feat: DiceSession meldet auffällige Wurffolgen bei Abschluss"
git push
```

---

### Task 3: Die Feststellung in der Wortanzeige

**Files:**
- Modify: `Pips39/Pips39/WordsView.swift`

- [ ] **Step 1: Den Hinweis oben einfügen**

Direkt nach dem Kopfbereich, **vor** dem Wortraster:

```swift
                if let finding = session.rollPattern {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(RollPattern.notice(for: finding))
                            .font(.footnote.weight(.medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(.orange)
                    .padding(12)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
```

> [!note] Warum oben und warum orange
> Oben, weil der Nutzer es lesen soll, **bevor** er etwas abschreibt. Orange und nicht
> rot, weil nichts kaputt ist — die Wörter sind gültig, und wer tatsächlich so
> gewürfelt hat, darf sie behalten. Die App stellt fest und blockiert nicht.

- [ ] **Step 2: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/WordsView.swift
git commit -m "feat: Hinweis auf auffällige Wurffolgen über den Wörtern"
git push
```

---

### Task 4: Ansehen

- [ ] **Step 1: Den Fall herstellen**

Mit 12 Wörtern und Verfahren B fünfzigmal dieselbe Zahl tippen, dann „Wörter zeigen".
Über den Wörtern muss die orange Feststellung stehen.

- [ ] **Step 2: Die Gegenprobe**

Denselben Weg mit gemischten Würfen — dort darf **nichts** erscheinen. Das ist der
wichtigere der beiden Durchgänge.

## Abschluss der Phase

- [ ] **Spec nachziehen:** Den offenen Punkt „Bias-Warnung" in Abschnitt 11 abhaken,
      mit der Unterscheidung zwischen statistischem Test (verworfen) und
      Entartungsprüfung (umgesetzt).

## Was danach kommt (nicht Teil dieses Plans)

- App-Store-Einreichung: Beschreibung in beiden Sprachen, Screenshots, der Satz zu
  Quelltext gegen Binary
