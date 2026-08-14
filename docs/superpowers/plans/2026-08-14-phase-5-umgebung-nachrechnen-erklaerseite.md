# Pips39 — Phase 5: Umgebungsprüfung, Nachrechnen und Erklärseite — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die App sagt, was sie über ihre Umgebung weiß, macht das Ergebnis unabhängig nachrechenbar und erklärt vorab, wie das Gerät vorbereitet gehört. Damit ist der im Spec beschriebene Umfang vollständig.

**Architecture:** Wie in Phase 3 und 4 — alles Prüfbare liegt im Swift Package, die SwiftUI-Ansichten bleiben dumm. Neu ist, dass hier zum ersten Mal **Texte** die eigentliche Anforderung tragen: Die Regel „nie ein grünes *sicher*" ist keine Formulierungsfrage, sondern wird als Test festgehalten.

**Tech Stack:** SwiftUI, Combine, Network (`NWPathMonitor`), Swift 5.9, iOS 16.

**Spec:** `~/Documents/Doku/02 Projekte/Ideen und Tests/Pips39/würfel-tool-spec.md`, Abschnitte 2.5, 2.6, 3 und 7

**Vorhanden aus Phasen 1–4:** `WordList`, `BitStream`, `BIP39`, `SecretBytes`, `DiceMethod` (`title`, `summary`, `rollCountHint`, `standard`), `ColemanEncoding`, `HashedEncoding`, `DiceEntropy`, `DiceProgress`, `DiceError`, `DiceSession` (`method`, `words`, `rollCount`, `progress`, `isComplete`, `canUndo`, `rollSequence`, `roll`, `undo`, `reveal`, `discard`), `WordEntry`, `TranscriptionCheck`; App mit `MethodChoiceView`, `RollingView`, `WordsView`, `WordKeyboardView`, `TranscriptionView`, `ScreenProtection`, `ContentView`. 119 Tests grün.

---

## Eine Folge der Kein-Speichern-Regel, die man akzeptieren muss

Die Erklärseite erscheint bei **jedem** Start. Ein „nicht mehr anzeigen" wäre ein
gespeicherter Zustand, und die App speichert nichts — auch keine Häkchen. Das ist
vertretbar: Ein Werkzeug, das man ein- oder zweimal im Leben benutzt, darf die
Geräte-Checkliste jedes Mal zeigen. Genau dann liest man sie nämlich, kurz bevor es
zählt.

---

### Task 1: `EnvironmentProbe` — feststellen, nie urteilen

**Files:**
- Create: `Sources/Pips39Core/EnvironmentProbe.swift`
- Create: `Tests/Pips39CoreTests/EnvironmentProbeTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/EnvironmentProbeTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class EnvironmentProbeTests: XCTestCase {

    func testConnectedDeviceProducesAStatement() {
        let notice = EnvironmentProbe.notice(isNetworkAvailable: true)
        XCTAssertNotNil(notice)
        XCTAssertTrue(notice!.contains("network"))
    }

    /// Ohne Verbindung sagt die App nichts. Sie gibt keine Entwarnung.
    func testDisconnectedDeviceProducesNoNotice() {
        XCTAssertNil(EnvironmentProbe.notice(isNetworkAvailable: false))
    }

    /// Der Kern von Spec 2.5, als Test festgehalten: Die App darf Sicherheit
    /// niemals behaupten. Bluetooth ist seit iOS 13 gar nicht abfragbar, und
    /// „keine Verbindung" heißt nicht luftdicht.
    func testNoNoticeEverClaimsSafety() {
        let forbidden = ["safe", "secure", "protected", "offline", "air-gap", "airgap"]
        for available in [true, false] {
            let text = (EnvironmentProbe.notice(isNetworkAvailable: available) ?? "").lowercased()
            for word in forbidden {
                XCTAssertFalse(text.contains(word),
                               "Verbotenes Wort \(word) im Hinweis: \(text)")
            }
        }
    }

    func testNoticeIsAStatementNotAnInstruction() {
        let text = EnvironmentProbe.notice(isNetworkAvailable: true) ?? ""
        XCTAssertFalse(text.contains("!"), "Kein Ausrufezeichen — Feststellung, kein Alarm")
        XCTAssertFalse(text.lowercased().hasPrefix("warning"))
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `cannot find 'EnvironmentProbe' in scope`.

- [ ] **Step 3: `EnvironmentProbe.swift` schreiben**

```swift
import Foundation
import Combine
import Network

/// Beobachtet, was über die Umgebung des Geräts feststellbar ist.
///
/// Die Trennung ist Absicht: `notice(isNetworkAvailable:)` ist eine reine Funktion
/// und damit prüfbar, der Monitor drumherum ist so dünn wie möglich.
public final class EnvironmentProbe: ObservableObject {

    /// Der anzuzeigende Hinweis, oder `nil` wenn nichts zu sagen ist.
    @Published public private(set) var notice: String?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "app.comodin.Pips39.environment")

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let available = path.status == .satisfied
            DispatchQueue.main.async {
                self?.notice = EnvironmentProbe.notice(isNetworkAvailable: available)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    /// Formuliert den Hinweis zu einem festgestellten Netzwerkzustand.
    ///
    /// > Wichtig: Es gibt **keinen** grünen „sicher"-Zustand. Ohne Verbindung sagt
    /// > die App gar nichts, statt eine Entwarnung zu geben, die sie nicht belegen
    /// > kann — Bluetooth ist seit iOS 13 nicht abfragbar, und wer den Flugmodus
    /// > kurz einschaltet, käme an jeder Sperre vorbei. Ein falsches
    /// > Sicherheitsversprechen ist schlechter als gar keins.
    public static func notice(isNetworkAvailable: Bool) -> String? {
        guard isNetworkAvailable else { return nil }
        return "This device is connected to a network."
    }
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/EnvironmentProbe.swift Tests/Pips39CoreTests/EnvironmentProbeTests.swift
git commit -m "feat: EnvironmentProbe — benennt den Netzzustand, gibt nie Entwarnung"
git push
```

---

### Task 2: Nachrechen-Daten und -Anleitung im Modell

**Files:**
- Modify: `Sources/Pips39Core/DiceSession.swift`
- Modify: `Sources/Pips39Core/DiceMethod.swift`
- Create: `Tests/Pips39CoreTests/VerificationDataTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/VerificationDataTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class VerificationDataTests: XCTestCase {

    private func session(_ method: DiceMethod, face: UInt8, times: Int) -> DiceSession {
        let session = DiceSession(method: method)
        for _ in 0..<times { session.roll(face) }
        return session
    }

    // MARK: Hex-Entropie

    func testNoHexBeforeCompletion() {
        XCTAssertNil(session(.sha256, face: 1, times: 50).entropyHex)
    }

    func testHexMatchesShasumForHashedMethod() {
        let hex = session(.sha256, face: 1, times: 99).entropyHex
        XCTAssertEqual(hex, "fa098eb852b2660348b21bb00ad03a49cc177ea07ebe34f46b40baa85313525e")
    }

    func testHexIsSixtyFourCharactersForColeman() throws {
        let hex = try XCTUnwrap(session(.coleman, face: 1, times: 128).entropyHex)
        XCTAssertEqual(hex.count, 64)
        XCTAssertTrue(hex.allSatisfy { $0.isHexDigit })
    }

    func testRollSequenceIsTheTypedDigits() {
        XCTAssertEqual(session(.sha256, face: 6, times: 5).rollSequence, "66666")
    }

    // MARK: Anleitung je Verfahren

    func testEveryMethodHasVerificationSteps() {
        for method in DiceMethod.allCases {
            XCTAssertFalse(method.verificationSteps.isEmpty, "Keine Schritte für \(method)")
            for step in method.verificationSteps {
                XCTAssertFalse(step.isEmpty)
            }
        }
    }

    func testHashedStepsMentionShasum() {
        let joined = DiceMethod.sha256.verificationSteps.joined(separator: " ")
        XCTAssertTrue(joined.contains("shasum"))
    }

    /// Die beiden Stolperstellen aus Spec 2.6 müssen in der Anleitung stehen,
    /// sonst produziert der Verifikationsweg Fehlalarme — und ein Fehlalarm bei
    /// korrektem Seed ist genau das, was Vertrauen zerstört.
    func testColemanStepsWarnAboutBothPitfalls() {
        let joined = DiceMethod.coleman.verificationSteps.joined(separator: " ")
        XCTAssertTrue(joined.contains("Dice"), "Hinweis auf den Radio-Button Dice fehlt")
        XCTAssertTrue(joined.contains("Raw Entropy"), "Hinweis auf Use Raw Entropy fehlt")
    }

    func testEveryMethodWarnsAboutThrowawaySequences() {
        for method in DiceMethod.allCases {
            XCTAssertTrue(method.verificationWarning.lowercased().contains("throwaway"),
                          "Wegwerf-Hinweis fehlt bei \(method)")
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `value of type 'DiceSession' has no member 'entropyHex'`.

- [ ] **Step 3: `DiceSession.swift` erweitern**

Vor der schließenden Klammer von `public final class DiceSession` einfügen:

```swift
    /// Die erzeugte Entropie als Hex, oder `nil` solange nicht genug gewürfelt wurde.
    ///
    /// Seed-gleichwertig. Wird nur im Nachrechnen-Bereich gezeigt, zusammen mit dem
    /// Hinweis, dafür eine Wegwerf-Folge zu benutzen.
    public var entropyHex: String? {
        guard var entropy = buffer.entropy() else { return nil }
        defer { entropy.wipe() }
        return entropy.bytes.map { String(format: "%02x", $0) }.joined()
    }
```

- [ ] **Step 4: `DiceMethod.swift` erweitern**

Vor der schließenden Klammer von `public enum DiceMethod` einfügen:

```swift
    /// Die Schritte, mit denen der Nutzer das Ergebnis unabhängig nachrechnet.
    public var verificationSteps: [String] {
        switch self {
        case .sha256:
            return [
                "Run: printf '%s' \"<your rolls>\" | shasum -a 256",
                "Open iancoleman.io/bip39 and paste the hex into the Entropy field.",
                "Set Entropy type to Hex, then compare the words."
            ]
        case .coleman:
            return [
                "Open iancoleman.io/bip39.",
                "Select the Dice entropy type first — otherwise a sequence of only 1s is read as binary.",
                "Leave Mnemonic Length on Use Raw Entropy — a fixed word count hashes instead and truncates the other way.",
                "Enter exactly the rolls shown here, no more, and compare the words."
            ]
        }
    }

    /// Der Satz, ohne den der Nachrechnen-Bereich mehr schadet als nützt.
    public var verificationWarning: String {
        "Use a throwaway sequence to try this out. Never type your real rolls into a browser."
    }
```

- [ ] **Step 5: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/DiceSession.swift Sources/Pips39Core/DiceMethod.swift Tests/Pips39CoreTests/VerificationDataTests.swift
git commit -m "feat: Hex-Entropie und verfahrensabhängige Nachrechen-Anleitung"
git push
```

---

### Task 3: Der Umgebungshinweis in der Oberfläche

**Files:**
- Create: `Pips39/Pips39/EnvironmentNotice.swift`

- [ ] **Step 1: Die Ansicht schreiben**

```swift
import SwiftUI
import Pips39Core

/// Zeigt, was über die Umgebung feststellbar ist — und sonst nichts.
///
/// Es gibt bewusst **keinen** grünen Gegenzustand: Ohne Verbindung erscheint diese
/// Ansicht gar nicht. Eine Entwarnung könnte die App nicht belegen (Spec 2.5).
struct EnvironmentNotice: View {

    @ObservedObject var probe: EnvironmentProbe

    var body: some View {
        if let notice = probe.notice {
            HStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                Text(notice)
                    .font(.footnote)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    EnvironmentNotice(probe: EnvironmentProbe())
        .padding()
}
```

- [ ] **Step 2: Bauen**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -4
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Pips39/Pips39/EnvironmentNotice.swift
git commit -m "feat: Umgebungshinweis ohne grünen Gegenzustand"
git push
```

---

### Task 4: Erklärseite mit Geräte-Checkliste

**Files:**
- Create: `Pips39/Pips39/IntroView.swift`

- [ ] **Step 1: Die Ansicht schreiben**

```swift
import SwiftUI
import Pips39Core

/// Was vor dem ersten Wurf zu tun ist.
///
/// Erscheint bei jedem Start. Ein „nicht mehr anzeigen" wäre gespeicherter Zustand,
/// und die App speichert nichts — auch keine Häkchen.
struct IntroView: View {

    @ObservedObject var probe: EnvironmentProbe
    let onContinue: () -> Void

    private let checklist = [
        "Turn off Wi-Fi, cellular, Bluetooth and AirDrop in Settings — not in Control Center.",
        "Turn off iCloud completely: no backup, no keychain sync.",
        "Block USB accessories under Face ID & Passcode.",
        "Turn on Lockdown Mode.",
        "Turn off Settings → App Store → Offload Unused Apps, or iOS may delete this app and need the network to restore it."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Before you start")
                        .font(.largeTitle.bold())
                    Text("Pips39 turns dice rolls into a BIP39 seed phrase. It stores nothing, derives no addresses and signs no transactions.")
                        .foregroundStyle(.secondary)
                }

                EnvironmentNotice(probe: probe)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Prepare the device")
                        .font(.headline)
                    ForEach(Array(checklist.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle")
                                .font(.caption2)
                                .padding(.top, 5)
                            Text(item).font(.footnote)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What this app cannot tell you")
                        .font(.headline)
                    Text("Bluetooth state is not readable by apps since iOS 13, and no network connection does not mean the device is isolated. This app reports what it can see and never claims you are safe. That judgement stays with you.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
    }
}

#Preview {
    IntroView(probe: EnvironmentProbe()) { }
}
```

- [ ] **Step 2: Bauen**

Wie in Task 3.
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Pips39/Pips39/IntroView.swift
git commit -m "feat: Erklärseite mit Geräte-Checkliste"
git push
```

---

### Task 5: Nachrechnen-Bereich

**Files:**
- Create: `Pips39/Pips39/VerifyView.swift`

- [ ] **Step 1: Die Ansicht schreiben**

```swift
import SwiftUI
import Pips39Core

/// Zeigt Wurffolge und Hex-Entropie, damit der Nutzer das Ergebnis unabhängig
/// nachrechnen kann — und warnt davor, das mit dem echten Seed zu tun.
struct VerifyView: View {

    @ObservedObject var session: DiceSession
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Check this yourself")
                    .font(.title2.bold())

                warning

                field(title: "Method", value: session.method.title, monospaced: false)
                field(title: "Dice rolls", value: session.rollSequence, monospaced: true)
                field(title: "Entropy (hex)", value: session.entropyHex ?? "—", monospaced: true)

                VStack(alignment: .leading, spacing: 10) {
                    Text("How to verify")
                        .font(.headline)
                    ForEach(Array(session.method.verificationSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(step).font(.footnote)
                        }
                    }
                }

                Button("Back", action: onBack)
                    .buttonStyle(.bordered)
                    .padding(.top)
            }
            .padding()
        }
        .screenProtected()
    }

    private var warning: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(session.method.verificationWarning)
                .font(.footnote.weight(.medium))
        }
        .foregroundStyle(.red)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func field(title: String, value: String, monospaced: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(monospaced ? .system(.footnote, design: .monospaced) : .footnote)
                .textSelection(.enabled)
        }
    }
}

private func previewSession() -> DiceSession {
    let session = DiceSession(method: .sha256)
    for _ in 0..<99 { session.roll(1) }
    session.reveal()
    return session
}

#Preview {
    VerifyView(session: previewSession()) { }
}
```

> [!note] Warum die Wurffolge hier auswählbar ist
> `textSelection(.enabled)` erlaubt Kopieren. Auf einem luftdichten Gerät nützt die
> Zwischenablage niemandem, und wer ohnehin mit einer Wegwerf-Folge probiert, spart
> sich Abtippen. Der Warnhinweis darüber steht genau deshalb an erster Stelle.

- [ ] **Step 2: Bauen**

Wie in Task 3.
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Pips39/Pips39/VerifyView.swift
git commit -m "feat: Nachrechnen-Bereich mit Wurffolge, Hex und Anleitung"
git push
```

---

### Task 6: Alles in den Ablauf einhängen

**Files:**
- Modify: `Pips39/Pips39/ContentView.swift`
- Modify: `Pips39/Pips39/WordsView.swift`

- [ ] **Step 1: `WordsView` um einen dritten Knopf ergänzen**

Eigenschaft unter `let onCheck: () -> Void`:

```swift
    let onVerify: () -> Void
```

Im Knopfblock, zwischen „I wrote them down" und „Discard and start over":

```swift
                    Button("Check this yourself", action: onVerify)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
```

Vorschau am Dateiende anpassen:

```swift
#Preview {
    WordsView(session: previewSession(), onDiscard: { }, onCheck: { }, onVerify: { })
}
```

- [ ] **Step 2: `ContentView.swift` ersetzen**

```swift
import SwiftUI
import Pips39Core

/// Der Ablauf: Erklärseite → Verfahren wählen → würfeln → Wörter →
/// Abschreibkontrolle → verwerfen. Der Nachrechnen-Bereich hängt an der Wortanzeige.
struct ContentView: View {

    private enum Step {
        case rolling
        case words
        case verifying
        case checking(TranscriptionCheck)
    }

    @StateObject private var probe = EnvironmentProbe()
    @State private var hasStarted = false
    @State private var session: DiceSession?
    @State private var step: Step = .rolling

    var body: some View {
        if !hasStarted {
            IntroView(probe: probe) { hasStarted = true }
        } else if let session {
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
                } onVerify: {
                    step = .verifying
                }
            case .verifying:
                VerifyView(session: session) {
                    step = .words
                }
            case let .checking(check):
                TranscriptionView(check: check) {
                    startOver()
                } onShowWordsAgain: {
                    step = .words
                }
            }
        } else {
            VStack(spacing: 12) {
                EnvironmentNotice(probe: probe)
                MethodChoiceView { method in
                    session = DiceSession(method: method)
                    step = .rolling
                }
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

- [ ] **Step 3: Bauen und Paket-Tests**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -4
cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **` und alle Tests grün.

- [ ] **Step 4: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Pips39/Pips39/ContentView.swift Pips39/Pips39/WordsView.swift
git commit -m "feat: Erklärseite, Umgebungshinweis und Nachrechnen im Ablauf"
git push
```

---

## Abschluss der Phase

- [ ] **Sichtprüfung im Simulator.** Der Simulator hängt am Netz, der Hinweis „This
      device is connected to a network." muss also auf der Erklärseite und über der
      Verfahrenswahl erscheinen. Weiter: Erklärseite durchlesbar, Checkliste
      vollständig, nach 99 Würfen der Weg über „Check this yourself" zu Wurffolge und
      Hex — und die Hex muss zu
      `printf '%s' "111…" | shasum -a 256` passen.

- [ ] **Spec nachziehen:** Bausteintabelle um `EnvironmentProbe` und die drei neuen
      Ansichten ergänzen, Abschnitt 3 als umgesetzt markieren.

- [ ] **Damit ist der Spec-Umfang vollständig.** Was bleibt, sind die offenen Punkte
      aus Abschnitt 11 — keine neuen Features.

## Was danach kommt (nicht Teil dieses Plans)

- Lokalisierung (die Texte stehen als Literale im Code)
- 12-Wort-Option, Bias-Warnung — beide bewusst offen im Spec
- Leerraum in der Prüfansicht zwischen Kandidatenzeile und Tastatur
- App-Store-Vorbereitung: Beschreibung mit dem Satz zu Quelltext gegen Binary,
  Screenshots, Repo öffentlich schalten
