# Pips39 — Phase 2: DiceEntropy (Verfahren A und B) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein getesteter `DiceEntropy`-Puffer, der Würfelwürfe entgegennimmt, Rückgängig beherrscht und daraus nach **beiden** im Spec festgelegten Verfahren 256 Bit Entropie erzeugt — Verfahren A bitgenau wie Ian Colemans Werkzeug, Verfahren B als SHA-256 über die Wurffolge.

**Architecture:** Drei neue Typen im bestehenden Swift Package `Pips39Core`. `DiceMethod` benennt das Verfahren, `ColemanEncoding` kapselt Colemans Bit-Tabelle samt Kürzungsregel, `DiceEntropy` hält den Ziffernpuffer und liefert je nach Verfahren die Entropie. Kein UI, keine Speicherung. Die Verfahrenstreue ist vollständig ohne UI testbar: Verfahren A gegen die fünf mit Colemans echtem JavaScript erzeugten Vektoren in `coleman-vectors.json`, Verfahren B gegen `shasum -a 256`.

**Tech Stack:** Swift 5.9, SwiftPM, CryptoKit, XCTest. `swift test` auf der Kommandozeile, kein Simulator.

**Spec:** `~/Documents/Doku/02 Projekte/Ideen und Tests/Pips39/würfel-tool-spec.md`, Abschnitte 2.1 und 2.4
**Quellenanalyse:** `docs/coleman-verfahren.md` im Repo — dort steht jede Behauptung mit Zeilenbeleg

**Vorhanden aus Phase 1:** `WordList`, `BitStream`, `BIP39` (Erzeugung, `isValid`, `firstMismatch`), `SecretBytes`. 32 Tests grün.

**Nicht in dieser Phase:** BIP39-Tastatur, `EnvironmentProbe`, App-Target, jegliche UI.

---

## Die beiden Verfahren in einem Absatz

**Verfahren A („Coleman"):** Jeder Wurf wird einzeln in eine Bitfolge übersetzt —
`1→01`, `2→10`, `3→11`, `6→00` (je zwei Bit), `4→0`, `5→1` (je ein Bit). Es wird
gewürfelt, bis mindestens 256 Rohbits zusammen sind; dann werden die **vordersten**
überzähligen Bits verworfen, so dass genau 256 bleiben. Die Wurfzahl steht vorher
nicht fest (im Mittel rund 154, mindestens 128, höchstens 256).

**Verfahren B („SHA-256", Standard):** Genau 99 Würfe. Die Ziffernkette wird als
ASCII gehasht, der 256-Bit-Hash ist die Entropie.

> [!danger] Die 6 wird in den beiden Verfahren unterschiedlich behandelt
> In **Verfahren A** wird die 6 vor der Umrechnung zur 0 (Colemans Zeichenersetzung).
> In **Verfahren B** wird die Ziffernfolge **so gehasht, wie sie gewürfelt wurde** —
> die 6 bleibt eine 6.
>
> Das ist kein Versehen und darf nicht „vereinheitlicht" werden. Der Beleg, dass es
> wirklich so auseinanderläuft, steckt in den vorhandenen Daten: Für 99 × `1` (keine
> 6 enthalten) stimmt unser Hash `fa098eb8…` exakt mit Colemans Hash-Pfad in
> `coleman-vectors.json` überein. Für 99 × `6` ergibt unser Verfahren `7efb8e5d…`,
> Coleman dagegen `37b322ff…` — weil er `000…` hasht statt `666…`.
>
> Für die Nachrechenbarkeit von B ist das ohne Belang: Der Prüfweg ist
> `printf '%s' "<Wurffolge>" | shasum -a 256` und dann der Hex-Wert in Colemans
> Feld „Entropy". Colemans eigener Hash-Pfad wird dabei nie benutzt.

---

### Task 1: `DiceMethod` und Colemans Bit-Tabelle

**Files:**
- Modify: `Package.swift` (zweite Testressource anmelden)
- Create: `Sources/Pips39Core/DiceMethod.swift`
- Create: `Sources/Pips39Core/ColemanEncoding.swift`
- Create: `Tests/Pips39CoreTests/ColemanEncodingTests.swift`

- [ ] **Step 1: `Package.swift` um die zweite Testressource ergänzen**

Im `testTarget` die `resources`-Zeile ersetzen durch:

```swift
            resources: [
                .copy("Resources/vectors.json"),
                .copy("Resources/coleman-vectors.json")
            ]
```

- [ ] **Step 2: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/ColemanEncodingTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class ColemanEncodingTests: XCTestCase {

    // MARK: Bit-Tabelle

    func testTwoBitRolls() {
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 1), [false, true])   // 01
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 2), [true, false])   // 10
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 3), [true, true])    // 11
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 6), [false, false])  // 00, die 6 wird zur 0
    }

    func testOneBitRolls() {
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 4), [false])
        XCTAssertEqual(ColemanEncoding.bits(forRoll: 5), [true])
    }

    func testRawBitsConcatenatesInRollOrder() {
        // 1 -> 01, 4 -> 0, 2 -> 10  ergibt  01 0 10
        XCTAssertEqual(ColemanEncoding.rawBits(for: [1, 4, 2]),
                       [false, true, false, true, false])
    }

    func testRawBitsOfEmptyInputIsEmpty() {
        XCTAssertEqual(ColemanEncoding.rawBits(for: []), [])
    }

    // MARK: gegen Colemans echte Ausgabe

    func testRawBitsMatchColemanVectors() throws {
        for vector in try ColemanVectors.load() {
            let bits = ColemanEncoding.rawBits(for: vector.rollDigits)
            XCTAssertEqual(bitString(bits), vector.rohBinaer,
                           "Rohbits weichen ab bei: \(vector.name)")
            XCTAssertEqual(bits.count, vector.rohBits,
                           "Bitanzahl weicht ab bei: \(vector.name)")
        }
    }

    private func bitString(_ bits: [Bool]) -> String {
        String(bits.map { $0 ? "1" : "0" })
    }
}
```

- [ ] **Step 3: Die Vektor-Hilfsdatei schreiben**

`Tests/Pips39CoreTests/ColemanVectors.swift`:

```swift
import XCTest
@testable import Pips39Core

/// Zugriff auf die mit Colemans echtem JavaScript erzeugten Referenzvektoren.
enum ColemanVectors {

    struct Vector: Decodable {
        let name: String
        let wuerfe: String
        let entropieHex: String
        let mnemonic: String
        let rohBinaer: String
        let rohBits: Int
        let genutzteBits: Int
        let woerter: Int

        /// Die Wurffolge als Ziffern 1…6.
        var rollDigits: [UInt8] {
            wuerfe.compactMap { $0.wholeNumberValue.map(UInt8.init) }
        }
    }

    private struct File: Decodable {
        let vektoren: [Vector]
    }

    static func load() throws -> [Vector] {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "coleman-vectors", withExtension: "json"),
            "coleman-vectors.json fehlt im Test-Bundle"
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(File.self, from: Data(contentsOf: url)).vektoren
    }
}
```

- [ ] **Step 4: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `cannot find 'ColemanEncoding' in scope`.

- [ ] **Step 5: `DiceMethod.swift` schreiben**

```swift
import Foundation

/// Das Verfahren, mit dem aus Würfen Entropie wird.
///
/// Die Wahl gehört zum Ergebnis, nicht in die Einstellungen: Eine Wurffolge sagt
/// nicht, mit welchem Verfahren sie gerechnet wurde, und dieselbe Folge ergibt unter
/// beiden Verfahren verschiedene, jeweils gültige Mnemonics.
public enum DiceMethod: String, CaseIterable, Equatable {

    /// SHA-256 über die Wurffolge, wie sie gewürfelt wurde. Feste Wurfzahl.
    /// Standard. Nachprüfbar mit `printf '%s' "…" | shasum -a 256`.
    case sha256

    /// Colemans Bit-Tabelle, bitgenau nachgebaut. Keine feste Wurfzahl.
    /// Nachprüfbar durch direkte Eingabe der Wurffolge bei iancoleman.io/bip39.
    case coleman
}
```

- [ ] **Step 6: `ColemanEncoding.swift` schreiben**

```swift
import Foundation

/// Colemans Umrechnung von Würfen in Entropie, bitgenau nachgebaut.
///
/// Belegt am Quelltext von `iancoleman/bip39`, siehe `docs/coleman-verfahren.md`.
/// Jeder Wurf liefert ein oder zwei Bit; die Ausbeute liegt bei 1,67 Bit pro Wurf
/// statt der 2,585 Bit einer ganzzahligen Base-6-Umrechnung. Dafür ist die Abbildung
/// bias-frei.
enum ColemanEncoding {

    /// Bits eines einzelnen Wurfs. Die 6 wird wie eine 0 behandelt.
    static func bits(forRoll roll: UInt8) -> [Bool] {
        switch roll {
        case 1: return [false, true]    // 01
        case 2: return [true, false]    // 10
        case 3: return [true, true]     // 11
        case 4: return [false]          // 0
        case 5: return [true]           // 1
        case 6: return [false, false]   // 00 — die 6 wird zur 0
        default: preconditionFailure("Ungültiger Wurf \(roll), erlaubt sind 1…6")
        }
    }

    /// Alle Bits einer Wurffolge, in Wurfreihenfolge aneinandergehängt.
    static func rawBits(for rolls: [UInt8]) -> [Bool] {
        rolls.flatMap { bits(forRoll: $0) }
    }
}
```

- [ ] **Step 7: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS. `testRawBitsMatchColemanVectors` prüft alle fünf Vektoren.

- [ ] **Step 8: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Package.swift Sources/Pips39Core/DiceMethod.swift Sources/Pips39Core/ColemanEncoding.swift Tests/Pips39CoreTests/ColemanEncodingTests.swift Tests/Pips39CoreTests/ColemanVectors.swift
git commit -m "feat: Colemans Bit-Tabelle, geprüft gegen seine echte Ausgabe"
git push
```

---

### Task 2: Colemans Kürzungsregel

**Files:**
- Modify: `Sources/Pips39Core/ColemanEncoding.swift`
- Modify: `Tests/Pips39CoreTests/ColemanEncodingTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

Folgendes vor der privaten `bitString`-Methode in `ColemanEncodingTests` einfügen:

```swift
    // MARK: Kürzung auf ein Vielfaches von 32

    func testTruncationKeepsMultipleOf32AndDropsLeadingBits() {
        // 34 Bits: die ersten beiden fallen weg, 32 bleiben.
        var bits = Array(repeating: false, count: 34)
        bits[0] = true   // fällt weg
        bits[1] = true   // fällt weg
        bits[2] = true   // bleibt, wird zum höchstwertigen Bit
        let entropy = ColemanEncoding.entropy(fromRawBits: bits)
        XCTAssertEqual(entropy.count, 4)
        XCTAssertEqual(entropy[0], 0b1000_0000)
    }

    func testTruncationYieldsNothingBelow32Bits() {
        XCTAssertEqual(ColemanEncoding.entropy(fromRawBits: Array(repeating: true, count: 31)), [])
        XCTAssertEqual(ColemanEncoding.entropy(fromRawBits: []), [])
    }

    func testEntropyMatchesColemanVectors() throws {
        for vector in try ColemanVectors.load() {
            let entropy = ColemanEncoding.entropy(from: vector.rollDigits)
            XCTAssertEqual(hexString(entropy), vector.entropieHex,
                           "Entropie weicht ab bei: \(vector.name)")
            XCTAssertEqual(entropy.count * 8, vector.genutzteBits,
                           "Genutzte Bits weichen ab bei: \(vector.name)")
        }
    }

    private func hexString(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `type 'ColemanEncoding' has no member 'entropy'`.

- [ ] **Step 3: `ColemanEncoding.swift` erweitern**

Vor der schließenden Klammer von `enum ColemanEncoding` einfügen:

```swift
    /// Kürzt Rohbits auf das nächstkleinere Vielfache von 32 und macht Bytes daraus.
    ///
    /// Coleman verwirft dabei die **vordersten** Bits:
    /// `start = bits.length - Math.floor(bits.length/32)*32`. Sein eigener Kommentar
    /// „Discard trailing entropy" ist falsch — es fällt der Anfang weg.
    /// Unter 32 Rohbits bleibt nichts übrig.
    static func entropy(fromRawBits bits: [Bool]) -> [UInt8] {
        let usable = (bits.count / 32) * 32
        guard usable > 0 else { return [] }
        let kept = Array(bits.suffix(usable))

        var bytes = [UInt8]()
        bytes.reserveCapacity(usable / 8)
        var index = kept.startIndex
        while index < kept.endIndex {
            var byte: UInt8 = 0
            for offset in 0..<8 {
                byte = (byte << 1) | (kept[index + offset] ? 1 : 0)
            }
            bytes.append(byte)
            index += 8
        }
        return bytes
    }

    /// Entropie direkt aus einer Wurffolge.
    static func entropy(from rolls: [UInt8]) -> [UInt8] {
        entropy(fromRawBits: rawBits(for: rolls))
    }
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS. `testEntropyMatchesColemanVectors` prüft alle fünf Vektoren, darunter zwei mit leerem Ergebnis (zu wenig Entropie) und drei mit 160 bzw. 192 Bit.

- [ ] **Step 5: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/ColemanEncoding.swift Tests/Pips39CoreTests/ColemanEncodingTests.swift
git commit -m "feat: Colemans Kürzungsregel — vorne abschneiden auf Vielfaches von 32"
git push
```

---

### Task 3: Verfahren A durchgehend bis zum Mnemonic

Der eigentliche Beweis: dieselbe Wurffolge muss bei Pips39 und bei Coleman zu denselben Wörtern führen.

**Files:**
- Create: `Tests/Pips39CoreTests/ColemanRoundTripTests.swift`

- [ ] **Step 1: Den Test schreiben**

```swift
import XCTest
@testable import Pips39Core

/// Der Beweis für Verfahren A: gleiche Würfe, gleiche Wörter wie bei Coleman.
final class ColemanRoundTripTests: XCTestCase {

    func testMnemonicMatchesColemanForEveryVector() throws {
        for vector in try ColemanVectors.load() {
            let entropy = ColemanEncoding.entropy(from: vector.rollDigits)

            guard !entropy.isEmpty else {
                XCTAssertEqual(vector.mnemonic, "",
                               "Coleman liefert Wörter, wir nicht: \(vector.name)")
                XCTAssertEqual(vector.woerter, 0, "Wortzahl passt nicht: \(vector.name)")
                continue
            }

            let words = try BIP39.mnemonic(from: entropy)
            XCTAssertEqual(words.joined(separator: " "), vector.mnemonic,
                           "Wörter weichen ab bei: \(vector.name)")
            XCTAssertEqual(words.count, vector.woerter,
                           "Wortzahl weicht ab bei: \(vector.name)")
        }
    }

    func testEveryProducedMnemonicIsValid() throws {
        for vector in try ColemanVectors.load() {
            let entropy = ColemanEncoding.entropy(from: vector.rollDigits)
            guard !entropy.isEmpty else { continue }
            let words = try BIP39.mnemonic(from: entropy)
            XCTAssertTrue(BIP39.isValid(mnemonic: words),
                          "Erzeugtes Mnemonic gilt als ungültig: \(vector.name)")
        }
    }
}
```

- [ ] **Step 2: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS ohne Änderung am Produktivcode — `ColemanEncoding` und `BIP39` existieren
bereits. Falls hier etwas fehlschlägt, liegt der Fehler in Task 1 oder 2, **nicht** im
Test: Die erwarteten Werte stammen aus Colemans echtem JavaScript.

Hinweis zu den Wortzahlen: Die Vektoren ergeben 0, 0, 18, 18 und 15 Wörter. Dass 18 und
15 keine 24 sind, ist richtig so — die Vektoren bilden Colemans Verhalten bei beliebigen
Wurfzahlen ab, nicht Pips39s Zielgröße. Die kommt in Task 6.

- [ ] **Step 3: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Tests/Pips39CoreTests/ColemanRoundTripTests.swift
git commit -m "test: Verfahren A liefert dieselben Wörter wie Colemans Werkzeug"
git push
```

---

### Task 4: Verfahren B — SHA-256 über die Wurffolge

**Files:**
- Create: `Sources/Pips39Core/HashedEncoding.swift`
- Create: `Tests/Pips39CoreTests/HashedEncodingTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/HashedEncodingTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class HashedEncodingTests: XCTestCase {

    private func rolls(_ text: String) -> [UInt8] {
        text.compactMap { $0.wholeNumberValue.map(UInt8.init) }
    }

    private func hexString(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// Werte erzeugt mit `printf '%s' "<Folge>" | shasum -a 256`.
    func testHashMatchesShasumForNinetyNineOnes() {
        let entropy = HashedEncoding.entropy(from: rolls(String(repeating: "1", count: 99)))
        XCTAssertEqual(hexString(entropy),
                       "fa098eb852b2660348b21bb00ad03a49cc177ea07ebe34f46b40baa85313525e")
    }

    func testHashMatchesShasumForNinetyNineSixes() {
        let entropy = HashedEncoding.entropy(from: rolls(String(repeating: "6", count: 99)))
        XCTAssertEqual(hexString(entropy),
                       "7efb8e5d1353a90137755f711e1763fd7301a033fbb854889e127ff79c389131")
    }

    func testHashMatchesShasumForMixedSequence() {
        let mixed = String(String(repeating: "142536", count: 17).prefix(99))
        let entropy = HashedEncoding.entropy(from: rolls(mixed))
        XCTAssertEqual(hexString(entropy),
                       "fa8ee59f391c1d8cd485f88a29dfee82ddbac1012bf695b8dfd513b7fcafa5b7")
    }

    func testHashMatchesShasumForShortSequence() {
        let entropy = HashedEncoding.entropy(from: rolls("123456"))
        XCTAssertEqual(hexString(entropy),
                       "8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92")
    }

    func testAlwaysProduces32Bytes() {
        XCTAssertEqual(HashedEncoding.entropy(from: rolls("1")).count, 32)
        XCTAssertEqual(HashedEncoding.entropy(from: []).count, 32)
    }

    /// Die 6 wird NICHT zur 0 — anders als bei Verfahren A.
    func testSixIsHashedAsSixNotZero() {
        let asSix = HashedEncoding.entropy(from: rolls("666"))
        let asZero = HashedEncoding.entropy(from: [0, 0, 0])
        XCTAssertNotEqual(asSix, asZero)
    }

    func testProducesTwentyFourWordsFromNinetyNineRolls() throws {
        let entropy = HashedEncoding.entropy(from: rolls(String(repeating: "1", count: 99)))
        let words = try BIP39.mnemonic(from: entropy)
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(words.joined(separator: " "),
                       "wheel erase puppy pistol chapter accuse carpet drop quote final attend near scrap satisfy limit style crunch person south inspire lunch meadow enact tattoo")
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `cannot find 'HashedEncoding' in scope`.

- [ ] **Step 3: `HashedEncoding.swift` schreiben**

```swift
import Foundation
import CryptoKit

/// Verfahren B: SHA-256 über die Wurffolge, so wie sie gewürfelt wurde.
///
/// Die Ziffern werden als ASCII gehasst — die 6 bleibt eine 6. Das unterscheidet
/// dieses Verfahren von `ColemanEncoding`, wo die 6 vor der Umrechnung zur 0 wird.
///
/// Nachprüfbar mit `printf '%s' "<Wurffolge>" | shasum -a 256`; der Hex-Wert lässt
/// sich anschließend in jedes BIP39-Werkzeug als Entropie einsetzen.
enum HashedEncoding {

    /// Immer 32 Byte, unabhängig von der Wurfzahl.
    static func entropy(from rolls: [UInt8]) -> [UInt8] {
        let ascii = rolls.map { UInt8(ascii: "0") + $0 }
        return Array(SHA256.hash(data: Data(ascii)))
    }
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS.

- [ ] **Step 5: Gegenprobe von Hand**

```bash
printf '%s' "$(python3 -c "print('1'*99)")" | shasum -a 256
```
Expected: `fa098eb852b2660348b21bb00ad03a49cc177ea07ebe34f46b40baa85313525e`

Damit ist belegt, dass der im Spec versprochene Prüfweg für Nutzer tatsächlich funktioniert.

- [ ] **Step 6: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/HashedEncoding.swift Tests/Pips39CoreTests/HashedEncodingTests.swift
git commit -m "feat: Verfahren B — SHA-256 über die Wurffolge, gegen shasum geprüft"
git push
```

---

### Task 5: Der Wurfpuffer mit Rückgängig

**Files:**
- Create: `Sources/Pips39Core/DiceEntropy.swift`
- Create: `Tests/Pips39CoreTests/DiceEntropyBufferTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/DiceEntropyBufferTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class DiceEntropyBufferTests: XCTestCase {

    func testStartsEmpty() {
        let buffer = DiceEntropy(method: .sha256)
        XCTAssertEqual(buffer.rolls, [])
    }

    func testAppendsInOrder() throws {
        var buffer = DiceEntropy(method: .sha256)
        try buffer.append(3)
        try buffer.append(1)
        try buffer.append(6)
        XCTAssertEqual(buffer.rolls, [3, 1, 6])
    }

    func testUndoRemovesLastRoll() throws {
        var buffer = DiceEntropy(method: .sha256)
        try buffer.append(3)
        try buffer.append(1)
        buffer.undo()
        XCTAssertEqual(buffer.rolls, [3])
    }

    func testUndoOnEmptyBufferDoesNothing() {
        var buffer = DiceEntropy(method: .sha256)
        buffer.undo()
        XCTAssertEqual(buffer.rolls, [])
    }

    func testRejectsRollBelowOne() {
        var buffer = DiceEntropy(method: .sha256)
        XCTAssertThrowsError(try buffer.append(0)) { error in
            XCTAssertEqual(error as? DiceError, .invalidRoll(0))
        }
        XCTAssertEqual(buffer.rolls, [])
    }

    func testRejectsRollAboveSix() {
        var buffer = DiceEntropy(method: .sha256)
        XCTAssertThrowsError(try buffer.append(7)) { error in
            XCTAssertEqual(error as? DiceError, .invalidRoll(7))
        }
    }

    func testAcceptsAllSixFaces() throws {
        var buffer = DiceEntropy(method: .sha256)
        for face in UInt8(1)...UInt8(6) {
            try buffer.append(face)
        }
        XCTAssertEqual(buffer.rolls, [1, 2, 3, 4, 5, 6])
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `cannot find 'DiceEntropy' in scope`.

- [ ] **Step 3: `DiceEntropy.swift` schreiben**

```swift
import Foundation

public enum DiceError: Error, Equatable {
    /// Der Wurf lag nicht zwischen 1 und 6.
    case invalidRoll(UInt8)
    /// Es wurde geworfen, obwohl bereits genug Entropie vorliegt.
    case alreadyComplete
}

/// Sammelt Würfelwürfe und macht daraus Entropie — nach dem beim Anlegen
/// gewählten Verfahren.
///
/// Speichert nichts über die Lebensdauer der Instanz hinaus. Das Verfahren wird beim
/// Anlegen festgelegt und kann nicht gewechselt werden: Ein Wechsel mitten im
/// Durchlauf würde aus derselben Wurffolge stillschweigend andere Wörter machen.
public struct DiceEntropy {

    /// Zielgröße der Entropie in Bit. 256 Bit ergeben 24 Wörter.
    public static let targetEntropyBits = 256

    /// Feste Wurfzahl für Verfahren B.
    public static let rollsForHashedMethod = 99

    public let method: DiceMethod
    public private(set) var rolls: [UInt8] = []

    public init(method: DiceMethod) {
        self.method = method
    }

    /// Nimmt einen Wurf entgegen. Wirft, wenn der Wert ungültig oder bereits genug
    /// gewürfelt ist.
    public mutating func append(_ roll: UInt8) throws {
        guard (1...6).contains(roll) else { throw DiceError.invalidRoll(roll) }
        guard !isComplete else { throw DiceError.alreadyComplete }
        rolls.append(roll)
    }

    /// Nimmt den letzten Wurf zurück. Auf einem leeren Puffer wirkungslos.
    public mutating func undo() {
        if !rolls.isEmpty {
            rolls.removeLast()
        }
    }

    /// **Vorläufig.** Task 6 ersetzt das durch die verfahrensabhängige Regel.
    /// `append` braucht die Abfrage schon jetzt, damit die Signatur später gleich
    /// bleibt.
    public var isComplete: Bool { false }
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS. Die Abschlussregel ist noch die Attrappe aus Step 3 — sie wird in
Task 6 ersetzt, und die Tests dafür entstehen dort.

- [ ] **Step 5: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/DiceEntropy.swift Tests/Pips39CoreTests/DiceEntropyBufferTests.swift
git commit -m "feat: Wurfpuffer mit Rückgängig und Wertprüfung"
git push
```

---

### Task 6: Fortschritt und Abschluss — je Verfahren verschieden

**Files:**
- Modify: `Sources/Pips39Core/DiceEntropy.swift`
- Create: `Tests/Pips39CoreTests/DiceEntropyProgressTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/DiceEntropyProgressTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class DiceEntropyProgressTests: XCTestCase {

    private func filled(_ method: DiceMethod, with roll: UInt8, count: Int) throws -> DiceEntropy {
        var buffer = DiceEntropy(method: method)
        for _ in 0..<count {
            try buffer.append(roll)
        }
        return buffer
    }

    // MARK: Verfahren B — Würfe zählen

    func testHashedProgressCountsRolls() throws {
        let buffer = try filled(.sha256, with: 1, count: 37)
        XCTAssertEqual(buffer.progress, .rolls(done: 37, needed: 99))
    }

    func testHashedIsCompleteAfterExactly99Rolls() throws {
        let buffer = try filled(.sha256, with: 1, count: 99)
        XCTAssertTrue(buffer.isComplete)
        XCTAssertEqual(buffer.progress, .rolls(done: 99, needed: 99))
    }

    func testHashedRefusesRollNumber100() throws {
        var buffer = try filled(.sha256, with: 1, count: 99)
        XCTAssertThrowsError(try buffer.append(1)) { error in
            XCTAssertEqual(error as? DiceError, .alreadyComplete)
        }
        XCTAssertEqual(buffer.rolls.count, 99)
    }

    // MARK: Verfahren A — Bits zählen

    func testColemanProgressCountsBitsNotRolls() throws {
        // Zehn Einsen liefern je zwei Bit.
        let buffer = try filled(.coleman, with: 1, count: 10)
        XCTAssertEqual(buffer.progress, .bits(done: 20, needed: 256))
    }

    func testColemanCountsOneBitFacesAsOne() throws {
        // Zehn Vieren liefern je ein Bit.
        let buffer = try filled(.coleman, with: 4, count: 10)
        XCTAssertEqual(buffer.progress, .bits(done: 10, needed: 256))
    }

    func testColemanCompletesAt128RollsOfTwoBitFaces() throws {
        let buffer = try filled(.coleman, with: 1, count: 128)
        XCTAssertEqual(buffer.progress, .bits(done: 256, needed: 256))
        XCTAssertTrue(buffer.isComplete)
    }

    func testColemanNotCompleteOneRollEarlier() throws {
        let buffer = try filled(.coleman, with: 1, count: 127)
        XCTAssertFalse(buffer.isComplete)
    }

    func testColemanNeeds256RollsOfOneBitFaces() throws {
        let buffer = try filled(.coleman, with: 4, count: 256)
        XCTAssertTrue(buffer.isComplete)
    }

    func testColemanMayOvershootByOneBit() throws {
        // 127 Einsen = 254 Bit, dann eine 1 -> 256, aber mit einer 4 davor: 255 -> 257
        var buffer = try filled(.coleman, with: 1, count: 127)
        try buffer.append(4)              // 255 Bit, noch nicht fertig
        XCTAssertFalse(buffer.isComplete)
        try buffer.append(1)              // 257 Bit
        XCTAssertTrue(buffer.isComplete)
        XCTAssertEqual(buffer.progress, .bits(done: 257, needed: 256))
    }

    func testColemanRefusesFurtherRollsWhenComplete() throws {
        var buffer = try filled(.coleman, with: 1, count: 128)
        XCTAssertThrowsError(try buffer.append(1)) { error in
            XCTAssertEqual(error as? DiceError, .alreadyComplete)
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `cannot find 'DiceProgress' in scope`.

- [ ] **Step 3: `DiceEntropy.swift` erweitern**

Die vorläufige `isComplete`-Konstante aus Task 5 **löschen** und stattdessen vor der
schließenden Klammer von `public struct DiceEntropy` einfügen:

```swift
    /// Wie viele Rohbits die bisherigen Würfe unter Verfahren A ergeben.
    /// Unter Verfahren B ohne Bedeutung.
    public var rawBitCount: Int {
        ColemanEncoding.rawBits(for: rolls).count
    }

    /// Der Fortschritt, in der Einheit, die zum Verfahren passt.
    public var progress: DiceProgress {
        switch method {
        case .sha256:
            return .rolls(done: rolls.count, needed: Self.rollsForHashedMethod)
        case .coleman:
            return .bits(done: rawBitCount, needed: Self.targetEntropyBits)
        }
    }

    /// Ob genug gewürfelt wurde. Weitere Würfe werden danach abgelehnt — unter
    /// Verfahren A würden sie die Nachrechenbarkeit bei Coleman zerstören, weil er
    /// die längere Folge anders kürzt.
    public var isComplete: Bool {
        switch method {
        case .sha256:
            return rolls.count >= Self.rollsForHashedMethod
        case .coleman:
            return rawBitCount >= Self.targetEntropyBits
        }
    }
```

Und als neuen Typ ans Ende der Datei, außerhalb von `DiceEntropy`:

```swift
/// Fortschritt beim Würfeln. Die Einheit hängt am Verfahren: Verfahren B hat eine
/// feste Wurfzahl, Verfahren A nicht — dort liefert jeder Wurf ein oder zwei Bit.
public enum DiceProgress: Equatable {
    /// Verfahren B: „37 von 99 Würfen".
    case rolls(done: Int, needed: Int)
    /// Verfahren A: „164 von 256 Bit". Es gibt keine verlässliche Restdauer.
    case bits(done: Int, needed: Int)
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/DiceEntropy.swift Tests/Pips39CoreTests/DiceEntropyProgressTests.swift
git commit -m "feat: Fortschritt in Würfen oder Bits, je nach Verfahren"
git push
```

---

### Task 7: Entropie ausliefern — beide Verfahren durchgehend

**Files:**
- Modify: `Sources/Pips39Core/DiceEntropy.swift`
- Create: `Tests/Pips39CoreTests/DiceEntropyResultTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/DiceEntropyResultTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class DiceEntropyResultTests: XCTestCase {

    private func filled(_ method: DiceMethod, with text: String) throws -> DiceEntropy {
        var buffer = DiceEntropy(method: method)
        for character in text {
            guard let value = character.wholeNumberValue else { continue }
            try buffer.append(UInt8(value))
        }
        return buffer
    }

    func testNoEntropyBeforeComplete() throws {
        let buffer = try filled(.sha256, with: String(repeating: "1", count: 98))
        XCTAssertNil(buffer.entropy())
    }

    func testHashedEntropyIs32Bytes() throws {
        let buffer = try filled(.sha256, with: String(repeating: "1", count: 99))
        let entropy = try XCTUnwrap(buffer.entropy())
        XCTAssertEqual(entropy.bytes.count, 32)
    }

    func testHashedProducesExpectedMnemonic() throws {
        let buffer = try filled(.sha256, with: String(repeating: "1", count: 99))
        let entropy = try XCTUnwrap(buffer.entropy())
        let words = try BIP39.mnemonic(from: entropy.bytes)
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(words.joined(separator: " "),
                       "wheel erase puppy pistol chapter accuse carpet drop quote final attend near scrap satisfy limit style crunch person south inspire lunch meadow enact tattoo")
    }

    func testColemanEntropyIsExactly32Bytes() throws {
        let buffer = try filled(.coleman, with: String(repeating: "1", count: 128))
        let entropy = try XCTUnwrap(buffer.entropy())
        XCTAssertEqual(entropy.bytes.count, 32)
    }

    func testColemanProducesTwentyFourValidWords() throws {
        let buffer = try filled(.coleman, with: String(repeating: "1", count: 128))
        let entropy = try XCTUnwrap(buffer.entropy())
        let words = try BIP39.mnemonic(from: entropy.bytes)
        XCTAssertEqual(words.count, 24)
        XCTAssertTrue(BIP39.isValid(mnemonic: words))
    }

    /// Der Kern der Sache: die beiden Verfahren liefern verschiedene Entropie.
    ///
    /// Ein Vergleich bei *identischer* Wurffolge ist nicht möglich — Verfahren B ist
    /// nach 99 Würfen fertig, Verfahren A braucht bei lauter Einsen 128. Genau
    /// deshalb muss das Verfahren neben dem Ergebnis stehen (Spec 2.1).
    func testMethodsProduceDifferentEntropy() throws {
        let hashed = try filled(.sha256, with: String(repeating: "1", count: 99))
        let coleman = try filled(.coleman, with: String(repeating: "1", count: 128))

        let a = try XCTUnwrap(coleman.entropy()).bytes
        let b = try XCTUnwrap(hashed.entropy()).bytes
        XCTAssertNotEqual(a, b, "Beide Verfahren dürfen nicht dasselbe liefern")
    }

    func testWipeClearsTheResult() throws {
        let buffer = try filled(.sha256, with: String(repeating: "1", count: 99))
        var entropy = try XCTUnwrap(buffer.entropy())
        entropy.wipe()
        XCTAssertEqual(entropy.bytes, [UInt8](repeating: 0, count: 32))
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `value of type 'DiceEntropy' has no member 'entropy'`.

- [ ] **Step 3: `DiceEntropy.swift` erweitern**

Vor der schließenden Klammer von `public struct DiceEntropy` einfügen:

```swift
    /// Die fertige Entropie, oder `nil` solange nicht genug gewürfelt wurde.
    ///
    /// Immer 32 Byte. Unter Verfahren A werden dazu die vordersten überzähligen
    /// Rohbits verworfen, genau wie bei Coleman.
    public func entropy() -> SecretBytes? {
        guard isComplete else { return nil }
        switch method {
        case .sha256:
            return SecretBytes(HashedEncoding.entropy(from: rolls))
        case .coleman:
            return SecretBytes(ColemanEncoding.entropy(from: rolls))
        }
    }
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS, alle Tests aus Phase 1 und 2.

- [ ] **Step 5: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/DiceEntropy.swift Tests/Pips39CoreTests/DiceEntropyResultTests.swift
git commit -m "feat: DiceEntropy liefert Entropie nach beiden Verfahren"
git push
```

---

## Abschluss der Phase

- [ ] **Alle Tests grün**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test
```

- [ ] **Spec nachziehen:** In `würfel-tool-spec.md` Abschnitt 4 die Bausteintabelle um
      `DiceEntropy`, `ColemanEncoding` und `HashedEncoding` als **fertig** ergänzen,
      und in Abschnitt 9 die beiden offenen Testpunkte abhaken.

- [ ] **Ein Punkt für die spätere UI, hier nur festhalten:** Unter Verfahren A muss der
      Nachrechnen-Bereich sagen, dass **genau die angezeigte Folge** bei Coleman
      einzugeben ist. Werden Würfe angehängt, kürzt Coleman anders und liefert andere
      Wörter — bei mehr als 287 Rohbits sogar mehr als 24 Wörter, ohne Warnung.

## Was danach kommt (nicht Teil dieses Plans)

- **Phase 3:** iOS-App-Target auf iOS 16 senken, mit `Pips39Core` verdrahten,
  Würfeleingabe und Wortanzeige
- **Phase 4:** BIP39-Tastatur und Abschreibkontrolle als UI
- **Phase 5:** `EnvironmentProbe`, Nachrechnen-Bereich, Erklärseite, Geräte-Checkliste
