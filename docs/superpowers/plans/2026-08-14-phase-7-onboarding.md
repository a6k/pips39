# Pips39 — Phase 7: Geführtes Onboarding — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die Erklärseite wird eine geführte Strecke aus drei Seiten in der Reihenfolge, in der man sie tatsächlich abarbeiten kann: erst die App prüfen (Netz noch an), dann das Gerät abschotten, dann loswürfeln. Eine feste Fußleiste bietet Überspringen und Weiter.

**Architecture:** Eine `TabView` im Page-Stil ersetzt die bisherige `IntroView`. Neu im Paket sind nur die externen Adressen; alles andere ist Oberfläche.

**Spec:** `~/Documents/Doku/02 Projekte/Ideen und Tests/Pips39/würfel-tool-spec.md`, Abschnitte 3 und 7

**Vorhanden:** 156 Tests grün, sechs Phasen umgesetzt, Zurück-Knopf in der Würfelansicht.

---

## Warum die Reihenfolge ein Fehler war, kein Schönheitsproblem

Die bisherige `IntroView` sagt oben „Schalte WLAN, Mobilfunk, Bluetooth und AirDrop
aus" und ganz unten „Prüfe die App" — mit Schritten, die eine Shell und einen Browser
mit Netz brauchen. Wer die Seite von oben nach unten abarbeitet, macht sich das Prüfen
unmöglich.

Das ist derselbe Fehlertyp, der schon einmal im Nachrechnen-Bereich steckte:
**Anweisungen, die dem Zustand widersprechen, in den die App den Nutzer gerade
gebracht hat.** Eine Abfolge kann das nicht mehr falsch herum lesen.

> [!note] Warum es ein Überspringen gibt
> Die App speichert nichts, auch kein „schon gesehen". Das Onboarding erscheint also
> bei **jedem** Start. Für den seltenen echten Einsatz ist das richtig; beim
> Entwickeln und Ausprobieren wäre es eine Qual, und ein genervter Nutzer klickt
> ohnehin durch, ohne zu lesen. Deshalb steht „Skip" dauerhaft in der Fußleiste.

---

### Task 1: Die externen Adressen ins Paket

**Files:**
- Create: `Sources/Pips39Core/ExternalLinks.swift`
- Create: `Tests/Pips39CoreTests/ExternalLinksTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

```swift
import XCTest
@testable import Pips39Core

final class ExternalLinksTests: XCTestCase {

    private var all: [String] {
        [ExternalLinks.colemanTool, ExternalLinks.sourceCode]
    }

    func testAllLinksParseAsURLs() {
        for link in all {
            XCTAssertNotNil(URL(string: link), "Keine gültige Adresse: \(link)")
        }
    }

    /// Eine App, die zum Abschotten anleitet, darf nirgends auf http verweisen.
    func testEveryLinkUsesHTTPS() {
        for link in all {
            XCTAssertTrue(link.hasPrefix("https://"), "Kein https: \(link)")
        }
    }

    func testColemanToolPointsAtTheBIP39Page() {
        XCTAssertTrue(ExternalLinks.colemanTool.contains("iancoleman"))
        XCTAssertTrue(ExternalLinks.colemanTool.contains("bip39"))
    }

    func testSourcePointsAtTheRepository() {
        XCTAssertTrue(ExternalLinks.sourceCode.contains("github.com"))
        XCTAssertTrue(ExternalLinks.sourceCode.contains("pips39"))
    }

    func testLinksAreDistinct() {
        XCTAssertEqual(Set(all).count, all.count)
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: FAIL, `cannot find 'ExternalLinks' in scope`.

- [ ] **Step 3: `ExternalLinks.swift` schreiben**

```swift
import Foundation

/// Die beiden Adressen, die das Onboarding anbietet.
///
/// Im Paket und nicht in der Ansicht, damit ein Test sie erwischt: Eine App, die zum
/// Abschotten anleitet, darf nirgends auf `http` verweisen.
public enum ExternalLinks {

    /// Ian Colemans BIP39-Werkzeug — die Referenz, gegen die geprüft wird.
    public static let colemanTool = "https://iancoleman.io/bip39/"

    /// Der Quelltext. „Open Source" heißt beim Store-Download geprüfter Quelltext,
    /// nicht geprüftes Binary — wer Gewissheit will, baut hier selbst.
    public static let sourceCode = "https://github.com/a6k/pips39"
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Sources/Pips39Core/ExternalLinks.swift Tests/Pips39CoreTests/ExternalLinksTests.swift
git commit -m "feat: externe Adressen im Paket, mit https-Test"
git push
```

---

### Task 2: Das Onboarding

**Files:**
- Create: `Pips39/Pips39/OnboardingView.swift`

- [ ] **Step 1: Die Ansicht schreiben**

```swift
import SwiftUI
import Pips39Core

/// Drei Seiten in der Reihenfolge, in der man sie abarbeiten kann.
///
/// Die alte einteilige Erklärseite widersprach sich selbst: Sie forderte oben das
/// Abschalten aller Funkwege und unten eine Prüfung, die Shell und Browser braucht.
/// Eine Abfolge lässt sich nicht falsch herum lesen.
struct OnboardingView: View {

    @ObservedObject var probe: EnvironmentProbe
    let onDone: () -> Void

    @State private var page = 0

    private let lastPage = 2

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                verifyPage.tag(0)
                offlinePage.tag(1)
                readyPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            footer
        }
    }

    // MARK: Seite 1 — prüfen, solange das Netz noch da ist

    private var verifyPage: some View {
        page(title: "First: check the app") {
            Text("Do this now, while this device is still online. Make up a dice sequence for it — never use the rolls behind a seed you intend to keep.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(DiceMethod.allCases, id: \.rawValue) { method in
                VStack(alignment: .leading, spacing: 6) {
                    Text(method.title)
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(method.verificationSteps(for: .standard).enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(step).font(.footnote)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Link("iancoleman.io/bip39", destination: URL(string: ExternalLinks.colemanTool)!)
                Link("Source code on GitHub", destination: URL(string: ExternalLinks.sourceCode)!)
            }
            .font(.footnote.weight(.medium))

            Text("Tapping a link opens Safari. That is fine now and not later — do it before you take the device offline.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Seite 2 — abschotten

    private var offlinePage: some View {
        page(title: "Then: take it offline") {
            EnvironmentNotice(probe: probe)

            ForEach(Array(checklist.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .padding(.top, 5)
                    Text(item).font(.footnote)
                }
            }

            Text("The notice above disappears once there is no connection left. That is a statement, not an all-clear — see the last page.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private let checklist = [
        "Turn off Wi-Fi, cellular, Bluetooth and AirDrop in Settings — not in Control Center.",
        "Turn off iCloud completely: no backup, no keychain sync.",
        "Block USB accessories under Face ID & Passcode.",
        "Turn on Lockdown Mode.",
        "Turn off Settings, App Store, Offload Unused Apps — otherwise iOS may delete this app and need the network to restore it."
    ]

    // MARK: Seite 3 — was bleibt

    private var readyPage: some View {
        page(title: "Ready") {
            EnvironmentNotice(probe: probe)

            VStack(alignment: .leading, spacing: 8) {
                Text("What this app cannot tell you")
                    .font(.headline)
                Text("Bluetooth state is not readable by apps since iOS 13, and no network connection does not mean the device is isolated. This app reports what it can see and never claims you are safe. That judgement stays with you.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("How this ends")
                    .font(.headline)
                Text("Nothing is stored. Write the words on paper, note the method next to them, and check your copy with the app before you leave the screen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Gerüst

    private func page<Content: View>(title: String,
                                     @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.largeTitle.bold())
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .padding(.bottom, 28)
        }
    }

    /// Immer sichtbar, damit man zum Starten nicht ans Seitenende scrollen muss.
    private var footer: some View {
        HStack {
            Button("Skip", action: onDone)
                .buttonStyle(.bordered)

            Spacer()

            Button(page == lastPage ? "Start" : "Next") {
                if page == lastPage {
                    onDone()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

#Preview {
    OnboardingView(probe: EnvironmentProbe()) { }
}
```

> [!note] Warum „Hilfe" **nicht** in dieser Fußleiste steht
> Ursprünglich waren „Start" und „Hilfe" als das Knopfpaar vorgeschlagen. Beim
> Entwerfen fiel auf: Ein Hilfe-Knopf auf der Hilfeseite führt im Kreis. Die
> Fußleiste trägt deshalb **Skip** und **Next/Start**; der Weg zurück zur Hilfe ist
> das „?" in der Würfelansicht aus Task 3.

- [ ] **Step 2: Bauen**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | tail -4
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Pips39/Pips39/OnboardingView.swift
git commit -m "feat: Onboarding in drei Seiten, in ausführbarer Reihenfolge"
git push
```

---

### Task 3: Einhängen, Hilfe-Knopf, alte Seite entfernen

**Files:**
- Modify: `Pips39/Pips39/ContentView.swift`
- Modify: `Pips39/Pips39/RollingView.swift`
- Delete: `Pips39/Pips39/IntroView.swift`

- [ ] **Step 1: `ContentView` umstellen**

`IntroView` durch `OnboardingView` ersetzen:

```swift
        if !hasStarted {
            OnboardingView(probe: probe) { hasStarted = true }
        } else if let session {
```

und die Würfelansicht um den Hilfe-Weg erweitern:

```swift
            case .rolling:
                RollingView(session: session) {
                    step = .words
                } onBack: {
                    startOver()
                } onHelp: {
                    hasStarted = false
                }
```

> [!important] Hilfe darf nichts verwerfen
> `hasStarted = false` zeigt das Onboarding **über** der laufenden Sitzung. `session`
> bleibt unangetastet, `step` auch. Wer „Start" oder „Skip" drückt, landet wieder
> genau in der Würfelansicht, mit allen bisherigen Würfen. Das ist der Unterschied
> zum Zurück-Knopf, der bewusst verwirft — deshalb fragt der nach und dieser nicht.

- [ ] **Step 2: `RollingView` um den Hilfe-Knopf erweitern**

Eigenschaft unter `let onBack: () -> Void`:

```swift
    let onHelp: () -> Void
```

In `backBar` nach dem `Spacer()`:

```swift
            Button(action: onHelp) {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
            }
            .accessibilityLabel("Help")
```

Und die Vorschau am Dateiende:

```swift
#Preview {
    RollingView(session: DiceSession(method: .sha256),
                onFinished: { }, onBack: { }, onHelp: { })
}
```

- [ ] **Step 3: `IntroView.swift` löschen**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git rm Pips39/Pips39/IntroView.swift
```

Der synchronisierte Ordner nimmt die Datei automatisch aus dem Build; an
`project.pbxproj` ist nichts zu ändern.

- [ ] **Step 4: Bauen und Tests**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | tail -4
cd "/Users/dev/Documents/Projekte/Apps/Pips39" && swift test 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **` und alle Tests grün.

- [ ] **Step 5: Commit**

```bash
cd "/Users/dev/Documents/Projekte/Apps/Pips39"
git add Pips39/Pips39/ContentView.swift Pips39/Pips39/RollingView.swift Pips39/Pips39/IntroView.swift
git commit -m "feat: Onboarding eingehängt, Hilfe-Knopf in der Würfelansicht"
git push
```

---

## Abschluss der Phase

- [ ] **Sichtprüfung im Simulator:**
  - Drei Seiten durchblättern, Punkte unten sichtbar, Fußleiste bleibt stehen
  - Auf Seite 1 stehen die Links, auf Seite 2 die Checkliste, auf Seite 3 die Grenzen
  - „Skip" springt sofort zur Verfahrenswahl
  - Ein paar Würfe eingeben, „?" tippen, „Skip" — die Würfe müssen **noch da sein**
  - Der Zurück-Knopf fragt weiterhin nach und verwirft

- [ ] **Spec nachziehen:** Abschnitt 3 auf die neue Abfolge, `OnboardingView` und
      `ExternalLinks` in die Bausteintabelle, `IntroView` raus.

## Was danach kommt (nicht Teil dieses Plans)

- Lokalisierung
- Bias-Warnung (bewusst offen im Spec)
- Leerraum in der Prüfansicht
- App-Store-Vorbereitung
