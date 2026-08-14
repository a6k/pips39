# Pips39 — Phase 10: Nachschlagetabelle — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wer Würfel und eine Hardware-Wallet hat, aber keinen Drucker, bekommt die
BitBox-Diceware-Tabelle auf dem Schirm — und die App erfährt den Seed dabei nie.

**Vorhanden:** 197 Tests grün, neun Phasen umgesetzt, Repo öffentlich.

---

## Was gebaut wird, und warum es kein drittes Verfahren ist

Die BitBox02-Diceware-Anleitung erzeugt einen Seed **ohne jede Rechnung**: fünf Würfel
und eine Münze wählen pro Wort einen Eintrag aus einer gedruckten Tabelle. Das Papier
weiß nichts, die App wäre nicht beteiligt. Der einzige Haken ist der Ausdruck.

Dieser Modus ersetzt den Ausdruck — **nicht** die Würfel und nicht die Wallet.

### Die Tabelle ist der BIP39-Index in Basis 4·4·4·4·4·2

```
Index = (W1−1)·512 + (W2−1)·128 + (W3−1)·32 + (W4−1)·8 + (W5−1)·2 + Münze
        └────────── eingegeben ──────────┘   └──────── abgelesen ────────┘
```

Würfel zeigen nur 1 bis 4; eine 5 oder 6 wird neu geworfen (Rejection Sampling, exakt
2 Bit pro Würfel ohne Modulo-Bias). Münze: Kopf = 0, Zahl = 1. Macht 11 Bit = 2048.

Gegen die offizielle Wortliste geprüft, alle acht Seitengrenzen und die ersten beiden
Zeilen stimmen: Index 0 = `abandon`, 511 = `divide`, 512 = `divorce`, 1023 = `lend`,
1024 = `length`, 1535 = `say`, 1536 = `scale`, 2047 = `zoo`. Task 1 friert das als
Test ein.

> [!important] Das ist die ganze Vertrauensgeschichte dieses Modus
> Kein SHA-256, keine Bit-Tabelle, keine Kürzungsregel. Wer misstrauisch ist, prüft die
> Formel gegen eine beliebige BIP39-Wortliste und ist fertig. Genau deshalb darf hier
> **nichts** gerechnet werden, was über die Formel hinausgeht.

### Die Bit-Bilanz — der Grund für 24 Wörter

Die App sieht 6 von 11 Bit pro Wort. Die anderen 5 liest der Nutzer ab und tippt sie
nie ein. Was einer kompromittierten App also verborgen bleibt:

| | 24 Wörter | 12 Wörter |
|---|---|---|
| gewürfelte Wörter | 23 | 11 |
| davon ungelesen | 23 × 5 = 115 bit | 11 × 5 = 55 bit |
| freie Bits im letzten Wort | 3 | 7 |
| **verborgen** | **118 bit** | **62 bit** |

118 bit sind unangreifbar. **62 bit sind es nicht.** Der Modus wird deshalb ohne
Längenwahl gebaut und ist immer 24 Wörter. `hiddenBits(for:)` rechnet beide Fälle aus,
damit der Grund im Test steht und nicht nur in diesem Dokument.

Zum Vergleich: Im normalen Pips39-Ablauf sind es 0 bit. Gegenüber dem Ausdruck ist
dieser Modus schlechter, gegenüber dem eigenen Hauptweg besser. Beides gehört gesagt.

### Richtigstellung zu einer früheren Aussage

Ich hatte gesagt, der Modus dürfe *gar nichts* mitzählen. Das war zu grob und hätte die
Bedienung ohne Sicherheitsgewinn verschlechtert. Zu trennen sind zwei Dinge:

- **Die Würfel sammeln** — verboten. Lägen die 23 Tripel im Speicher, wären das 138 bit
  an einer Stelle statt 6 bit für einen Augenblick.
- **Die Wortnummer zählen** — harmlos. Eine Zahl von 1 bis 23 verrät nichts über den
  Seed, und wer 23 Wörter auf eine Karte schreibt, verliert sonst die Zeile.

Gebaut wird also ein Zähler, der **nur** ein `Int` hält, und eine Eingabe, die nach
jedem Wort gelöscht wird.

### Was dieser Modus bewusst nicht kann

Das 24. Wort. Dafür müsste ein Gerät alle 23 Wörter kennen — und genau das soll dieses
Gerät nicht. Die Wallet bietet die acht gültigen Optionen an; die App sagt am Ende nur,
wie man unter ihnen wählt: **drei Münzwürfe**, nicht nach Gefühl. Die BitBox-Anleitung
verlangt an dieser Stelle „nach dem Zufallsprinzip" auszuwählen, nachdem sie auf Seite 1
selbst geschrieben hat, dass Menschen darin schlecht sind. Drei Münzwürfe decken die
acht Optionen exakt ab.

---

### Task 1: `LookupTable` im Paket

**Files:**
- Create: `Sources/Pips39Core/LookupTable.swift`
- Create: `Tests/Pips39CoreTests/LookupTableTests.swift`

- [x] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/LookupTableTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class LookupTableTests: XCTestCase {

    // MARK: Die Formel gegen die offizielle Wortliste

    /// Die acht Seitengrenzen der BitBox-Tabelle. Stimmen die, stimmt die Formel —
    /// sie sind die Ecken des Wertebereichs jeder der drei eingegebenen Stellen.
    func testPageBoundariesMatchTheOfficialList() {
        let expected: [(Int, String)] = [
            (0, "abandon"), (511, "divide"),
            (512, "divorce"), (1023, "lend"),
            (1024, "length"), (1535, "say"),
            (1536, "scale"), (2047, "zoo")
        ]
        for (index, word) in expected {
            XCTAssertEqual(WordList.english[index], word)
        }
    }

    func testIndexOfTheFirstEntry() {
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 1,
                                         fourth: 1, fifth: 1, coin: .heads), 0)
    }

    func testIndexOfTheLastEntry() {
        XCTAssertEqual(LookupTable.index(page: 4, second: 4, third: 4,
                                         fourth: 4, fifth: 4, coin: .tails), 2047)
    }

    /// Die Münze ist das niederwertigste Bit, der erste Würfel das höchstwertige.
    func testPlaceValues() {
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 1,
                                         fourth: 1, fifth: 1, coin: .tails), 1)
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 1,
                                         fourth: 1, fifth: 2, coin: .heads), 2)
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 1,
                                         fourth: 2, fifth: 1, coin: .heads), 8)
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 2,
                                         fourth: 1, fifth: 1, coin: .heads), 32)
        XCTAssertEqual(LookupTable.index(page: 1, second: 2, third: 1,
                                         fourth: 1, fifth: 1, coin: .heads), 128)
        XCTAssertEqual(LookupTable.index(page: 2, second: 1, third: 1,
                                         fourth: 1, fifth: 1, coin: .heads), 512)
    }

    /// Eine 5 oder 6 gibt es nicht — die wird neu geworfen, bevor etwas eingegeben wird.
    func testFacesOutsideOneToFourAreRejected() {
        XCTAssertNil(LookupTable.index(page: 5, second: 1, third: 1,
                                       fourth: 1, fifth: 1, coin: .heads))
        XCTAssertNil(LookupTable.index(page: 0, second: 1, third: 1,
                                       fourth: 1, fifth: 1, coin: .heads))
        XCTAssertNil(LookupTable.block(page: 1, second: 6, third: 1))
    }

    // MARK: Der Block, der auf dem Schirm landet

    func testBlockHasThirtyTwoWords() {
        XCTAssertEqual(LookupTable.block(page: 1, second: 1, third: 1)?.count, 32)
    }

    func testFirstBlockIsTheStartOfTheList() {
        XCTAssertEqual(LookupTable.block(page: 1, second: 1, third: 1),
                       Array(WordList.english.prefix(32)))
    }

    /// Die 64 Blöcke müssen die Wortliste lückenlos und überschneidungsfrei abdecken.
    /// Fehlt ein Wort, wäre es unerreichbar; käme eines doppelt vor, wäre die
    /// Verteilung schief.
    func testTheSixtyFourBlocksTileTheWholeList() {
        var seen: [String] = []
        for page in 1...4 {
            for second in 1...4 {
                for third in 1...4 {
                    guard let block = LookupTable.block(page: page, second: second,
                                                        third: third) else {
                        return XCTFail("Block fehlt: \(page)/\(second)/\(third)")
                    }
                    seen.append(contentsOf: block)
                }
            }
        }
        XCTAssertEqual(seen.count, 2048)
        XCTAssertEqual(seen, WordList.english)
    }

    /// Jede Zelle des Rasters muss genau dem Index entsprechen, den die Formel für
    /// dieselben Würfe liefert — sonst liest der Nutzer das falsche Wort ab.
    func testGridPositionMatchesTheFormula() {
        let block = LookupTable.block(page: 3, second: 2, third: 4)!
        for fourth in 1...4 {
            for fifth in 1...4 {
                for coin in LookupTable.Coin.allCases {
                    let offset = LookupTable.offsetInBlock(fourth: fourth, fifth: fifth,
                                                           coin: coin)!
                    let index = LookupTable.index(page: 3, second: 2, third: 4,
                                                  fourth: fourth, fifth: fifth,
                                                  coin: coin)!
                    XCTAssertEqual(block[offset], WordList.english[index])
                }
            }
        }
    }

    // MARK: Die Bit-Bilanz

    /// 23 gewürfelte Wörter mit je 5 ungelesenen Bit, dazu die 3 freien Bit im
    /// 24. Wort. Diese Zahl steht in der App und trägt die Entscheidung, dass es
    /// den Modus nur für 24 Wörter gibt.
    func testHiddenBitsForTwentyFourWords() {
        XCTAssertEqual(LookupTable.hiddenBits(for: .twentyFour), 118)
    }

    /// Warum es keine Zwölf-Wort-Variante gibt: 62 bit sind angreifbar.
    func testTwelveWordsWouldFallBelowTheThreshold() {
        XCTAssertEqual(LookupTable.hiddenBits(for: .twelve), 62)
        XCTAssertLessThan(LookupTable.hiddenBits(for: .twelve), 128)
        XCTAssertGreaterThan(LookupTable.hiddenBits(for: .twentyFour), 128)
    }

    func testRolledWordCount() {
        XCTAssertEqual(LookupTable.rolledWords(for: .twentyFour), 23)
    }
}
```

- [x] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

```bash
cd "$REPO" && swift test 2>&1 | grep -E "error:" | head -3
```
Expected: `cannot find 'LookupTable' in scope`.

> [!warning] `WordList.english` muss öffentlich und ein `[String]` sein
> Vor dem Schreiben prüfen: `grep -n "public" Sources/Pips39Core/WordList.swift`.
> Heißt die Eigenschaft anders oder ist sie intern, in den Tests den vorhandenen
> Namen benutzen und **nicht** die Wortliste ein zweites Mal einbetten.

- [x] **Step 3: `LookupTable` schreiben**

`Sources/Pips39Core/LookupTable.swift`:

```swift
import Foundation

/// Die BitBox02-Diceware-Tabelle als Rechnung statt als Ausdruck.
///
/// Fünf Würfel und eine Münze wählen ein Wort aus der BIP39-Liste. Würfel zeigen nur
/// 1 bis 4 — eine 5 oder 6 wird neu geworfen. Das ist Rejection Sampling und liefert
/// exakt 2 bit je Würfel, ohne Modulo-Bias und ohne Kürzung. Mit dem Münzbit sind es
/// 11 bit, also genau die 2048 Wörter.
///
/// ```
/// Index = (W1−1)·512 + (W2−1)·128 + (W3−1)·32 + (W4−1)·8 + (W5−1)·2 + Münze
/// ```
///
/// **Die App bekommt nur die ersten drei Würfel zu sehen.** Sie zeigt daraufhin den
/// Block von 32 Wörtern, in dem das gesuchte steht; welches davon es ist, liest der
/// Nutzer ab und tippt es nie ein. Deshalb kennt die App 6 von 11 bit je Wort — siehe
/// `hiddenBits(for:)`.
///
/// Hier wird bewusst **nichts** gerechnet, was über die Formel hinausgeht: Wer der App
/// nicht traut, prüft sie gegen eine beliebige BIP39-Wortliste und ist fertig.
public enum LookupTable {

    /// Wie viele Wörter die App zeigt, nachdem drei Würfel eingegeben wurden:
    /// 4 (Würfel 4) × 4 (Würfel 5) × 2 (Münze).
    public static let wordsPerBlock = 32

    /// Der Münzwurf. Wer keine Münze hat, wirft einen Würfel: 1 bis 3 ist Kopf,
    /// 4 bis 6 ist Zahl — beides drei von sechs, also unverfälscht.
    public enum Coin: CaseIterable, Equatable {
        case heads
        case tails

        var bit: Int { self == .heads ? 0 : 1 }
    }

    private static let validFaces = 1...4

    /// Der Wortindex, oder `nil` wenn ein Würfel außerhalb 1 bis 4 liegt.
    public static func index(page: Int, second: Int, third: Int,
                             fourth: Int, fifth: Int, coin: Coin) -> Int? {
        guard let base = blockStart(page: page, second: second, third: third),
              let offset = offsetInBlock(fourth: fourth, fifth: fifth, coin: coin)
        else { return nil }
        return base + offset
    }

    /// Die 32 Wörter, unter denen das gesuchte steht — in genau der Reihenfolge, die
    /// `offsetInBlock(fourth:fifth:coin:)` adressiert.
    public static func block(page: Int, second: Int, third: Int) -> [String]? {
        guard let start = blockStart(page: page, second: second, third: third) else {
            return nil
        }
        return Array(WordList.english[start..<(start + wordsPerBlock)])
    }

    /// Die Stelle im Block. Die Ansicht baut daraus ihr Raster, damit Formel und
    /// Anzeige nicht auseinanderlaufen können.
    public static func offsetInBlock(fourth: Int, fifth: Int, coin: Coin) -> Int? {
        guard validFaces.contains(fourth), validFaces.contains(fifth) else { return nil }
        return (fourth - 1) * 8 + (fifth - 1) * 2 + coin.bit
    }

    private static func blockStart(page: Int, second: Int, third: Int) -> Int? {
        guard validFaces.contains(page),
              validFaces.contains(second),
              validFaces.contains(third) else { return nil }
        return (page - 1) * 512 + (second - 1) * 128 + (third - 1) * 32
    }

    // MARK: Was der App verborgen bleibt

    /// So viele Wörter werden gewürfelt — das letzte kommt aus der Wallet, weil dafür
    /// die Prüfsumme über alle anderen nötig wäre.
    public static func rolledWords(for length: SeedLength) -> Int {
        length.wordCount - 1
    }

    /// Die Entropie, die diese App auch dann nicht kennt, wenn sie kompromittiert ist.
    ///
    /// Je gewürfeltem Wort bleiben 5 der 11 bit ungelesen. Dazu kommen die freien Bits
    /// im letzten Wort: 11 minus der Prüfsumme, also 3 bei 24 Wörtern und 7 bei 12.
    ///
    /// Das Ergebnis trägt die Entscheidung, dass es diesen Modus nur mit 24 Wörtern
    /// gibt: 118 bit sind unangreifbar, 62 bit sind es nicht.
    public static func hiddenBits(for length: SeedLength) -> Int {
        let checksumBits = length.entropyBits / 32
        let freeBitsInLastWord = 11 - checksumBits
        return rolledWords(for: length) * 5 + freeBitsInLastWord
    }
}
```

- [x] **Step 4: Test laufen lassen**

```bash
cd "$REPO" && swift test 2>&1 | grep -E "error:|Executed [0-9]+ tests, with" | tail -2
```
Expected: PASS.

- [x] **Step 5: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core/LookupTable.swift Tests/Pips39CoreTests/LookupTableTests.swift
git commit -m "feat: LookupTable — die BitBox-Diceware-Tabelle als Formel"
git push
```

---

### Task 2: Die Ableseansicht

**Files:**
- Create: `Pips39/Pips39/LookupView.swift`

- [x] **Step 1: Die Ansicht schreiben**

Drei Würfel werden eingegeben, dann erscheint das Raster: vier Spalten (Würfel 4),
acht Zeilen (Würfel 5 und Münze).

> [!note] Gedreht gegenüber dem Ausdruck, mit Absicht
> Das PDF legt acht Spalten nebeneinander, weil es DIN A4 quer hat. Acht Wortspalten
> passen auf keinem iPhone hochkant nebeneinander. Vier Spalten und acht Zeilen zeigen
> dieselben 32 Wörter, in derselben Reihenfolge, ohne dass jemand das Gerät drehen
> muss. Beim Vergleich mit dem Ausdruck ist es also transponiert.

```swift
import SwiftUI
import Pips39Core

/// Der Ausdruck auf dem Schirm. Die App zeigt 32 Kandidaten und erfährt nie, welcher
/// davon genommen wurde.
///
/// Was hier bewusst fehlt: eine Sitzung. Gespeichert wird die Wortnummer, sonst
/// nichts — die eingegebenen Würfel werden nach jedem Wort gelöscht. Lägen die 23
/// Tripel im Speicher, wären das 138 bit an einer Stelle statt 6 bit für einen
/// Augenblick.
struct LookupView: View {

    let onExit: () -> Void

    private let totalWords = LookupTable.rolledWords(for: .twentyFour)

    @State private var dice: [Int] = []
    @State private var wordNumber = 1
    @State private var isFinished = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            bar

            if isFinished {
                closing
            } else {
                header
                diceInput
                if let block = currentBlock {
                    grid(for: block)
                    nextButton
                } else {
                    hint
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .screenProtected()
        .hiddenFromScreenCapture()
    }

    private var currentBlock: [String]? {
        guard dice.count == 3 else { return nil }
        return LookupTable.block(page: dice[0], second: dice[1], third: dice[2])
    }

    // MARK: Kopf

    private var bar: some View {
        HStack {
            Button(action: onExit) {
                Label("Back", systemImage: "chevron.left")
            }
            Spacer()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Word \(wordNumber) of \(totalWords)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            Text("Throw five dice and the coin. Re-throw any die showing 5 or 6. Then enter the first three dice.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Eingabe der ersten drei Würfel

    private var diceInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ForEach(1...4, id: \.self) { face in
                    Button {
                        if dice.count < 3 { dice.append(face) }
                    } label: {
                        Image(systemName: "die.face.\(face).fill")
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(dice.count == 3)
                }
            }

            HStack {
                ForEach(Array(dice.enumerated()), id: \.offset) { _, face in
                    Image(systemName: "die.face.\(face).fill")
                        .font(.title3)
                }
                Spacer()
                Button("Undo") { _ = dice.popLast() }
                    .font(.footnote)
                    .disabled(dice.isEmpty)
            }
            .frame(minHeight: 28)
        }
    }

    private var hint: some View {
        Text("A die showing 5 or 6 carries no value here. Throw it again until it shows 1 to 4.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    // MARK: Das Raster

    private func grid(for block: [String]) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(" ").frame(width: 46)
                ForEach(1...4, id: \.self) { fourth in
                    Image(systemName: "die.face.\(fourth).fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            ForEach(rowKeys, id: \.offset) { row in
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "die.face.\(row.fifth).fill")
                        Text(row.coin == .heads ? "H" : "T")
                            .font(.caption2.weight(.bold))
                    }
                    .frame(width: 46, alignment: .leading)
                    .foregroundStyle(.secondary)

                    ForEach(1...4, id: \.self) { fourth in
                        Text(block[LookupTable.offsetInBlock(fourth: fourth,
                                                             fifth: row.fifth,
                                                             coin: row.coin)!])
                            .font(.footnote)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Text("H = heads (or a die showing 1 to 3), T = tails (4 to 6).")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
    }

    private struct RowKey {
        let fifth: Int
        let coin: LookupTable.Coin
        var offset: Int { (fifth - 1) * 2 + (coin == .heads ? 0 : 1) }
    }

    private var rowKeys: [RowKey] {
        (1...4).flatMap { fifth in
            LookupTable.Coin.allCases.map { RowKey(fifth: fifth, coin: $0) }
        }
    }

    // MARK: Weiter

    private var nextButton: some View {
        Button {
            if wordNumber == totalWords {
                isFinished = true
            } else {
                wordNumber += 1
            }
            dice = []
        } label: {
            Text(wordNumber == totalWords ? "Done" : "Next word")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.top, 4)
    }

    // MARK: Der Abschluss

    private var closing: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The 24th word")
                .font(.title2.weight(.semibold))
            Text("This app cannot work it out. It never saw your words, and the last word carries a checksum over all the others.")
                .font(.footnote)
            Text("Enter your 23 words into your wallet. It will offer eight valid options for the last one. Pick between them with three coin flips, not by feel — eight options are exactly three bits.")
                .font(.footnote)
            Button("Done", action: onExit)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }
}

#Preview {
    LookupView(onExit: { })
}
```

> [!warning] `block[...]` mit `!` ist hier sicher, aber nur hier
> `offsetInBlock` bekommt ausschließlich Werte aus `1...4` und `Coin.allCases`. Wer die
> Schleifengrenzen ändert, muss das `!` mit ändern.

- [x] **Step 2: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [x] **Step 3: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/LookupView.swift
git commit -m "feat: Ableseansicht für die Nachschlagetabelle"
```

---

### Task 3: Die Einstiegsseite bekommt einen zweiten Block

**Files:**
- Modify: `Pips39/Pips39/MethodChoiceView.swift`

- [x] **Step 1: Signatur erweitern und scrollbar machen**

Der Eintrag ist **kein** drittes Verfahren: Die beiden Karten beantworten dieselbe
Frage und führen in denselben Ablauf, dieser Eintrag nicht. Ihn danebenzustellen würde
außerdem den Seed-Längen-Schalter zur Falle machen — er gilt für ihn nicht.

Deshalb: eigener Block unter einem `Divider()`, mit eigener Überschrift und dem
Zusatz, dass es immer 24 Wörter sind.

Änderungen an `MethodChoiceView`:

```swift
    let onChoose: (DiceMethod, SeedLength) -> Void
    let onChooseLookupTable: () -> Void
```

Den Körper in eine `ScrollView` setzen — mit dem zweiten Block passt die Seite auf
kleinen Geräten sonst nicht mehr:

```swift
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ... unverändert bis einschließlich des Verfahrens-Hinweistexts ...

                Divider()

                lookupSection
            }
            .padding()
        }
    }
```

Der neue Abschnitt, hinter den bestehenden Hinweistext:

```swift
    /// Bewusst abgesetzt und nicht als dritte Karte: Dieser Weg erzeugt den Seed
    /// nicht in der App, er führt in keine Würfelansicht, und der Längen-Schalter
    /// oben gilt für ihn nicht.
    private var lookupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Roll without a printout")
                .font(.headline)

            Button(action: onChooseLookupTable) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lookup table")
                        .font(.title3.weight(.semibold))
                    Text("For dice and a hardware wallet. The seed is made on paper — this app only shows the words to read off, and never learns it.")
                        .font(.footnote)
                    Text("Always 24 words.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
```

Das abschließende `Spacer()` entfällt — in einer `ScrollView` hat es keine Wirkung.

Die Vorschau nachziehen:

```swift
#Preview {
    MethodChoiceView(onChoose: { _, _ in }, onChooseLookupTable: { })
}
```

- [x] **Step 2: Bauen**

Der Build **muss** jetzt an `ContentView` scheitern (fehlendes Argument). Das ist der
erwartete Zwischenstand; Task 4 schließt ihn.

---

### Task 4: In den Ablauf einhängen

**Files:**
- Modify: `Pips39/Pips39/ContentView.swift`

- [x] **Step 1: Zustand und Verzweigung ergänzen**

```swift
    @State private var showsLookupTable = false
```

Im Körper, **vor** der Prüfung auf `session`, damit der Modus unabhängig vom
Würfelablauf lebt:

```swift
        if !hasStarted {
            OnboardingView(probe: probe) { hasStarted = true }
        } else if showsLookupTable {
            LookupView { showsLookupTable = false }
        } else if let session {
            // ... unverändert ...
        } else {
            VStack(spacing: 12) {
                EnvironmentNotice(probe: probe)
                MethodChoiceView { method, length in
                    session = DiceSession(method: method, length: length)
                    step = .rolling
                } onChooseLookupTable: {
                    showsLookupTable = true
                }
            }
        }
```

- [x] **Step 2: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [x] **Step 3: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/MethodChoiceView.swift Pips39/Pips39/ContentView.swift
git commit -m "feat: Nachschlagetabelle als eigener Block auf der Einstiegsseite"
```

---

### Task 5: Die deutschen Texte

**Files:**
- Modify: `Pips39/Pips39/de.lproj/Localizable.strings`

- [x] **Step 1: Eintragen**

Die englische Tabelle bleibt leer — dort sind die Schlüssel selbst der Text.

```
/* ===== Nachschlagetabelle ===== */
"Roll without a printout" = "Ohne Ausdruck würfeln";
"Lookup table" = "Nachschlagetabelle";
"For dice and a hardware wallet. The seed is made on paper — this app only shows the words to read off, and never learns it." = "Für Würfel und eine Hardware-Wallet. Der Seed entsteht auf Papier — diese App zeigt nur die Wörter zum Ablesen und erfährt ihn nie.";
"Always 24 words." = "Immer 24 Wörter.";
"Throw five dice and the coin. Re-throw any die showing 5 or 6. Then enter the first three dice." = "Fünf Würfel und die Münze werfen. Jeden Würfel, der 5 oder 6 zeigt, neu werfen. Dann die ersten drei Würfel eingeben.";
"A die showing 5 or 6 carries no value here. Throw it again until it shows 1 to 4." = "Eine 5 oder 6 trägt hier keinen Wert. Den Würfel neu werfen, bis er 1 bis 4 zeigt.";
"H" = "K";
"T" = "Z";
"H = heads (or a die showing 1 to 3), T = tails (4 to 6)." = "K = Kopf (oder ein Würfel mit 1 bis 3), Z = Zahl (4 bis 6).";
"Next word" = "Nächstes Wort";
"The 24th word" = "Das 24. Wort";
"This app cannot work it out. It never saw your words, and the last word carries a checksum over all the others." = "Diese App kann es nicht berechnen. Sie hat die Wörter nie gesehen, und das letzte Wort trägt eine Prüfsumme über alle anderen.";
"Enter your 23 words into your wallet. It will offer eight valid options for the last one. Pick between them with three coin flips, not by feel — eight options are exactly three bits." = "Die 23 Wörter in die Wallet eingeben. Sie bietet acht gültige Möglichkeiten für das letzte an. Zwischen ihnen mit drei Münzwürfen wählen, nicht nach Gefühl — acht Möglichkeiten sind genau drei Bit.";
"Word %lld of %lld" = "Wort %lld von %lld";
```

> [!warning] Zwei Fallen, beide in diesem Projekt schon einmal zugeschnappt
> 1. **Jede Zeile hat genau vier gerade Anführungszeichen.** Ein `"` im Text bricht
>    die Datei ohne Zeilenangabe. Prüfen:
>    ```bash
>    grep -n '^"' de.lproj/Localizable.strings | awk -F: '{n=gsub(/"/,"\"",$0); if (n!=4) print "FEHLER", $0}'
>    ```
> 2. **`"Word %lld of %lld"` steht bereits in der Datei** (Abschreibkontrolle). Nicht
>    doppelt eintragen — beim zweiten Vorkommen gewinnt der letzte Eintrag, und
>    identisch ist er hier ohnehin. Vorher `grep -c` prüfen und die Zeile nur ergänzen,
>    wenn sie fehlt.

- [x] **Step 2: Bauen und committen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | tail -3
cd "$REPO"
git add Pips39/Pips39/de.lproj/Localizable.strings
git commit -m "i18n: Texte der Nachschlagetabelle"
git push
```

---

### Task 6: Sichtprüfung

- [x] **Step 1: Der Weg hinein**

Onboarding überspringen. Auf der Einstiegsseite muss unter einer Trennlinie der Block
„Ohne Ausdruck würfeln" stehen — **nicht** als dritte Karte neben SHA-256 und Coleman.
Der Seed-Längen-Schalter darf sichtbar zum oberen Block gehören.

- [x] **Step 2: Ein Wort nachschlagen und gegen die Formel prüfen**

Würfel 1, 1, 1 eingeben. Die **erste Zeile** muss dann lauten:
`abandon · absurd · acoustic · adapt`, die **erste Spalte** von oben nach unten
`abandon · ability · able · about · above · absent · absorb · abstract`.

Nachrechnen statt raten:

```bash
python3 -c "
w=open('$REPO/Sources/Pips39Core/Resources/english.txt').read().split()
for f4 in range(1,5):
    print('Wuerfel4 =', f4, [w[(f4-1)*8+(f5-1)*2+c] for f5 in range(1,5) for c in (0,1)])
"
```

Die vier ausgegebenen Listen sind die vier **Spalten** des Rasters, jede von oben nach
unten. Bildschirm damit vergleichen.

- [x] **Step 3: Zähler und Löschung**

„Nächstes Wort" tippen. Die Würfeleingabe muss leer sein, das Raster verschwunden, der
Zähler auf 2 von 23.

- [x] **Step 4: Der Abschluss**

Bis 23 durchzählen ist zu mühsam für die Sichtprüfung. Stattdessen `totalWords` in
`LookupView` vorübergehend auf 2 setzen, bauen, den Abschlusstext ansehen — und den
Wert **zurücksetzen**, bevor irgendetwas committet wird.

---

## Abschluss der Phase

- [x] **Spec nachziehen:** In `~/Documents/Doku/02 Projekte/Ideen und Tests/Pips39/würfel-tool-spec.md`
      einen Abschnitt 2.8 „Nachschlagetabelle" anlegen: die Formel, die Bit-Bilanz
      (118 gegen 62), warum es kein drittes Verfahren ist, und dass das 24. Wort
      bewusst außerhalb bleibt. In Abschnitt 10 „Verworfen" den Satz ergänzen, dass
      eine Zwölf-Wort-Variante an den 62 bit scheitert.

- [x] **Quelle vermerken:** Die BitBox-Anleitung liegt unter `BitBox-Anleitung/` im
      Repo und steht unter CC BY-SA 4.0. Im README und in der Spec nennen, woher das
      Verfahren stammt — das ist keine Höflichkeit, sondern die Lizenzbedingung.

> [!warning] Vor dem Push: `git diff` auf `DEVELOPMENT_TEAM` prüfen
> Xcode trägt die Team-ID beim nächsten Signieren auf einem Gerät neu ein. Sie darf
> nicht ins öffentliche Repo.

## Was danach kommt (nicht Teil dieses Plans)

- App-Store-Einreichung: Beschreibung in beiden Sprachen, Screenshots, der Satz zu
  Quelltext gegen Binary
- Offen aus Phase 6: Der Seed-Längen-Schalter springt beim Verwerfen auf 24 zurück
- Offen aus Phase 4: `SecureLayer` ist nur auf echter Hardware prüfbar
