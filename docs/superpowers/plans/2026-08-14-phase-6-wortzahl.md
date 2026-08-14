# Pips39 — Phase 6: 12 oder 24 Wörter — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Der Nutzer wählt über einen segmentierten Schalter über der Verfahrenswahl, ob er 12 oder 24 Wörter würfeln will. Die Wurfzahl-Angaben auf den Methodenkarten ändern sich sofort mit.

**Architecture:** Wie bisher — die Wahl wird ein Typ im Paket (`SeedLength`), alles Rechnende hängt daran, die Ansicht bleibt dumm. Der Schalter ist ein `Picker` mit `.pickerStyle(.segmented)`.

**Spec:** `das Spec (liegt im privaten Vault, nicht im Repo)`, Abschnitt 11 („12-Wort-Option")

**Vorhanden:** 131 Tests grün, alle fünf Phasen umgesetzt.

---

## Zwei Dinge, die man beim Rechnen leicht übersieht

> [!danger] Bei 12 Wörtern zählt nur die **halbe** Hex-Entropie — und die Anleitung muss das sagen
> Verfahren B hasht die Wurffolge zu **32 Byte**. Für 12 Wörter werden davon nur die
> **ersten 16 Byte** gebraucht.
>
> Das schlägt direkt auf die Nachrechen-Anleitung durch: `shasum` liefert weiterhin
> 64 Hex-Zeichen, aber in Colemans Entropy-Feld gehören dann nur die **ersten 32**.
> Wer alle 64 einfügt, bekommt 24 Wörter und damit eine Abweichung — ein Fehlalarm
> bei völlig korrektem Seed, also genau das, was das Vertrauen zerstört. Task 3 macht
> die Anleitung deshalb abhängig von der Wortzahl.

**Verfahren A braucht keine Sonderbehandlung.** Colemans Kürzung auf das nächstkleinere
Vielfache von 32 erledigt das von selbst: Wer bei ≥ 128 Rohbits aufhört, hat 128 oder
129, und beides kürzt auf 128.

### Die Zahlen, nachgerechnet

| | 24 Wörter (256 bit) | 12 Wörter (128 bit) |
|---|---|---|
| Verfahren B, feste Wurfzahl | 99 | 50 |
| Verfahren A, mittlere Wurfzahl | ~154 | ~77 |

Die 99 sind Konvention, keine Formel: 256 / log2(6) = 99,03, aufgerundet wären es 100.
99 Würfe liefern 255,9 bit, die in einen 256-bit-Hash gehen — der Unterschied ist
belanglos, und 99 ist die Zahl, die auch ColdCard benutzt. Bei 12 Wörtern reichen 50
Würfe mit 129,2 bit bequem.

---

### Task 1: `SeedLength`

**Files:**
- Create: `Sources/Pips39Core/SeedLength.swift`
- Create: `Tests/Pips39CoreTests/SeedLengthTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

```swift
import XCTest
@testable import Pips39Core

final class SeedLengthTests: XCTestCase {

    func testWordCounts() {
        XCTAssertEqual(SeedLength.twelve.wordCount, 12)
        XCTAssertEqual(SeedLength.twentyFour.wordCount, 24)
    }

    func testEntropyBitsFollowBIP39() {
        XCTAssertEqual(SeedLength.twelve.entropyBits, 128)
        XCTAssertEqual(SeedLength.twentyFour.entropyBits, 256)
    }

    func testEntropyBitsAreValidBIP39Sizes() {
        for length in SeedLength.allCases {
            XCTAssertTrue(BIP39.allowedEntropyBits.contains(length.entropyBits))
        }
    }

    func testHashedRollCounts() {
        XCTAssertEqual(SeedLength.twelve.rollsForHashedMethod, 50)
        XCTAssertEqual(SeedLength.twentyFour.rollsForHashedMethod, 99)
    }

    /// Genug Würfelentropie für die Zielgröße: jeder Wurf trägt log2(6) = 2,585 bit.
    func testHashedRollCountsCarryEnoughEntropy() {
        for length in SeedLength.allCases {
            let bits = Double(length.rollsForHashedMethod) * 2.5849625
            XCTAssertGreaterThan(bits, Double(length.entropyBits) - 1,
                                 "Zu wenige Würfe für \(length.wordCount) Wörter")
        }
    }

    func testApproximateColemanRolls() {
        XCTAssertEqual(SeedLength.twelve.approximateColemanRolls, 77)
        XCTAssertEqual(SeedLength.twentyFour.approximateColemanRolls, 154)
    }

    func testTwentyFourIsTheDefault() {
        XCTAssertEqual(SeedLength.standard, .twentyFour)
    }

    func testTitlesNameTheWordCount() {
        XCTAssertTrue(SeedLength.twelve.title.contains("12"))
        XCTAssertTrue(SeedLength.twentyFour.title.contains("24"))
    }

    func testAllCasesAreDistinct() {
        XCTAssertEqual(Set(SeedLength.allCases.map(\.wordCount)).count,
                       SeedLength.allCases.count)
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "$REPO" && swift test`
Expected: FAIL, `cannot find 'SeedLength' in scope`.

- [ ] **Step 3: `SeedLength.swift` schreiben**

```swift
import Foundation

/// Wie viele Wörter der Seed haben soll.
///
/// 128 bit sind nicht brechbar, gegen 12 Wörter spricht sicherheitstechnisch nichts.
/// Der Vorgabewert ist trotzdem 24, weil die Würfel-Community dogmatisch dazu neigt
/// und ein vorausgewähltes 12 als Lässigkeit gelesen würde.
public enum SeedLength: Int, CaseIterable, Identifiable, Equatable {

    case twelve = 12
    case twentyFour = 24

    public static let standard: SeedLength = .twentyFour

    public var id: Int { rawValue }
    public var wordCount: Int { rawValue }

    /// Die Entropiegröße nach BIP39: Wortzahl × 11 Bit, abzüglich der Prüfsumme.
    public var entropyBits: Int { wordCount * 11 * 32 / 33 }

    /// Feste Wurfzahl für Verfahren B.
    ///
    /// Konvention, keine Formel: 256 / log2(6) = 99,03 — aufgerundet wären es 100.
    /// 99 Würfe tragen 255,9 bit in einen 256-bit-Hash, der Unterschied ist belanglos,
    /// und 99 ist die Zahl, die auch ColdCard benutzt.
    public var rollsForHashedMethod: Int {
        switch self {
        case .twelve:     return 50
        case .twentyFour: return 99
        }
    }

    /// Grobe Erwartung für Verfahren A — dort steht die Wurfzahl nicht fest,
    /// jeder Wurf liefert ein oder zwei Bit (im Mittel 1,67).
    public var approximateColemanRolls: Int {
        switch self {
        case .twelve:     return 77
        case .twentyFour: return 154
        }
    }

    /// Beschriftung für den Schalter.
    public var title: String { "\(wordCount) words" }
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "$REPO" && swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core/SeedLength.swift Tests/Pips39CoreTests/SeedLengthTests.swift
git commit -m "feat: SeedLength — 12 oder 24 Wörter als Typ"
git push
```

---

### Task 2: Die Wortzahl durch den Kern reichen

**Files:**
- Modify: `Sources/Pips39Core/HashedEncoding.swift`
- Modify: `Sources/Pips39Core/DiceEntropy.swift`
- Modify: `Sources/Pips39Core/DiceSession.swift`
- Create: `Tests/Pips39CoreTests/SeedLengthWiringTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

```swift
import XCTest
@testable import Pips39Core

final class SeedLengthWiringTests: XCTestCase {

    private func session(_ method: DiceMethod, _ length: SeedLength,
                         face: UInt8, times: Int) -> DiceSession {
        let session = DiceSession(method: method, length: length)
        for _ in 0..<times { session.roll(face) }
        return session
    }

    // MARK: Verfahren B

    func testTwelveWordsCompleteAfterFiftyRolls() {
        let session = session(.sha256, .twelve, face: 1, times: 50)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.progress, .rolls(done: 50, needed: 50))
    }

    func testTwelveWordsRefuseRollFiftyOne() {
        let session = session(.sha256, .twelve, face: 1, times: 60)
        XCTAssertEqual(session.rollCount, 50)
    }

    /// Bei 12 Wörtern zählen nur die ersten 16 Byte des Hashes.
    func testTwelveWordEntropyIsSixteenBytes() {
        let session = session(.sha256, .twelve, face: 1, times: 50)
        XCTAssertEqual(session.entropyHex?.count, 32)
        XCTAssertEqual(session.entropyHex,
                       "3dac51a65ec9fcfc409a1b5f1defe92b")
    }

    /// Erzeugt mit `printf '%s' "111…" | shasum -a 256`, davon die ersten 32 Zeichen.
    func testTwelveWordsProduceExpectedMnemonic() {
        let session = session(.sha256, .twelve, face: 1, times: 50)
        session.reveal()
        XCTAssertEqual(session.words.count, 12)
        XCTAssertEqual(session.words.joined(separator: " "),
                       "diet glad hat rural panther lawsuit act drop gallery urge where fit")
    }

    // MARK: Verfahren A

    func testColemanTwelveWordsCompleteAt128Bits() {
        let session = session(.coleman, .twelve, face: 1, times: 64)
        XCTAssertEqual(session.progress, .bits(done: 128, needed: 128))
        XCTAssertTrue(session.isComplete)
    }

    func testColemanTwelveWordsProduceTwelveValidWords() {
        let session = session(.coleman, .twelve, face: 1, times: 64)
        session.reveal()
        XCTAssertEqual(session.words.count, 12)
        XCTAssertTrue(BIP39.isValid(mnemonic: session.words))
    }

    // MARK: Vorgabe und Beständigkeit

    func testDefaultIsStillTwentyFour() {
        XCTAssertEqual(DiceSession(method: .sha256).length, .twentyFour)
        XCTAssertEqual(DiceEntropy(method: .sha256).length, .twentyFour)
    }

    func testTwentyFourStillBehavesAsBefore() {
        let session = session(.sha256, .twentyFour, face: 1, times: 99)
        session.reveal()
        XCTAssertEqual(session.words.count, 24)
        XCTAssertEqual(session.entropyHex,
                       "fa098eb852b2660348b21bb00ad03a49cc177ea07ebe34f46b40baa85313525e")
    }

    /// Verwerfen darf die Wortzahl nicht verlieren.
    func testDiscardKeepsTheLength() {
        let session = session(.sha256, .twelve, face: 1, times: 50)
        session.discard()
        XCTAssertEqual(session.length, .twelve)
        XCTAssertEqual(session.progress, .rolls(done: 0, needed: 50))
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "$REPO" && swift test`
Expected: FAIL, `extra argument 'length' in call`.

- [ ] **Step 3: `HashedEncoding.swift` erweitern**

Die bestehende Funktion behalten und eine gekürzte Fassung danebenstellen:

```swift
    /// Die ersten `byteCount` Byte des Hashes.
    ///
    /// Für 12 Wörter werden nur 16 der 32 Byte gebraucht. Das schlägt auf die
    /// Nachrechen-Anleitung durch: In Colemans Entropy-Feld gehören dann nur die
    /// ersten 32 Hex-Zeichen, sonst kommen 24 Wörter heraus.
    static func entropy(from rolls: [UInt8], byteCount: Int) -> [UInt8] {
        Array(entropy(from: rolls).prefix(byteCount))
    }
```

- [ ] **Step 4: `DiceEntropy.swift` umstellen**

Die beiden `static let` **löschen** und durch Folgendes ersetzen; `init` bekommt die
Wortzahl mit Vorgabewert, damit alle bestehenden Aufrufe weiter übersetzen:

```swift
    public let method: DiceMethod
    public let length: SeedLength
    public private(set) var rolls: [UInt8] = []

    public init(method: DiceMethod, length: SeedLength = .standard) {
        self.method = method
        self.length = length
    }

    /// Zielgröße der Entropie in Bit.
    public var targetEntropyBits: Int { length.entropyBits }

    /// Feste Wurfzahl für Verfahren B.
    public var rollsForHashedMethod: Int { length.rollsForHashedMethod }
```

In `progress`, `isComplete` und `entropy()` `Self.` durch den Selbstbezug ersetzen:

```swift
    public var progress: DiceProgress {
        switch method {
        case .sha256:
            return .rolls(done: rolls.count, needed: rollsForHashedMethod)
        case .coleman:
            return .bits(done: rawBitCount, needed: targetEntropyBits)
        }
    }

    public var isComplete: Bool {
        switch method {
        case .sha256:
            return rolls.count >= rollsForHashedMethod
        case .coleman:
            return rawBitCount >= targetEntropyBits
        }
    }

    public func entropy() -> SecretBytes? {
        guard isComplete else { return nil }
        switch method {
        case .sha256:
            return SecretBytes(HashedEncoding.entropy(from: rolls,
                                                      byteCount: targetEntropyBits / 8))
        case .coleman:
            return SecretBytes(ColemanEncoding.entropy(from: rolls))
        }
    }
```

- [ ] **Step 5: `DiceSession.swift` umstellen**

```swift
    public let method: DiceMethod
    public let length: SeedLength

    public init(method: DiceMethod, length: SeedLength = .standard) {
        self.method = method
        self.length = length
        self.buffer = DiceEntropy(method: method, length: length)
    }
```

Und in `discard()` die Wortzahl mitgeben:

```swift
    public func discard() {
        words = []
        buffer = DiceEntropy(method: method, length: length)
    }
```

- [ ] **Step 6: Tests laufen lassen**

Run: `cd "$REPO" && swift test`
Expected: PASS, auch alle bisherigen Tests — die Vorgabe `.standard` hält sie am Leben.

- [ ] **Step 7: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core/HashedEncoding.swift Sources/Pips39Core/DiceEntropy.swift Sources/Pips39Core/DiceSession.swift Tests/Pips39CoreTests/SeedLengthWiringTests.swift
git commit -m "feat: Wortzahl durch DiceEntropy und DiceSession gereicht"
git push
```

---

### Task 3: Beschriftungen und Anleitung an der Wortzahl

**Files:**
- Modify: `Sources/Pips39Core/DiceMethod.swift`
- Modify: `Tests/Pips39CoreTests/DiceMethodLabelTests.swift`
- Modify: `Pips39/Pips39/MethodChoiceView.swift` (nur der eine Aufruf)
- Modify: `Pips39/Pips39/IntroView.swift` (nur der eine Aufruf)
- Create: `Tests/Pips39CoreTests/SeedLengthHintTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

```swift
import XCTest
@testable import Pips39Core

final class SeedLengthHintTests: XCTestCase {

    func testHashedHintNamesTheExactRollCount() {
        XCTAssertTrue(DiceMethod.sha256.rollCountHint(for: .twentyFour).contains("99"))
        XCTAssertTrue(DiceMethod.sha256.rollCountHint(for: .twelve).contains("50"))
    }

    /// Verfahren A darf für keine Wortzahl eine feste Zahl versprechen.
    func testColemanHintNeverPromisesAnExactCount() {
        for length in SeedLength.allCases {
            let hint = DiceMethod.coleman.rollCountHint(for: length)
            XCTAssertTrue(hint.lowercased().contains("varies"),
                          "Verfahren A muss die Schwankung nennen: \(hint)")
            XCTAssertFalse(hint.lowercased().contains("exactly"))
        }
    }

    func testColemanHintNamesTheApproximateCount() {
        XCTAssertTrue(DiceMethod.coleman.rollCountHint(for: .twelve).contains("77"))
        XCTAssertTrue(DiceMethod.coleman.rollCountHint(for: .twentyFour).contains("154"))
    }

    func testEveryCombinationHasANonEmptyHint() {
        for method in DiceMethod.allCases {
            for length in SeedLength.allCases {
                XCTAssertFalse(method.rollCountHint(for: length).isEmpty)
            }
        }
    }

    // MARK: Nachrechen-Anleitung

    /// Der Fehlalarm-Fänger: Bei 12 Wörtern gehören nur die ersten 32 Hex-Zeichen
    /// in Colemans Feld. Ohne diesen Hinweis bekommt der Nutzer 24 Wörter und
    /// glaubt, sein Seed sei falsch.
    func testHashedStepsExplainTheHexTruncationForTwelveWords() {
        let joined = DiceMethod.sha256.verificationSteps(for: .twelve).joined(separator: " ")
        XCTAssertTrue(joined.contains("32"), "Hinweis auf die ersten 32 Hex-Zeichen fehlt")
    }

    func testHashedStepsDoNotTruncateForTwentyFourWords() {
        let joined = DiceMethod.sha256.verificationSteps(for: .twentyFour).joined(separator: " ")
        XCTAssertFalse(joined.contains("first 32"))
    }

    func testColemanStepsStillWarnAboutBothPitfalls() {
        for length in SeedLength.allCases {
            let joined = DiceMethod.coleman.verificationSteps(for: length).joined(separator: " ")
            XCTAssertTrue(joined.contains("Dice"))
            XCTAssertTrue(joined.contains("Raw Entropy"))
        }
    }
}
```

- [ ] **Step 2: Bestehenden Test anpassen**

In `Tests/Pips39CoreTests/DiceMethodLabelTests.swift` die beiden Methoden ersetzen, die
`rollCountHint` ohne Argument aufrufen:

```swift
    func testEveryMethodHasANonEmptyLabel() {
        for method in DiceMethod.allCases {
            XCTAssertFalse(method.title.isEmpty, "Titel fehlt für \(method)")
            XCTAssertFalse(method.summary.isEmpty, "Kurzbeschreibung fehlt für \(method)")
            XCTAssertFalse(method.rollCountHint(for: .standard).isEmpty,
                           "Wurfzahl-Hinweis fehlt für \(method)")
        }
    }

    func testOnlyHashedPromisesAFixedRollCount() {
        XCTAssertTrue(DiceMethod.sha256.rollCountHint(for: .twentyFour).contains("99"))
        XCTAssertFalse(DiceMethod.coleman.rollCountHint(for: .twentyFour).contains("99"))
    }
```

Und in `Tests/Pips39CoreTests/VerificationDataTests.swift` die drei Tests, die
`verificationSteps` ohne Argument benutzen, auf `verificationSteps(for: .standard)`
umstellen — die Erwartungen bleiben gleich.

- [ ] **Step 3: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "$REPO" && swift test`
Expected: FAIL, `cannot call value of non-function type 'String'`.

- [ ] **Step 4: `DiceMethod.swift` umstellen**

`rollCountHint` und `verificationSteps` von Eigenschaften zu Funktionen machen:

```swift
    /// Was den Nutzer an Würfelarbeit erwartet. Verfahren A darf keine feste Zahl
    /// nennen — dort liefert jeder Wurf ein oder zwei Bit.
    public func rollCountHint(for length: SeedLength) -> String {
        switch self {
        case .sha256:
            return "Exactly \(length.rollsForHashedMethod) rolls."
        case .coleman:
            return "Around \(length.approximateColemanRolls) rolls, but the exact number varies."
        }
    }

    /// Die Schritte, mit denen der Nutzer das Ergebnis unabhängig nachrechnet.
    public func verificationSteps(for length: SeedLength) -> [String] {
        switch self {
        case .sha256:
            var steps = [
                "Run: printf '%s' \"<your rolls>\" | shasum -a 256"
            ]
            if length == .twelve {
                steps.append("Take only the first 32 hex characters — 12 words use 128 of the 256 bits.")
            }
            steps.append("Open iancoleman.io/bip39 and paste the hex into the Entropy field.")
            steps.append("Set Entropy type to Hex, then compare the words.")
            return steps
        case .coleman:
            return [
                "Open iancoleman.io/bip39.",
                "Select the Dice entropy type first — otherwise a sequence of only 1s is read as binary.",
                "Leave Mnemonic Length on Use Raw Entropy — a fixed word count hashes instead and truncates the other way.",
                "Enter exactly the rolls shown here, no more, and compare the words."
            ]
        }
    }
```

- [ ] **Step 5: Die beiden Aufrufstellen in der App nachziehen**

In `Pips39/Pips39/MethodChoiceView.swift`:

```swift
                        Text(method.rollCountHint(for: length))
```

(`length` kommt in Task 4 dazu — bis dahin `for: .standard` schreiben, damit es
übersetzt, und in Task 4 ersetzen.)

In `Pips39/Pips39/IntroView.swift`, im `verification`-Block:

```swift
                        ForEach(Array(method.verificationSteps(for: .standard).enumerated()), id: \.offset) { index, step in
```

Auf der Erklärseite steht die Wortzahl noch nicht fest — `.standard` ist dort richtig,
und der 32-Zeichen-Hinweis fehlt dann bewusst. Wer mit 12 Wörtern nachrechnet, findet
ihn im Nachrechnen-Bereich am Ergebnis, wo die tatsächliche Wortzahl bekannt ist.

- [ ] **Step 6: Tests und Build**

```bash
cd "$REPO" && swift test 2>&1 | tail -3
cd Pips39 && xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -3
```
Expected: alle Tests grün, `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core/DiceMethod.swift Tests/Pips39CoreTests/ Pips39/Pips39/MethodChoiceView.swift Pips39/Pips39/IntroView.swift
git commit -m "feat: Wurfzahl-Hinweise und Nachrechen-Anleitung folgen der Wortzahl"
git push
```

---

### Task 4: Der Schalter über der Verfahrenswahl

**Files:**
- Modify: `Pips39/Pips39/MethodChoiceView.swift`
- Modify: `Pips39/Pips39/ContentView.swift`
- Modify: `Pips39/Pips39/VerifyView.swift` (Anleitung mit echter Wortzahl)

- [ ] **Step 1: `MethodChoiceView` erweitern**

Eigenschaft und Zustand ersetzen:

```swift
    let onChoose: (DiceMethod, SeedLength) -> Void

    @State private var length: SeedLength = .standard
```

Zwischen dem Kopfbereich und `Text("Choose a method")` einfügen:

```swift
            VStack(alignment: .leading, spacing: 8) {
                Text("Seed length")
                    .font(.headline)
                Picker("Seed length", selection: $length) {
                    ForEach(SeedLength.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
```

Im Karten-`Button` den Aufruf und den Hinweis anpassen:

```swift
                Button {
                    onChoose(method, length)
                } label: {
```

```swift
                        Text(method.rollCountHint(for: length))
```

Und die Vorschau:

```swift
#Preview {
    MethodChoiceView { _, _ in }
}
```

- [ ] **Step 2: `ContentView` nachziehen**

```swift
            MethodChoiceView { method, length in
                session = DiceSession(method: method, length: length)
                step = .rolling
            }
```

- [ ] **Step 3: `VerifyView` auf die echte Wortzahl umstellen**

Dort ist die Wortzahl bekannt, also gehört der 32-Zeichen-Hinweis genau hierhin.
`VerifyView` zeigt zwar keine Schritte mehr, aber die Wortzahl gehört zu den Feldern:

```swift
                field(title: "Method", value: session.method.title, monospaced: false)
                field(title: "Seed length", value: session.length.title, monospaced: false)
                field(title: "Dice rolls", value: session.rollSequence, monospaced: true)
                field(title: "Entropy (hex)", value: session.entropyHex ?? "—", monospaced: true)
```

- [ ] **Step 4: Bauen und Tests**

```bash
cd "$REPO/Pips39" && xcodebuild -project Pips39.xcodeproj \
  -scheme Pips39 -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -3
cd "$REPO" && swift test 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`, alle Tests grün.

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/MethodChoiceView.swift Pips39/Pips39/ContentView.swift Pips39/Pips39/VerifyView.swift
git commit -m "feat: segmentierter Schalter für 12 oder 24 Wörter"
git push
```

---

## Abschluss der Phase

- [ ] **Sichtprüfung im Simulator.** Schalter auf 12 stellen und prüfen, dass auf der
      SHA-256-Karte sofort „Exactly 50 rolls." steht und auf der Coleman-Karte
      „Around 77 rolls". Dann 50 Würfe eingeben — die Wortanzeige muss 12 Wörter
      zeigen. Mit lauter Einsen müssen es
      `diet glad hat rural panther lawsuit act drop gallery urge where fit` sein,
      und die Hex im Nachrechnen-Bereich `3dac51a65ec9fcfc409a1b5f1defe92b`.

- [ ] **Gegenprobe von Hand:**

```bash
printf '%s' "$(python3 -c "print('1'*50)")" | shasum -a 256 | cut -c1-32
```
Expected: `3dac51a65ec9fcfc409a1b5f1defe92b`

- [ ] **Spec nachziehen:** Den offenen Punkt „12-Wort-Option" in Abschnitt 11 abhaken,
      `SeedLength` in die Bausteintabelle, und in 2.4 ergänzen, dass die Wurfzahl auch
      von der Wortzahl abhängt.

## Was danach kommt (nicht Teil dieses Plans)

- Lokalisierung
- Bias-Warnung (bewusst offen im Spec)
- Leerraum in der Prüfansicht
- App-Store-Vorbereitung
