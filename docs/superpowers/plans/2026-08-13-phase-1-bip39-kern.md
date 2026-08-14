# Pips39 — Phase 1: Fundament und BIP39-Kern — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein getestetes Swift-Paket `Pips39Core`, das aus roher Entropie gültige BIP39-Mnemonics erzeugt und eingegebene Mnemonics validiert — geprüft gegen die offiziellen BIP39-Testvektoren.

**Architecture:** Der Kern liegt als **Swift Package** (`Pips39Core`) ohne UIKit/SwiftUI vor und ist per `swift test` auf der Kommandozeile prüfbar, ohne Simulator und ohne Xcode-Testtarget. Die iOS-App kommt in einer späteren Phase als eigenes Target obendrauf und hängt vom Paket ab. Diese Trennung ist bewusst gewählt: Sie umgeht die bekannte Falle, dass Test-Targets mit zu hohem Deployment-Target den Testlauf stumm abbrechen lassen (siehe globale CLAUDE.md), und sie macht den sicherheitskritischen Teil unabhängig von jeder UI überprüfbar.

**Tech Stack:** Swift 5.9, SwiftPM, CryptoKit (SHA-256), XCTest. Deployment-Targets `.iOS(.v16)` und `.macOS(.v13)`.

**Spec:** `das Spec (liegt im privaten Vault, nicht im Repo)`

**Nicht in dieser Phase:** `DiceEntropy` (blockiert, siehe Task 8), BIP39-Tastatur, Umgebungsprüfung, jegliche UI.

---

## Wichtige Vorentscheidung: SHA-256 kommt aus CryptoKit

Das Konzept sagt „kein externes Framework für Krypto-Primitiven — alles selbst implementiert und auditierbar". Dieser Plan weicht bei SHA-256 bewusst ab und nimmt Apples CryptoKit.

**Begründung:** Die Prüfsumme schützt kein Geheimnis, sie erkennt Tippfehler. Eine falsche SHA-256-Implementierung fällt sofort bei den offiziellen BIP39-Vektoren durch — sie kann nicht stillschweigend etwas Schwaches erzeugen. Eine handgeschriebene SHA-256 fügt also Fehlerfläche hinzu, ohne echte Prüfbarkeit zu gewinnen: dem Compiler und dem Betriebssystem muss man ohnehin vertrauen. CryptoKit ist Apples eigenes, kein fremdes Framework — der Grundsatz zielte auf Dritt-Abhängigkeiten.

**Falls diese Abwägung anders entschieden wird,** ist nur Task 3 betroffen; alles Weitere bleibt unverändert.

---

### Task 1: Repo, Paket, Grundgerüst

**Files:**
- Create: `.gitignore`
- Create: `Package.swift`
- Create: `README.md`
- Create: `Sources/Pips39Core/Placeholder.swift`
- Create: `Tests/Pips39CoreTests/SmokeTests.swift`

- [ ] **Step 1: Git-Repo anlegen**

```bash
cd "$REPO"
git init
git symbolic-ref HEAD refs/heads/main
```

- [ ] **Step 2: `.gitignore` schreiben**

```gitignore
.DS_Store
/.build
/Packages
xcuserdata/
DerivedData/
.swiftpm/
*.xcodeproj/project.xcworkspace/xcuserdata/
```

- [ ] **Step 3: `Package.swift` schreiben**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pips39Core",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "Pips39Core", targets: ["Pips39Core"])
    ],
    targets: [
        .target(
            name: "Pips39Core",
            resources: [.copy("Resources/english.txt")]
        ),
        .testTarget(
            name: "Pips39CoreTests",
            dependencies: ["Pips39Core"],
            resources: [.copy("Resources/vectors.json")]
        )
    ]
)
```

- [ ] **Step 4: Platzhalter-Quelle und Rauchtest schreiben**

`Sources/Pips39Core/Placeholder.swift`:

```swift
/// Wird in Task 2 durch die Wortliste ersetzt.
enum Pips39CorePlaceholder {
    static let ready = true
}
```

`Tests/Pips39CoreTests/SmokeTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class SmokeTests: XCTestCase {
    func testPackageBuilds() {
        XCTAssertTrue(Pips39CorePlaceholder.ready)
    }
}
```

- [ ] **Step 5: Leere Ressourcenordner anlegen, damit `Package.swift` auflöst**

```bash
cd "$REPO"
mkdir -p Sources/Pips39Core/Resources Tests/Pips39CoreTests/Resources
touch Sources/Pips39Core/Resources/english.txt Tests/Pips39CoreTests/Resources/vectors.json
```

- [ ] **Step 6: `README.md` schreiben**

```markdown
# Pips39

Ein Rechner, der aus Würfelwürfen einen BIP39-Seed macht und beim korrekten
Abschreiben hilft. Keine Wallet: es wird nichts gespeichert, keine Adresse
abgeleitet, keine Transaktion signiert.

## Aufbau

- `Sources/Pips39Core` — Kernlogik ohne UI, per `swift test` prüfbar
- Die iOS-App kommt in einer späteren Phase als eigenes Target dazu

## Tests

    swift test

## Lizenz

MIT
```

- [ ] **Step 7: Bauen und Test laufen lassen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: PASS, ein Test (`testPackageBuilds`).

- [ ] **Step 8: Commit**

```bash
cd "$REPO"
git add -A
git commit -m "chore: Swift-Paket Pips39Core mit Grundgerüst angelegt"
```

- [ ] **Step 9: Remote eintragen und ersten Stand hochladen**

Das Repo besteht bereits unter `https://github.com/a6k/pips39`.

```bash
cd "$REPO"
git remote add origin https://github.com/a6k/pips39.git
git push -u origin main
```

Expected: `branch 'main' set up to track 'origin/main'`.

Falls das Remote-Repo bereits Commits enthält (etwa eine von GitHub angelegte
README oder Lizenz), **nicht** mit `--force` überschreiben, sondern zusammenführen:

```bash
git pull --rebase origin main
git push -u origin main
```

---

### Task 2: Offizielle Wortliste einbetten und ihre Integrität testen

Die Wortliste ist sicherheitsrelevant: ein einziges vertauschtes Wort erzeugt falsche Mnemonics. Sie wird deshalb nicht abgetippt, sondern aus der BIP-Quelle geholt und ihre Eigenschaften werden getestet.

**Files:**
- Modify: `Sources/Pips39Core/Resources/english.txt` (Inhalt ersetzen)
- Create: `Sources/Pips39Core/WordList.swift`
- Create: `Tests/Pips39CoreTests/WordListTests.swift`
- Delete: `Sources/Pips39Core/Placeholder.swift`
- Modify: `Tests/Pips39CoreTests/SmokeTests.swift` (löschen)

- [ ] **Step 1: Wortliste laden und Prüfsumme notieren**

```bash
cd "$REPO"
curl -sL "https://raw.githubusercontent.com/bitcoin/bips/master/bip-0039/english.txt" \
  -o Sources/Pips39Core/Resources/english.txt
wc -l < Sources/Pips39Core/Resources/english.txt
shasum -a 256 Sources/Pips39Core/Resources/english.txt
```

Expected: `2048` Zeilen. Die ausgegebene SHA-256-Summe in die Commit-Message übernehmen, damit später nachvollziehbar ist, welcher Stand eingebettet wurde.

- [ ] **Step 2: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/WordListTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class WordListTests: XCTestCase {

    func testHasExactly2048Words() {
        XCTAssertEqual(WordList.english.count, 2048)
    }

    func testIsSortedAscending() {
        XCTAssertEqual(WordList.english, WordList.english.sorted())
    }

    func testHasNoDuplicates() {
        XCTAssertEqual(Set(WordList.english).count, 2048)
    }

    func testKnownBoundaryWords() {
        XCTAssertEqual(WordList.english.first, "abandon")
        XCTAssertEqual(WordList.english.last, "zoo")
    }

    func testIndexLookupIsConsistent() {
        for (index, word) in WordList.english.enumerated() {
            XCTAssertEqual(WordList.index(of: word), index, "Index für \(word) falsch")
        }
    }

    func testUnknownWordHasNoIndex() {
        XCTAssertNil(WordList.index(of: "nichtimwortschatz"))
    }
}
```

- [ ] **Step 3: Test laufen lassen, Fehlschlag bestätigen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: FAIL, Compilerfehler `cannot find 'WordList' in scope`.

- [ ] **Step 4: `WordList.swift` schreiben**

```swift
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
```

- [ ] **Step 5: Platzhalter entfernen**

```bash
cd "$REPO"
rm Sources/Pips39Core/Placeholder.swift Tests/Pips39CoreTests/SmokeTests.swift
```

- [ ] **Step 6: Tests laufen lassen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: PASS, sechs Tests in `WordListTests`.

- [ ] **Step 7: Commit**

```bash
cd "$REPO"
git add -A
git commit -m "feat: offizielle BIP39-Wortliste eingebettet und Integrität getestet

Quelle: bitcoin/bips bip-0039/english.txt
SHA-256 der eingebetteten Datei: <hier die Summe aus Task 2 Step 1 einsetzen>"
```

---

### Task 3: Bitfolgen und SHA-256-Prüfsumme

Zwischenschicht, die BIP39 braucht: Bytes in Bits zerlegen, Bits zu 11er-Gruppen bündeln, Prüfsummenbits berechnen. Wird getrennt getestet, weil hier die meisten Vorzeichen- und Reihenfolgefehler passieren.

**Files:**
- Create: `Sources/Pips39Core/BitStream.swift`
- Create: `Tests/Pips39CoreTests/BitStreamTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/BitStreamTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class BitStreamTests: XCTestCase {

    func testBitsFromSingleByteAreMostSignificantFirst() {
        XCTAssertEqual(BitStream.bits(from: [0b1000_0000]),
                       [true, false, false, false, false, false, false, false])
        XCTAssertEqual(BitStream.bits(from: [0b0000_0001]),
                       [false, false, false, false, false, false, false, true])
    }

    func testBitsFromTwoBytesKeepByteOrder() {
        XCTAssertEqual(BitStream.bits(from: [0x00, 0xFF]),
                       Array(repeating: false, count: 8) + Array(repeating: true, count: 8))
    }

    func testGroupsOfElevenSplitsExactly() {
        let bits = Array(repeating: false, count: 22)
        XCTAssertEqual(BitStream.groupsOfEleven(bits), [0, 0])
    }

    func testGroupsOfElevenComputesValue() {
        // 11 Bits, alle gesetzt -> 2047
        let bits = Array(repeating: true, count: 11)
        XCTAssertEqual(BitStream.groupsOfEleven(bits), [2047])
    }

    func testGroupsOfElevenIsBigEndianWithinGroup() {
        // 1000 0000 000 -> 1024
        var bits = Array(repeating: false, count: 11)
        bits[0] = true
        XCTAssertEqual(BitStream.groupsOfEleven(bits), [1024])
    }

    func testChecksumBitsForKnownEntropy() {
        // SHA-256 über 16 Nullbytes beginnt mit 0x37 = 0011 0111.
        // Bei 128 Bit Entropie sind 128/32 = 4 Prüfsummenbits zu nehmen: 0011.
        let entropy = [UInt8](repeating: 0x00, count: 16)
        XCTAssertEqual(BitStream.checksumBits(for: entropy, count: 4),
                       [false, false, true, true])
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: FAIL, Compilerfehler `cannot find 'BitStream' in scope`.

- [ ] **Step 3: `BitStream.swift` schreiben**

```swift
import Foundation
import CryptoKit

/// Bit-Werkzeuge für BIP39. Bewusst frei von Zustand und ohne Kenntnis der Wortliste.
enum BitStream {

    /// Zerlegt Bytes in Bits, höchstwertiges Bit zuerst.
    static func bits(from bytes: [UInt8]) -> [Bool] {
        var result = [Bool]()
        result.reserveCapacity(bytes.count * 8)
        for byte in bytes {
            for shift in stride(from: 7, through: 0, by: -1) {
                result.append((byte >> shift) & 1 == 1)
            }
        }
        return result
    }

    /// Bündelt Bits zu 11-Bit-Werten. Die Bitanzahl muss durch 11 teilbar sein.
    static func groupsOfEleven(_ bits: [Bool]) -> [Int] {
        precondition(bits.count % 11 == 0, "Bitanzahl \(bits.count) ist nicht durch 11 teilbar")
        var result = [Int]()
        result.reserveCapacity(bits.count / 11)
        var index = bits.startIndex
        while index < bits.endIndex {
            var value = 0
            for offset in 0..<11 {
                value = (value << 1) | (bits[index + offset] ? 1 : 0)
            }
            result.append(value)
            index += 11
        }
        return result
    }

    /// Die ersten `count` Bits des SHA-256 über die Entropie.
    static func checksumBits(for entropy: [UInt8], count: Int) -> [Bool] {
        let digest = SHA256.hash(data: Data(entropy))
        return Array(bits(from: Array(digest)).prefix(count))
    }
}
```

- [ ] **Step 4: Tests laufen lassen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: PASS, alle Tests in `BitStreamTests` und `WordListTests`.

Der erwartete Wert in `testChecksumBitsForKnownEntropy` ist verifiziert:
`SHA-256(16 × 0x00) = 374708ff…`, erstes Byte `0x37` = `00110111`, die ersten vier
Bits sind also `0011`. Gegenprobe:

```bash
python3 -c "import hashlib;print(hashlib.sha256(bytes(16)).hexdigest()[:2])"
```
Expected: `37`

Das passt zum bekannten Vektor aus Task 4: Bei 128 Nullbits ist die letzte
11-Bit-Gruppe `00000000011` = 3, und das Wort mit Index 3 ist „about".

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add -A
git commit -m "feat: Bitzerlegung, 11-Bit-Gruppierung und SHA-256-Prüfsummenbits"
```

---

### Task 4: Entropie → Mnemonic, geprüft an bekannten Vektoren

**Files:**
- Create: `Sources/Pips39Core/BIP39.swift`
- Create: `Tests/Pips39CoreTests/BIP39GenerationTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/BIP39GenerationTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class BIP39GenerationTests: XCTestCase {

    private func entropy(_ hex: String) -> [UInt8] {
        var bytes = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            bytes.append(UInt8(hex[index..<next], radix: 16)!)
            index = next
        }
        return bytes
    }

    func testTwelveWordsAllZeroEntropy() throws {
        let words = try BIP39.mnemonic(from: entropy("00000000000000000000000000000000"))
        XCTAssertEqual(words.count, 12)
        XCTAssertEqual(words.joined(separator: " "),
                       "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")
    }

    func testTwelveWordsAllOnesEntropy() throws {
        let words = try BIP39.mnemonic(from: entropy("ffffffffffffffffffffffffffffffff"))
        XCTAssertEqual(words.joined(separator: " "),
                       "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong")
    }

    func testTwentyFourWordsAllZeroEntropy() throws {
        let words = try BIP39.mnemonic(
            from: entropy("0000000000000000000000000000000000000000000000000000000000000000"))
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(words.last, "art")
        XCTAssertEqual(Set(words.dropLast()), ["abandon"])
    }

    func testTwentyFourWordsAllOnesEntropy() throws {
        let words = try BIP39.mnemonic(
            from: entropy("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(words.last, "vote")
        XCTAssertEqual(Set(words.dropLast()), ["zoo"])
    }

    func testRejectsEntropyOfWrongLength() {
        XCTAssertThrowsError(try BIP39.mnemonic(from: [UInt8](repeating: 0, count: 15))) { error in
            XCTAssertEqual(error as? BIP39Error, .invalidEntropyLength(120))
        }
    }

    func testRejectsEmptyEntropy() {
        XCTAssertThrowsError(try BIP39.mnemonic(from: [])) { error in
            XCTAssertEqual(error as? BIP39Error, .invalidEntropyLength(0))
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: FAIL, Compilerfehler `cannot find 'BIP39' in scope`.

- [ ] **Step 3: `BIP39.swift` schreiben**

```swift
import Foundation

public enum BIP39Error: Error, Equatable {
    /// Entropie hat nicht 128, 160, 192, 224 oder 256 Bit. Der Wert ist die tatsächliche Bitzahl.
    case invalidEntropyLength(Int)
}

/// Umsetzung von BIP39, Teil „Entropie → Mnemonic".
///
/// Nicht enthalten: die Ableitung des 512-Bit-Seeds per PBKDF2. Die macht die Wallet,
/// nicht dieses Werkzeug.
public enum BIP39 {

    /// Erlaubte Entropiegrößen in Bit, nach BIP39.
    public static let allowedEntropyBits = [128, 160, 192, 224, 256]

    /// Erzeugt die Mnemonic-Wörter zu einer gegebenen Entropie.
    public static func mnemonic(from entropy: [UInt8]) throws -> [String] {
        let entropyBits = entropy.count * 8
        guard allowedEntropyBits.contains(entropyBits) else {
            throw BIP39Error.invalidEntropyLength(entropyBits)
        }

        let checksumLength = entropyBits / 32
        let allBits = BitStream.bits(from: entropy)
            + BitStream.checksumBits(for: entropy, count: checksumLength)

        return BitStream.groupsOfEleven(allBits).map { WordList.english[$0] }
    }
}
```

- [ ] **Step 4: Tests laufen lassen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: PASS, alle Tests.

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add -A
git commit -m "feat: Entropie zu BIP39-Mnemonic, geprüft an bekannten Vektoren"
```

---

### Task 5: Vollständige offizielle Testvektoren

Die vier Vektoren aus Task 4 sind Handarbeit und könnten falsch abgeschrieben sein. Hier kommt die normative Datei dazu, alle Vektoren auf einmal.

**Files:**
- Modify: `Tests/Pips39CoreTests/Resources/vectors.json` (Inhalt ersetzen)
- Create: `Tests/Pips39CoreTests/OfficialVectorTests.swift`

- [ ] **Step 1: Offizielle Vektoren laden**

```bash
cd "$REPO"
curl -sL "https://raw.githubusercontent.com/trezor/python-mnemonic/master/vectors.json" \
  -o Tests/Pips39CoreTests/Resources/vectors.json
python3 -c "import json;d=json.load(open('Tests/Pips39CoreTests/Resources/vectors.json'));print(len(d['english']),'Vektoren')"
shasum -a 256 Tests/Pips39CoreTests/Resources/vectors.json
```

Expected: eine zweistellige Anzahl Vektoren (die Datei enthält üblicherweise 24 englische Einträge). Jeder Eintrag ist ein Array, dessen erstes Element die Entropie als Hex und dessen zweites Element die Mnemonic ist.

- [ ] **Step 2: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/OfficialVectorTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class OfficialVectorTests: XCTestCase {

    private struct VectorFile: Decodable {
        let english: [[String]]
    }

    private func loadVectors() throws -> [(entropyHex: String, mnemonic: String)] {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "vectors", withExtension: "json"),
            "vectors.json fehlt im Test-Bundle"
        )
        let file = try JSONDecoder().decode(VectorFile.self, from: Data(contentsOf: url))
        return file.english.map { (entropyHex: $0[0], mnemonic: $0[1]) }
    }

    private func bytes(fromHex hex: String) -> [UInt8] {
        var result = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            result.append(UInt8(hex[index..<next], radix: 16)!)
            index = next
        }
        return result
    }

    func testVectorFileIsNotEmpty() throws {
        XCTAssertGreaterThan(try loadVectors().count, 10)
    }

    func testAllOfficialVectorsProduceExpectedMnemonic() throws {
        for vector in try loadVectors() {
            let produced = try BIP39.mnemonic(from: bytes(fromHex: vector.entropyHex))
            XCTAssertEqual(produced.joined(separator: " "), vector.mnemonic,
                           "Abweichung bei Entropie \(vector.entropyHex)")
        }
    }

    func testAllOfficialVectorsRoundTripThroughValidation() throws {
        for vector in try loadVectors() {
            let words = vector.mnemonic.split(separator: " ").map(String.init)
            XCTAssertTrue(BIP39.isValid(mnemonic: words),
                          "Offizieller Vektor \(vector.entropyHex) gilt als ungültig")
        }
    }
}
```

Der dritte Test benutzt `BIP39.isValid(mnemonic:)`, das erst in Task 6 entsteht. Das ist beabsichtigt: Task 5 endet mit zwei grünen Tests, der dritte wird in Task 6 grün.

- [ ] **Step 3: Test laufen lassen, Fehlschlag bestätigen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: FAIL, Compilerfehler `type 'BIP39' has no member 'isValid'`.

- [ ] **Step 4: Dritten Test vorübergehend auskommentieren**

Den Rumpf von `testAllOfficialVectorsRoundTripThroughValidation` durch

```swift
        throw XCTSkip("BIP39.isValid entsteht in Task 6")
```

ersetzen, damit Task 5 für sich abschließbar ist.

- [ ] **Step 5: Tests laufen lassen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: PASS, `testAllOfficialVectorsProduceExpectedMnemonic` grün, ein übersprungener Test.

- [ ] **Step 6: Commit**

```bash
cd "$REPO"
git add -A
git commit -m "test: vollständige offizielle BIP39-Vektoren eingebunden"
```

---

### Task 6: Mnemonic validieren — Grundlage der Abschreibkontrolle

Die Abschreibkontrolle aus Spec 2.2 braucht zwei Auskünfte: ist ein eingegebenes Wort überhaupt ein BIP39-Wort, und stimmt die Prüfsumme der gesamten Eingabe.

**Files:**
- Modify: `Sources/Pips39Core/BIP39.swift`
- Create: `Tests/Pips39CoreTests/BIP39ValidationTests.swift`
- Modify: `Tests/Pips39CoreTests/OfficialVectorTests.swift` (XCTSkip aus Task 5 entfernen)

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/BIP39ValidationTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class BIP39ValidationTests: XCTestCase {

    private let validTwelve = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        .split(separator: " ").map(String.init)

    func testAcceptsKnownGoodMnemonic() {
        XCTAssertTrue(BIP39.isValid(mnemonic: validTwelve))
    }

    func testRejectsWrongChecksumWord() {
        var words = validTwelve
        words[11] = "abandon"   // "about" wäre korrekt
        XCTAssertFalse(BIP39.isValid(mnemonic: words))
    }

    func testRejectsUnknownWord() {
        var words = validTwelve
        words[3] = "nichtimwortschatz"
        XCTAssertFalse(BIP39.isValid(mnemonic: words))
    }

    func testRejectsWrongWordCount() {
        XCTAssertFalse(BIP39.isValid(mnemonic: Array(validTwelve.dropLast())))
        XCTAssertFalse(BIP39.isValid(mnemonic: []))
    }

    func testFirstMismatchReportsPosition() {
        var typed = validTwelve
        typed[5] = "zoo"
        XCTAssertEqual(BIP39.firstMismatch(between: validTwelve, and: typed), 5)
    }

    func testFirstMismatchReturnsNilWhenIdentical() {
        XCTAssertNil(BIP39.firstMismatch(between: validTwelve, and: validTwelve))
    }

    func testFirstMismatchReportsLengthDifference() {
        XCTAssertEqual(BIP39.firstMismatch(between: validTwelve,
                                           and: Array(validTwelve.dropLast())), 11)
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: FAIL, `type 'BIP39' has no member 'isValid'`.

- [ ] **Step 3: `BIP39.swift` erweitern**

Folgendes vor der schließenden Klammer von `public enum BIP39` einfügen:

```swift
    /// Erlaubte Wortanzahlen, abgeleitet aus den erlaubten Entropiegrößen.
    public static let allowedWordCounts = allowedEntropyBits.map { ($0 + $0 / 32) / 11 }

    /// Prüft, ob eine Wortfolge eine gültige BIP39-Mnemonic ist — bekannte Wörter,
    /// zulässige Länge und stimmige Prüfsumme.
    public static func isValid(mnemonic words: [String]) -> Bool {
        guard allowedWordCounts.contains(words.count) else { return false }

        var bits = [Bool]()
        bits.reserveCapacity(words.count * 11)
        for word in words {
            guard let index = WordList.index(of: word) else { return false }
            for shift in stride(from: 10, through: 0, by: -1) {
                bits.append((index >> shift) & 1 == 1)
            }
        }

        let entropyBits = words.count * 11 * 32 / 33
        let checksumLength = entropyBits / 32
        let entropy = bytes(fromBits: Array(bits.prefix(entropyBits)))
        let expected = BitStream.checksumBits(for: entropy, count: checksumLength)

        return Array(bits.suffix(checksumLength)) == expected
    }

    /// Position des ersten Unterschieds zwischen erzeugter und abgetippter Wortfolge,
    /// oder `nil` wenn beide gleich sind. Unterschiedliche Längen zählen ab der
    /// ersten fehlenden Position als Abweichung.
    public static func firstMismatch(between expected: [String], and typed: [String]) -> Int? {
        for position in 0..<Swift.min(expected.count, typed.count) where expected[position] != typed[position] {
            return position
        }
        return expected.count == typed.count ? nil : Swift.min(expected.count, typed.count)
    }

    private static func bytes(fromBits bits: [Bool]) -> [UInt8] {
        precondition(bits.count % 8 == 0, "Bitanzahl \(bits.count) ist nicht durch 8 teilbar")
        var result = [UInt8]()
        result.reserveCapacity(bits.count / 8)
        var index = bits.startIndex
        while index < bits.endIndex {
            var byte: UInt8 = 0
            for offset in 0..<8 {
                byte = (byte << 1) | (bits[index + offset] ? 1 : 0)
            }
            result.append(byte)
            index += 8
        }
        return result
    }
```

- [ ] **Step 4: XCTSkip aus Task 5 entfernen**

In `Tests/Pips39CoreTests/OfficialVectorTests.swift` die Zeile

```swift
        throw XCTSkip("BIP39.isValid entsteht in Task 6")
```

löschen und den ursprünglichen Rumpf aus Task 5 Step 2 wiederherstellen:

```swift
        for vector in try loadVectors() {
            let words = vector.mnemonic.split(separator: " ").map(String.init)
            XCTAssertTrue(BIP39.isValid(mnemonic: words),
                          "Offizieller Vektor \(vector.entropyHex) gilt als ungültig")
        }
```

- [ ] **Step 5: Tests laufen lassen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: PASS, keine übersprungenen Tests mehr.

- [ ] **Step 6: Commit**

```bash
cd "$REPO"
git add -A
git commit -m "feat: Mnemonic-Validierung und Positionsvergleich für die Abschreibkontrolle"
```

---

### Task 7: Entropie sicher halten und löschen

Spec Abschnitt 5 verlangt, dass Entropie als `[UInt8]` gehalten und aktiv überschrieben wird. Der Typ macht das explizit, statt es der Aufrufseite zu überlassen.

**Files:**
- Create: `Sources/Pips39Core/SecretBytes.swift`
- Create: `Tests/Pips39CoreTests/SecretBytesTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/SecretBytesTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class SecretBytesTests: XCTestCase {

    func testExposesItsBytes() {
        let secret = SecretBytes([1, 2, 3])
        XCTAssertEqual(secret.bytes, [1, 2, 3])
    }

    func testWipeOverwritesWithZeroes() {
        var secret = SecretBytes([9, 9, 9])
        secret.wipe()
        XCTAssertEqual(secret.bytes, [0, 0, 0])
    }

    func testWipeKeepsLength() {
        var secret = SecretBytes([UInt8](repeating: 7, count: 32))
        secret.wipe()
        XCTAssertEqual(secret.bytes.count, 32)
    }

    func testDescriptionDoesNotLeakContent() {
        let secret = SecretBytes([0xDE, 0xAD, 0xBE, 0xEF])
        XCTAssertEqual(String(describing: secret), "SecretBytes(4 Bytes)")
        XCTAssertFalse(String(describing: secret).contains("222"))
        XCTAssertFalse(String(describing: secret).contains("de"))
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: FAIL, `cannot find 'SecretBytes' in scope`.

- [ ] **Step 3: `SecretBytes.swift` schreiben**

```swift
import Foundation

/// Bytes, die niemals in Logs, Fehlermeldungen oder Debug-Ausgaben auftauchen sollen,
/// und die aktiv überschrieben werden können.
///
/// Das ist Sorgfalt, keine Garantie: Swift gibt keine Zusage darüber, ob der Puffer
/// zwischenzeitlich kopiert oder ausgelagert wurde. Der Typ macht die Absicht sichtbar
/// und verhindert versehentliches Ausgeben — mehr kann er nicht.
public struct SecretBytes: CustomStringConvertible, CustomDebugStringConvertible {

    public private(set) var bytes: [UInt8]

    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    /// Überschreibt den Inhalt mit Nullen, ohne die Länge zu ändern.
    public mutating func wipe() {
        for index in bytes.indices {
            bytes[index] = 0
        }
    }

    public var description: String { "SecretBytes(\(bytes.count) Bytes)" }
    public var debugDescription: String { description }
}
```

- [ ] **Step 4: Tests laufen lassen**

Run:
```bash
cd "$REPO" && swift test
```
Expected: PASS, alle Tests.

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add -A
git commit -m "feat: SecretBytes — Entropie ohne Debug-Ausgabe, aktiv löschbar"
```

---

### Task 8: Colemans Umrechnung ermitteln und einfrieren

**Das ist der einzige echte Blocker des Projekts** (Spec 2.1). Ohne diese Antwort kann `DiceEntropy` nicht geschrieben werden. Diese Aufgabe schreibt keinen Produktivcode — sie erzeugt ein Dokument und eine Vektorendatei, auf denen Phase 2 aufsetzt.

**Files:**
- Create: `docs/coleman-verfahren.md`
- Create: `Tests/Pips39CoreTests/Resources/coleman-vectors.json`

- [ ] **Step 1: Quelltext von Colemans Werkzeug holen**

```bash
cd /tmp
curl -sL "https://raw.githubusercontent.com/iancoleman/bip39/master/src/js/index.js" -o coleman-index.js
wc -l coleman-index.js
grep -n -i "base\|dice\|entropy" coleman-index.js | head -60
```

Ziel ist die Funktion, die Roh-Eingaben in Entropie wandelt (in der Regel in `src/js/entropy.js`). Diese Datei ebenfalls holen:

```bash
curl -sL "https://raw.githubusercontent.com/iancoleman/bip39/master/src/js/entropy.js" -o coleman-entropy.js
```

- [ ] **Step 2: Die vier offenen Fragen aus Spec 2.1 am Quelltext beantworten**

Für jede Frage die Antwort **mit Zeilenangabe aus dem Quelltext belegen**:

1. Wie werden die Ziffern 1–6 auf Basis-6-Werte abgebildet? Wird die 6 auf 0 abgebildet?
2. Wird die Base-6-Zahl als Ganzes in Binär gewandelt, oder Wurf für Wurf?
3. Werden überzählige Bits links oder rechts abgeschnitten?
4. Was passiert bei einer Wurfanzahl, die nicht glatt auf 128/256 Bit führt?

- [ ] **Step 3: `docs/coleman-verfahren.md` schreiben**

Aufbau: je Frage aus Step 2 ein Abschnitt mit Antwort, Zeilenbeleg und dem zitierten Quelltextausschnitt. Am Ende ein Abschnitt „Folgen für `DiceEntropy`" mit der Entscheidung, ob 99 oder 100 Würfe für 256 Bit nötig sind — damit ist der erste offene Punkt aus Spec Abschnitt 11 beantwortet.

- [ ] **Step 4: Vektoren am laufenden Werkzeug erheben**

`https://iancoleman.io/bip39/` im Browser öffnen, Netzwerkverbindung dabei egal (es werden nur Wegwerf-Folgen benutzt). Unter „Entropy" den Typ „Dice" wählen und für jede der folgenden Eingaben die erzeugte Mnemonic und die angezeigte Hex-Entropie notieren:

- `1` (ein einzelner Wurf, Grenzfall)
- `123456`
- `111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111` (99 × 1)
- `666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666` (99 × 6)
- eine gemischte Folge aus 99 Würfen, frei gewürfelt oder ausgedacht — sie muss nur notiert werden

> [!warning] Nur Wegwerf-Folgen verwenden
> Diese Vektoren landen öffentlich im Repo. Niemals eine echte Wurffolge eintragen.

- [ ] **Step 5: `coleman-vectors.json` schreiben**

```json
{
  "quelle": "https://iancoleman.io/bip39/ — Entropy-Typ 'Dice'",
  "erhoben_am": "JJJJ-MM-TT",
  "hinweis": "Ausschließlich Wegwerf-Folgen. Keine dieser Eingaben wurde je für einen echten Seed verwendet.",
  "vektoren": [
    {
      "wuerfe": "123456",
      "entropie_hex": "<aus dem Werkzeug ablesen>",
      "mnemonic": "<aus dem Werkzeug ablesen>"
    }
  ]
}
```

Für jede Eingabe aus Step 4 einen Eintrag anlegen. Die Platzhalter in spitzen Klammern werden durch die tatsächlich abgelesenen Werte ersetzt — es darf am Ende keine spitze Klammer mehr in der Datei stehen.

- [ ] **Step 6: Prüfen, dass die Datei vollständig ist**

```bash
cd "$REPO"
python3 -c "
import json
d = json.load(open('Tests/Pips39CoreTests/Resources/coleman-vectors.json'))
assert len(d['vektoren']) >= 5, 'zu wenige Vektoren'
for v in d['vektoren']:
    assert '<' not in json.dumps(v), f'Platzhalter übrig: {v}'
print(len(d['vektoren']), 'Vektoren vollständig')
"
```
Expected: `5 Vektoren vollständig` oder mehr.

- [ ] **Step 7: Commit**

```bash
cd "$REPO"
git add -A
git commit -m "docs: Colemans Würfel-Umrechnung analysiert und Referenzvektoren erhoben

Beantwortet den Blocker aus Spec 2.1. Grundlage für DiceEntropy in Phase 2."
```

---

## Abschluss der Phase

- [ ] **Alle Tests grün**

```bash
cd "$REPO" && swift test
```

- [ ] **Spec nachziehen:** In `würfel-tool-spec.md` Abschnitt 11 den Punkt „99 oder 100 Würfe" mit dem Ergebnis aus Task 8 schließen.

- [ ] **Phase 2 planen:** `DiceEntropy` auf Basis von `docs/coleman-verfahren.md` und `coleman-vectors.json`.

## Was danach kommt (nicht Teil dieses Plans)

- **Phase 2:** `DiceEntropy` — Ziffernpuffer, Rückgängig, Base-6-Umrechnung, Fortschritt
- **Phase 3:** iOS-App-Target, Würfeleingabe, Wortanzeige, `EnvironmentProbe`
- **Phase 4:** BIP39-Tastatur und Abschreibkontrolle als UI
- **Phase 5:** Nachrechnen-Bereich, Erklärseite, Geräte-Checkliste
