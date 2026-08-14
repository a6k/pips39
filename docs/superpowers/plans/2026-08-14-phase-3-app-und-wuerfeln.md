# Pips39 — Phase 3: App-Target, Würfeln und Wortanzeige — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eine lauffähige App: Verfahren wählen, würfeln, 24 Wörter sehen, verwerfen. Die Wörter sind gegen Hintergrund-Schnappschüsse und Bildschirmaufnahmen geschützt.

**Architecture:** Alles Entscheidbare wandert in `DiceSession` — ein `ObservableObject` **im Swift Package**, das ohne Simulator mit `swift test` prüfbar ist. Die SwiftUI-Ansichten im App-Target bleiben dumm: sie zeigen an und leiten Taps weiter. Damit hängt die Testbarkeit des Projekts nicht an Xcode-UI-Tests, die erfahrungsgemäß die unzuverlässigste Stelle sind.

**Tech Stack:** SwiftUI, Combine (`ObservableObject`), Swift 5.9, Deployment Target iOS 16.0.

**Spec:** `das Spec (liegt im privaten Vault, nicht im Repo)`

**Vorhanden aus Phase 1 und 2:** `WordList`, `BitStream`, `BIP39`, `SecretBytes`, `DiceMethod`, `ColemanEncoding`, `HashedEncoding`, `DiceEntropy`, `DiceProgress`, `DiceError`. 73 Tests grün.

**Nicht in dieser Phase:** BIP39-Tastatur und Abschreibkontrolle (Phase 4), `EnvironmentProbe`, Nachrechnen-Bereich, Erklärseite (Phase 5).

---

## Zwei Festlegungen, die hier zum ersten Mal nötig werden

**Die Oberfläche ist englisch.** Das Spec nennt als Zielgruppe die internationale
Bitcoin-Community; der Name wurde ausdrücklich danach gewählt. Quelltextkommentare
bleiben deutsch wie bisher. Keine Lokalisierungsdateien in dieser Phase — die Texte
stehen als Literale im Code, eine String-Catalog-Umstellung ist später billig.

> [!warning] Diese App warnt in Phase 3 noch nicht vor Netzwerkverbindungen
> `EnvironmentProbe` aus Spec 2.5 kommt erst in Phase 5. Bis dahin gilt: Das ist ein
> Entwicklungsstand im privaten Repo, kein Werkzeug zum Erzeugen echter Seeds. Der
> Bildschirmschutz aus Task 7 ist trotzdem **jetzt** dabei, weil hier zum ersten Mal
> echte Wörter auf dem Schirm stehen — ihn zu vertagen, wäre die falsche Reihenfolge.

---

### Task 1: Projekt auf iOS 16 senken und mit dem Kern verdrahten

Zwei Dinge, die zusammengehören, weil beide nur am Bauergebnis prüfbar sind.

**Files:**
- Modify: `Pips39/Pips39.xcodeproj/project.pbxproj`

- [ ] **Step 1: Ausgangslage festhalten**

```bash
cd "$REPO/Pips39"
grep -c "IPHONEOS_DEPLOYMENT_TARGET = 26.5" Pips39.xcodeproj/project.pbxproj
```
Expected: `4`

- [ ] **Step 2: Deployment Target senken**

```bash
cd "$REPO/Pips39"
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 26\.5;/IPHONEOS_DEPLOYMENT_TARGET = 16.0;/g' Pips39.xcodeproj/project.pbxproj
grep -o "IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*" Pips39.xcodeproj/project.pbxproj | sort | uniq -c
```
Expected: `4 IPHONEOS_DEPLOYMENT_TARGET = 16.0` — und **keine** 26.5 mehr.

Alle vier Konfigurationen müssen umgestellt sein, auch die der Test-Targets. Genau
dort liegt sonst die Falle, bei der Testläufe auf älteren Simulatoren stumm abbrechen.

- [ ] **Step 3: `Pips39Core` als lokale Paketabhängigkeit eintragen**

Das Projekt hat `objectVersion = 77`, unterstützt also `XCLocalSwiftPackageReference`.
Das Paket liegt eine Ebene höher; der relative Pfad ist `..`.

Fünf Einfügungen sind nötig. Das folgende Skript macht sie deterministisch und bricht
ab, sobald ein Anker nicht genau einmal vorkommt — es hinterlässt in dem Fall keine
halb bearbeitete Datei.

```bash
cd "$REPO/Pips39"
cp Pips39.xcodeproj/project.pbxproj /tmp/pbxproj.bak
python3 - <<'PY'
import sys

PATH = "Pips39.xcodeproj/project.pbxproj"
BUILD_FILE = "AA11111111111111111111AA"
PRODUCT    = "AA22222222222222222222AA"
PACKAGE    = "AA33333333333333333333AA"
APP_FRAMEWORKS = "D76D6B54302E6C0800EFAECE"

text = open(PATH, encoding="utf-8").read()
if "XCLocalSwiftPackageReference" in text:
    sys.exit("Paketreferenz ist bereits eingetragen — nichts zu tun.")

def sub_once(old, new, what):
    global text
    if text.count(old) != 1:
        sys.exit(f"Anker '{what}' kommt {text.count(old)}x vor, erwartet genau 1x. Abbruch.")
    text = text.replace(old, new)

# 1) PBXBuildFile-Abschnitt anlegen
sub_once(
    "/* Begin PBXContainerItemProxy section */",
    "/* Begin PBXBuildFile section */\n"
    f"\t\t{BUILD_FILE} /* Pips39Core in Frameworks */ = "
    f"{{isa = PBXBuildFile; productRef = {PRODUCT} /* Pips39Core */; }};\n"
    "/* End PBXBuildFile section */\n\n"
    "/* Begin PBXContainerItemProxy section */",
    "PBXBuildFile-Abschnitt")

# 2) In die Frameworks-Phase des App-Targets eintragen
old_phase = (f"\t\t{APP_FRAMEWORKS} /* Frameworks */ = {{\n"
             "\t\t\tisa = PBXFrameworksBuildPhase;\n"
             "\t\t\tbuildActionMask = 2147483647;\n"
             "\t\t\tfiles = (\n"
             "\t\t\t);")
new_phase = (f"\t\t{APP_FRAMEWORKS} /* Frameworks */ = {{\n"
             "\t\t\tisa = PBXFrameworksBuildPhase;\n"
             "\t\t\tbuildActionMask = 2147483647;\n"
             "\t\t\tfiles = (\n"
             f"\t\t\t\t{BUILD_FILE} /* Pips39Core in Frameworks */,\n"
             "\t\t\t);")
sub_once(old_phase, new_phase, "Frameworks-Phase des App-Targets")

# 3) packageProductDependencies am App-Target
sub_once(
    "\t\t\tpackageProductDependencies = (\n\t\t\t);",
    "\t\t\tpackageProductDependencies = (\n"
    f"\t\t\t\t{PRODUCT} /* Pips39Core */,\n"
    "\t\t\t);",
    "packageProductDependencies")

# 4) packageReferences am Projekt
sub_once(
    "\t\t\ttargets = (\n",
    "\t\t\tpackageReferences = (\n"
    f"\t\t\t\t{PACKAGE} /* XCLocalSwiftPackageReference \"..\" */,\n"
    "\t\t\t);\n"
    "\t\t\ttargets = (\n",
    "targets-Liste des Projekts")

# 5) Die beiden neuen Abschnitte ans Ende der objects-Liste
sub_once(
    "\t};\n\trootObject = ",
    "\n/* Begin XCLocalSwiftPackageReference section */\n"
    f"\t\t{PACKAGE} /* XCLocalSwiftPackageReference \"..\" */ = {{\n"
    "\t\t\tisa = XCLocalSwiftPackageReference;\n"
    "\t\t\trelativePath = ..;\n"
    "\t\t};\n"
    "/* End XCLocalSwiftPackageReference section */\n\n"
    "/* Begin XCSwiftPackageProductDependency section */\n"
    f"\t\t{PRODUCT} /* Pips39Core */ = {{\n"
    "\t\t\tisa = XCSwiftPackageProductDependency;\n"
    "\t\t\tproductName = Pips39Core;\n"
    "\t\t};\n"
    "/* End XCSwiftPackageProductDependency section */\n"
    "\t};\n\trootObject = ",
    "Ende der objects-Liste")

open(PATH, "w", encoding="utf-8").write(text)
print("Paketreferenz eingetragen.")
PY
```

Danach prüfen, dass Xcode die Datei noch lesen kann:

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -list 2>&1 | head -20
```
Expected: die drei Targets `Pips39`, `Pips39Tests`, `Pips39UITests` und das Schema `Pips39`.

> [!warning] Wenn das Skript abbricht oder der Build danach scheitert
> Zurückrollen mit `cp /tmp/pbxproj.bak Pips39.xcodeproj/project.pbxproj` und
> **BLOCKED melden**. Der Nutzer erledigt es dann in Xcode in einer halben Minute über
> *File → Add Package Dependencies… → Add Local…* und wählt den Repo-Ordner. Das ist
> kein Scheitern, sondern die schnellere Route — eine kaputte `project.pbxproj` kostet
> deutlich mehr Zeit als dieser Handgriff. Nicht mehr als zwei Versuche.

- [ ] **Step 4: Import beweisen**

In `Pips39/Pips39/ContentView.swift` den Rumpf vorläufig ersetzen:

```swift
import SwiftUI
import Pips39Core

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Pips39")
                .font(.largeTitle.bold())
            Text("\(WordList.english.count) BIP39 words loaded")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 5: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`

Schlägt der Build mit `no such module 'Pips39Core'` fehl, ist Step 3 nicht vollständig
— siehe die Warnung dort.

- [ ] **Step 6: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39.xcodeproj/project.pbxproj Pips39/Pips39/ContentView.swift
git commit -m "chore: App-Target auf iOS 16 gesenkt und mit Pips39Core verdrahtet"
git push
```

---

### Task 2: `DiceSession` — das testbare Modell

Hier liegt die gesamte Ablauflogik der App, prüfbar ohne Simulator.

**Files:**
- Create: `Sources/Pips39Core/DiceSession.swift`
- Create: `Tests/Pips39CoreTests/DiceSessionTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/DiceSessionTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class DiceSessionTests: XCTestCase {

    private func rolled(_ session: DiceSession, face: UInt8, times: Int) {
        for _ in 0..<times {
            session.roll(face)
        }
    }

    func testStartsEmptyAndNotComplete() {
        let session = DiceSession(method: .sha256)
        XCTAssertEqual(session.rollCount, 0)
        XCTAssertFalse(session.isComplete)
        XCTAssertFalse(session.canUndo)
        XCTAssertTrue(session.words.isEmpty)
    }

    func testRollingCountsUp() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 3, times: 5)
        XCTAssertEqual(session.rollCount, 5)
        XCTAssertTrue(session.canUndo)
    }

    func testInvalidFaceIsIgnored() {
        let session = DiceSession(method: .sha256)
        session.roll(0)
        session.roll(7)
        XCTAssertEqual(session.rollCount, 0)
    }

    func testUndoStepsBack() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 3, times: 2)
        session.undo()
        XCTAssertEqual(session.rollCount, 1)
    }

    func testRollsBeyondCompletionAreIgnored() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 120)
        XCTAssertEqual(session.rollCount, 99)
        XCTAssertTrue(session.isComplete)
    }

    func testProgressFollowsMethodForHashed() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 10)
        XCTAssertEqual(session.progress, .rolls(done: 10, needed: 99))
    }

    func testProgressFollowsMethodForColeman() {
        let session = DiceSession(method: .coleman)
        rolled(session, face: 1, times: 10)
        XCTAssertEqual(session.progress, .bits(done: 20, needed: 256))
    }

    // MARK: Aufdecken und Verwerfen

    func testRevealDoesNothingBeforeCompletion() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 98)
        session.reveal()
        XCTAssertTrue(session.words.isEmpty)
    }

    func testRevealProducesTwentyFourWords() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 99)
        session.reveal()
        XCTAssertEqual(session.words.count, 24)
        XCTAssertEqual(session.words.joined(separator: " "),
                       "wheel erase puppy pistol chapter accuse carpet drop quote final attend near scrap satisfy limit style crunch person south inspire lunch meadow enact tattoo")
    }

    func testRevealedWordsAreValid() {
        let session = DiceSession(method: .coleman)
        rolled(session, face: 1, times: 128)
        session.reveal()
        XCTAssertEqual(session.words.count, 24)
        XCTAssertTrue(BIP39.isValid(mnemonic: session.words))
    }

    func testDiscardClearsEverything() {
        let session = DiceSession(method: .sha256)
        rolled(session, face: 1, times: 99)
        session.reveal()
        session.discard()
        XCTAssertTrue(session.words.isEmpty)
        XCTAssertEqual(session.rollCount, 0)
        XCTAssertFalse(session.isComplete)
    }

    /// Die Wurffolge, wie sie der Nachrechnen-Bereich später anzeigt.
    func testRollSequenceIsReadable() {
        let session = DiceSession(method: .sha256)
        session.roll(1)
        session.roll(4)
        session.roll(6)
        XCTAssertEqual(session.rollSequence, "146")
    }

    func testRollSequenceIsEmptyAtStart() {
        XCTAssertEqual(DiceSession(method: .sha256).rollSequence, "")
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "$REPO" && swift test`
Expected: FAIL, `cannot find 'DiceSession' in scope`.

- [ ] **Step 3: `DiceSession.swift` schreiben**

```swift
import Foundation
import Combine

/// Der Ablauf eines Würfel-Durchlaufs, wie die Oberfläche ihn sieht.
///
/// Enthält die gesamte Entscheidungslogik, damit die SwiftUI-Ansichten dumm bleiben
/// und ohne Simulator geprüft werden kann. Das Verfahren wird beim Anlegen gewählt
/// und ist danach unveränderlich — ein Wechsel mitten im Durchlauf würde aus
/// derselben Wurffolge stillschweigend andere Wörter machen.
public final class DiceSession: ObservableObject {

    public let method: DiceMethod

    @Published private var buffer: DiceEntropy
    @Published public private(set) var words: [String] = []

    public init(method: DiceMethod) {
        self.method = method
        self.buffer = DiceEntropy(method: method)
    }

    // MARK: Würfeln

    public var rollCount: Int { buffer.rolls.count }
    public var progress: DiceProgress { buffer.progress }
    public var isComplete: Bool { buffer.isComplete }
    public var canUndo: Bool { !buffer.rolls.isEmpty }

    /// Die Wurffolge als Ziffernkette — das, was der Nutzer notiert hätte.
    public var rollSequence: String {
        buffer.rolls.map(String.init).joined()
    }

    /// Nimmt einen Wurf entgegen. Ungültige Werte und Würfe nach Abschluss werden
    /// stillschweigend übergangen: Die Oberfläche sperrt die Tasten ohnehin, und ein
    /// Fehlerdialog an dieser Stelle hilft niemandem.
    public func roll(_ face: UInt8) {
        try? buffer.append(face)
    }

    /// Nimmt den letzten Wurf zurück.
    public func undo() {
        buffer.undo()
    }

    // MARK: Ergebnis

    /// Berechnet die Wörter, sobald genug gewürfelt wurde. Vorher wirkungslos.
    public func reveal() {
        guard var entropy = buffer.entropy() else { return }
        defer { entropy.wipe() }
        words = (try? BIP39.mnemonic(from: entropy.bytes)) ?? []
    }

    /// Wirft alles weg und beginnt von vorn — gleiches Verfahren, leerer Puffer.
    public func discard() {
        words = []
        buffer = DiceEntropy(method: method)
    }
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "$REPO" && swift test`
Expected: PASS, alle bisherigen plus die neuen `DiceSessionTests`.

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core/DiceSession.swift Tests/Pips39CoreTests/DiceSessionTests.swift
git commit -m "feat: DiceSession — die gesamte Ablauflogik, ohne Simulator prüfbar"
git push
```

---

### Task 3: Beschriftungen der Verfahren

Die Oberfläche braucht Namen und Erklärungen für die beiden Verfahren. Die gehören
zum Modell, nicht in die Ansicht — sie tauchen in Phase 5 im Nachrechnen-Bereich
erneut auf.

**Files:**
- Modify: `Sources/Pips39Core/DiceMethod.swift`
- Create: `Tests/Pips39CoreTests/DiceMethodLabelTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/DiceMethodLabelTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class DiceMethodLabelTests: XCTestCase {

    func testEveryMethodHasANonEmptyLabel() {
        for method in DiceMethod.allCases {
            XCTAssertFalse(method.title.isEmpty, "Titel fehlt für \(method)")
            XCTAssertFalse(method.summary.isEmpty, "Kurzbeschreibung fehlt für \(method)")
            XCTAssertFalse(method.rollCountHint.isEmpty, "Wurfzahl-Hinweis fehlt für \(method)")
        }
    }

    func testTitlesAreDistinct() {
        let titles = Set(DiceMethod.allCases.map(\.title))
        XCTAssertEqual(titles.count, DiceMethod.allCases.count)
    }

    func testHashedIsTheDefault() {
        XCTAssertEqual(DiceMethod.standard, .sha256)
    }

    /// Verfahren B nennt eine feste Wurfzahl, Verfahren A darf das nicht.
    func testOnlyHashedPromisesAFixedRollCount() {
        XCTAssertTrue(DiceMethod.sha256.rollCountHint.contains("99"))
        XCTAssertFalse(DiceMethod.coleman.rollCountHint.contains("99"))
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "$REPO" && swift test`
Expected: FAIL, `type 'DiceMethod' has no member 'title'`.

- [ ] **Step 3: `DiceMethod.swift` erweitern**

Vor der schließenden Klammer von `public enum DiceMethod` einfügen:

```swift
    /// Das voreingestellte Verfahren.
    public static let standard: DiceMethod = .sha256

    /// Kurzer Name für die Oberfläche. Englisch — die Zielgruppe ist international.
    public var title: String {
        switch self {
        case .sha256:  return "SHA-256"
        case .coleman: return "Coleman"
        }
    }

    /// Ein Satz dazu, was das Verfahren tut.
    public var summary: String {
        switch self {
        case .sha256:
            return "Your dice sequence is hashed with SHA-256. Verify with shasum and any BIP39 tool."
        case .coleman:
            return "Bit-for-bit identical to iancoleman.io/bip39. Verify by entering the same rolls there."
        }
    }

    /// Was den Nutzer an Würfelarbeit erwartet. Verfahren A darf keine feste Zahl
    /// nennen — dort liefert jeder Wurf ein oder zwei Bit.
    public var rollCountHint: String {
        switch self {
        case .sha256:  return "Exactly 99 rolls."
        case .coleman: return "Around 154 rolls, but the exact number varies."
        }
    }
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "$REPO" && swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core/DiceMethod.swift Tests/Pips39CoreTests/DiceMethodLabelTests.swift
git commit -m "feat: Beschriftungen der beiden Verfahren im Modell"
git push
```

---

### Task 4: Verfahrenswahl-Ansicht

**Files:**
- Create: `Pips39/Pips39/MethodChoiceView.swift`

Das Projekt nutzt `objectVersion = 77` mit synchronisierten Ordnern — neue Dateien in
`Pips39/Pips39/` werden automatisch mitgebaut, die `project.pbxproj` muss dafür
**nicht** angefasst werden.

- [ ] **Step 1: Die Ansicht schreiben**

```swift
import SwiftUI
import Pips39Core

/// Erster Schritt: das Verfahren wählen.
///
/// Bewusst hier und nicht in den Einstellungen: Eine Wurffolge sagt nicht, mit
/// welchem Verfahren sie gerechnet wurde. Ein Schalter, der zwischen zwei Sitzungen
/// still umspringt, lässt den Nutzer sein Backup für kaputt halten.
struct MethodChoiceView: View {

    let onChoose: (DiceMethod) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pips39")
                    .font(.largeTitle.bold())
                Text("Roll dice, get a BIP39 seed phrase. Nothing is stored.")
                    .foregroundStyle(.secondary)
            }

            Text("Choose a method")
                .font(.headline)

            ForEach(DiceMethod.allCases, id: \.self) { method in
                Button {
                    onChoose(method)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(method.title).font(.title3.weight(.semibold))
                            if method == .standard {
                                Text("DEFAULT")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(method.summary).font(.footnote)
                        Text(method.rollCountHint)
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

            Text("The method travels with the result. Write it down together with your words.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    MethodChoiceView { _ in }
}
```

- [ ] **Step 2: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/MethodChoiceView.swift
git commit -m "feat: Verfahrenswahl als erster Schritt, nicht als Einstellung"
git push
```

---

### Task 5: Würfel-Ansicht

**Files:**
- Create: `Pips39/Pips39/RollingView.swift`

- [ ] **Step 1: Die Ansicht schreiben**

```swift
import SwiftUI
import Pips39Core

/// Die Würfeleingabe: sechs große Flächen, Rückgängig, Fortschritt.
struct RollingView: View {

    @ObservedObject var session: DiceSession
    let onFinished: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 20) {
            header

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...6, id: \.self) { face in
                    Button {
                        session.roll(UInt8(face))
                    } label: {
                        Image(systemName: "die.face.\(face).fill")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(session.isComplete)
                }
            }

            HStack {
                Button("Undo") { session.undo() }
                    .disabled(!session.canUndo)
                Spacer()
                Button("Show words") {
                    session.reveal()
                    onFinished()
                }
                .font(.body.weight(.semibold))
                .disabled(!session.isComplete)
            }

            Spacer()
        }
        .padding()
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(session.method.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(progressText)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            ProgressView(value: fraction)
        }
    }

    private var progressText: String {
        switch session.progress {
        case let .rolls(done, needed):
            return "\(done) of \(needed) rolls"
        case let .bits(done, needed):
            return "\(min(done, needed)) of \(needed) bits"
        }
    }

    private var fraction: Double {
        switch session.progress {
        case let .rolls(done, needed), let .bits(done, needed):
            return needed == 0 ? 0 : min(Double(done) / Double(needed), 1)
        }
    }
}

#Preview {
    RollingView(session: DiceSession(method: .sha256)) { }
}
```

Hinweis zur Fortschrittsanzeige: Unter Verfahren A zählt sie **Bits**, nicht Würfe,
und darf keine Restdauer versprechen. Der `min(done, needed)` fängt den Fall ab, dass
der letzte Wurf um ein Bit über das Ziel schießt.

- [ ] **Step 2: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/RollingView.swift
git commit -m "feat: Würfeleingabe mit Rückgängig und verfahrensrichtigem Fortschritt"
git push
```

---

### Task 6: Wortanzeige

**Files:**
- Create: `Pips39/Pips39/WordsView.swift`

- [ ] **Step 1: Die Ansicht schreiben**

```swift
import SwiftUI
import Pips39Core

/// Die 24 Wörter, nummeriert, mit dem benutzten Verfahren daneben.
struct WordsView: View {

    @ObservedObject var session: DiceSession
    let onDiscard: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Write these down")
                        .font(.title2.bold())
                    Text("Method: \(session.method.title) — note this down too. The same rolls give different words under the other method.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(Array(session.words.enumerated()), id: \.offset) { index, word in
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)
                            Text(word)
                                .font(.body.weight(.medium))
                            Spacer(minLength: 0)
                        }
                    }
                }

                Button(role: .destructive) {
                    session.discard()
                    onDiscard()
                } label: {
                    Text("Discard and start over")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
    }
}

/// Eigene Funktion, damit die Vorschau ein einzelner Ausdruck bleibt —
/// `#Preview` verträgt keine mehrzeilige Anweisungsfolge.
private func previewSession() -> DiceSession {
    let session = DiceSession(method: .sha256)
    for _ in 0..<99 { session.roll(1) }
    session.reveal()
    return session
}

#Preview {
    WordsView(session: previewSession()) { }
}
```

- [ ] **Step 2: Bauen**

Run wie in Task 5.
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/WordsView.swift
git commit -m "feat: Wortanzeige mit Verfahrensangabe"
git push
```

---

### Task 7: Bildschirmschutz

**Files:**
- Create: `Pips39/Pips39/ScreenProtection.swift`

Dieser Teil braucht UIKit und gehört deshalb ins App-Target, nicht ins Paket. Er ist
damit **nicht** durch `swift test` abgedeckt — die Prüfung erfolgt in Task 8 von Hand
im Simulator.

- [ ] **Step 1: Den Modifier schreiben**

```swift
import SwiftUI
import UIKit

/// Verdeckt den Inhalt, sobald er auf die Platte oder in eine Aufnahme geraten könnte.
///
/// Zwei verschiedene Fälle:
/// - **Hintergrund:** iOS legt beim Wechsel in den App-Umschalter einen Schnappschuss
///   des Bildschirms als Datei ab. Der Inhalt wird deshalb schon bei
///   `willResignActive` verdeckt, nicht erst bei `didEnterBackground`.
/// - **Aufnahme und Spiegelung:** `UIScreen.isCaptured` ist zuverlässig, hier wird
///   hart abgeblendet.
///
/// Screenshots lassen sich nicht verhindern — iOS meldet sie erst hinterher.
struct ScreenProtection: ViewModifier {

    @State private var isObscured = false
    @State private var isCaptured = UIScreen.main.isCaptured

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isObscured || isCaptured ? 0 : 1)

            if isObscured || isCaptured {
                VStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill").font(.largeTitle)
                    Text(isCaptured ? "Hidden while the screen is being recorded or mirrored."
                                    : "Hidden")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
                .padding()
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willResignActiveNotification)) { _ in
            isObscured = true
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification)) { _ in
            isObscured = false
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIScreen.capturedDidChangeNotification)) { _ in
            isCaptured = UIScreen.main.isCaptured
        }
    }
}

extension View {
    /// Auf jede Ansicht anwenden, die Wörter oder die Wurffolge zeigt.
    func screenProtected() -> some View {
        modifier(ScreenProtection())
    }
}
```

`UIScreen.main` ist seit iOS 16 als veraltet markiert und erzeugt eine Warnung. Es
funktioniert weiterhin, und die Alternativen über die Szene sind an dieser Stelle
umständlicher. Die Warnung stehen lassen, nicht unterdrücken.

- [ ] **Step 2: Auf die Wortanzeige anwenden**

In `WordsView.swift` an den `ScrollView` anhängen, direkt nach dem schließenden
`}` des ScrollView-Blocks und vor dem Ende von `body`:

```swift
        .screenProtected()
```

- [ ] **Step 3: Bauen**

Run wie in Task 5.
Expected: `** BUILD SUCCEEDED **`, mit einer Deprecation-Warnung zu `UIScreen.main`.

- [ ] **Step 4: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/ScreenProtection.swift Pips39/Pips39/WordsView.swift
git commit -m "feat: Wörter bei Hintergrundwechsel und Bildschirmaufnahme verdecken"
git push
```

---

### Task 8: Ablauf zusammenbauen

**Files:**
- Modify: `Pips39/Pips39/ContentView.swift`

- [ ] **Step 1: `ContentView.swift` ersetzen**

```swift
import SwiftUI
import Pips39Core

/// Der Ablauf: Verfahren wählen → würfeln → Wörter → verwerfen.
struct ContentView: View {

    @State private var session: DiceSession?
    @State private var showsWords = false

    var body: some View {
        if let session {
            if showsWords {
                WordsView(session: session) {
                    self.session = nil
                    showsWords = false
                }
            } else {
                RollingView(session: session) {
                    showsWords = true
                }
            }
        } else {
            MethodChoiceView { method in
                session = DiceSession(method: method)
            }
        }
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 2: Bauen**

Run wie in Task 5.
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Alle Paket-Tests laufen lassen**

```bash
cd "$REPO" && swift test
```
Expected: PASS, alle Tests aus Phase 1 bis 3.

- [ ] **Step 4: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/ContentView.swift
git commit -m "feat: Ablauf verdrahtet — Verfahren, Würfeln, Wörter, Verwerfen"
git push
```

---

## Abschluss der Phase

- [ ] **Sichtprüfung im Simulator** — macht der Auftraggeber, nicht der Implementierer.
      Ablauf: Verfahren wählen, ein paar Würfe eingeben, Rückgängig prüfen,
      durchwürfeln, Wörter ansehen, verwerfen. Zusätzlich: App in den Hintergrund
      schicken und im App-Umschalter prüfen, dass die Wörter verdeckt sind.

- [ ] **Spec nachziehen:** Bausteintabelle um `DiceSession` ergänzen, den offenen
      Punkt „Deployment-Target senken" und „App-Target mit `Pips39Core` verdrahten"
      abhaken.

## Was danach kommt (nicht Teil dieses Plans)

- **Phase 4:** BIP39-Tastatur und Abschreibkontrolle
- **Phase 5:** `EnvironmentProbe`, Nachrechnen-Bereich, Erklärseite, Geräte-Checkliste
- **Später:** Lokalisierung, 12-Wort-Option, Bias-Warnung, App-Store-Vorbereitung
