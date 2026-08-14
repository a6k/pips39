# Pips39 — Phase 13: Drei Reiter — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Alle drei Wege sind jederzeit erreichbar, und ein Wechsel kostet nichts. Wer
mit 60 Würfen unter SHA-256 steht, schaut bei Coleman vorbei und findet die 60 Würfe
beim Zurückkommen unverändert.

**Architektur:** Eine `TabView` mit drei Reitern. Das Verfahren **ist** der Reiter, die
Verfahrenswahl-Seite entfällt. Jeder Reiter hält seinen eigenen Zustand, weil SwiftUI die
Ansichten einer `TabView` über den Wechsel hinweg am Leben lässt.

**Tech Stack:** SwiftUI `TabView`, `@State` je Reiter, Swift Package `Pips39Core`
unverändert.

**Vorhanden:** 218 Tests grün, zwölf Phasen umgesetzt, Repo öffentlich.

---

## Warum die alte Begründung nicht mehr trägt

Spec 2.1 verbietet einen dauerhaft sichtbaren Verfahrensumschalter. Die Begründung war
konkret: Wer eine Wurffolge notiert, später mit anders stehender Einstellung nachrechnet
und andere Wörter bekommt, hält sein Backup für kaputt.

**Diesen Menschen gibt es hier nicht mehr.** Seit Phase 12 sagt die erste
Onboarding-Seite, dass aus dieser App keine Seeds für echtes Geld kommen. Wer nichts
aufhebt, kann auch nichts falsch nachrechnen. Die App ist zum Ausprobieren da, und
Ausprobieren heißt, die Wege nebeneinander zu haben.

Was von 2.1 bleibt und bleiben muss: **Das Verfahren steht neben den Wörtern und in der
Aufzeichnung.** Nach dem dritten Versuch weiß sonst niemand mehr, welche Wörter woher
kamen. Dieser Teil wird nicht angefasst.

> [!important] Der Zustand je Reiter ist die ganze Idee
> Ohne ihn wäre der Wechsel ein Verwerfen mit Rückfrage, also schlechter als heute. Mit
> ihm ist er folgenlos. `TabView` hält die Ansichten ihrer Reiter am Leben, `@State`
> überlebt den Wechsel. **Task 6 prüft das als Erstes nach**, denn darauf ruht alles.

## Die neue Aufteilung

| Reiter | Symbol | Inhalt |
|---|---|---|
| SHA-256 | `number` | Startseite, würfeln, Wörter, Aufzeichnung, Abschreibkontrolle |
| Coleman | `list.number` | dasselbe mit dem anderen Verfahren |
| Worttabelle | `tablecells` | direkt die Tabelle, immer 24 Wörter |

Die Startseite eines Würfel-Reiters zeigt: Umgebungshinweis, Verfahrensname mit seinem
Einzeiler und der Wurfzahl, den Seed-Längen-Schalter und einen Knopf zum Loswürfeln. Das
ist die alte `MethodChoiceView`, auf ein Verfahren eingedampft.

## Dateien

- Create `Pips39/Pips39/RollingFlow.swift` — ein Würfel-Reiter mit eigenem Zustand
- Rewrite `Pips39/Pips39/ContentView.swift` — Onboarding, dann `TabView`
- Modify `Pips39/Pips39/LookupView.swift` — kein `onExit` mehr, „Fertig" setzt zurück
- Modify `Pips39/Pips39/RollingView.swift` — Rückfragetext ohne Verfahrenswahl
- **Delete** `Pips39/Pips39/MethodChoiceView.swift`
- Modify `Pips39/Pips39/de.lproj/Localizable.strings`

---

### Task 1: `RollingFlow` — ein Reiter mit eigenem Zustand

**Files:**
- Create: `Pips39/Pips39/RollingFlow.swift`

- [x] **Step 1: Die Datei anlegen**

```swift
import SwiftUI
import Pips39Core

/// Ein Würfel-Reiter: Startseite, würfeln, Wörter, Aufzeichnung, Abschreibkontrolle.
///
/// Das Verfahren steht fest und kommt von außen. Jeder Reiter hat seine eigene Instanz
/// und damit seinen eigenen `@State`. SwiftUI hält die Ansichten einer `TabView` über
/// den Wechsel hinweg am Leben, deshalb steht ein angefangener Durchlauf beim
/// Zurückkommen unverändert da.
///
/// Genau das ist der Zweck: Die App ist zum Ausprobieren da. Ein Wechsel, der 60 Würfe
/// wegwirft, hält niemanden zum Ausprobieren an.
struct RollingFlow: View {

    let method: DiceMethod
    @ObservedObject var probe: EnvironmentProbe

    private enum Step {
        case rolling
        case words
        case verifying
        case checking(TranscriptionCheck)
    }

    @State private var length: SeedLength = .standard
    @State private var session: DiceSession?
    @State private var step: Step = .rolling

    var body: some View {
        if let session {
            switch step {
            case .rolling:
                RollingView(session: session) {
                    step = .words
                } onBack: {
                    startOver()
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
            startPage
        }
    }

    // MARK: Die Startseite des Reiters

    private var startPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TopBar()

                EnvironmentNotice(probe: probe)

                VStack(alignment: .leading, spacing: 6) {
                    Text(method.title)
                        .font(.largeTitle.bold())
                    Text(method.summary())
                        .font(.footnote)
                    Text(method.rollCountHint(for: length))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Seed length")
                        .font(.headline)
                    Picker("Seed length", selection: $length) {
                        ForEach(SeedLength.allCases) { option in
                            Text(option.title()).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button {
                    session = DiceSession(method: method, length: length)
                    step = .rolling
                } label: {
                    Text("Start rolling")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("The method travels with the result. Write it down together with your words.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func startOver() {
        session?.discard()
        session = nil
        step = .rolling
    }
}

#Preview {
    RollingFlow(method: .sha256, probe: EnvironmentProbe())
}
```

- [x] **Step 2: Bauen**

Der Build läuft noch mit der alten `ContentView` durch; `RollingFlow` wird erst in
Task 3 benutzt.

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | grep -E "error:|BUILD" | tail -3
```
Expected: `** BUILD SUCCEEDED **`

---

### Task 2: `LookupView` wird ein Reiter

**Files:**
- Modify: `Pips39/Pips39/LookupView.swift`

Ein Reiter hat kein Zurück. Der Weg hinaus ist der Reiterwechsel.

- [x] **Step 1: `onExit` entfernen**

Die Eigenschaft streichen:

```swift
struct LookupView: View {

    private let totalWords = LookupTable.rolledWords(for: .twentyFour)
```

Die Leiste behält nur die Hilfe:

```swift
    private var bar: some View {
        TopBar()
    }
```

Der Abschluss-Knopf setzt zurück, statt zu verlassen:

```swift
            Button("Start again") {
                wordNumber = 1
                dice = []
                isFinished = false
            }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
```

Die Vorschau nachziehen:

```swift
#Preview {
    LookupView()
}
```

- [x] **Step 2: Bauen**

Der Build **muss** an `ContentView` scheitern, die `LookupView` noch mit `onExit`
aufruft. Task 3 schließt das.

---

### Task 3: `ContentView` auf drei Reiter

**Files:**
- Rewrite: `Pips39/Pips39/ContentView.swift`
- Delete: `Pips39/Pips39/MethodChoiceView.swift`

- [x] **Step 1: `ContentView` ersetzen**

```swift
import SwiftUI
import Pips39Core

/// Onboarding, danach drei Reiter, die nebeneinander stehen bleiben.
///
/// Vorher führte eine Verfahrenswahl in genau einen Weg, und der Rückweg verwarf alles.
/// Die App ist aber zum Ausprobieren da: Alle drei Wege bleiben erreichbar, und der
/// Wechsel kostet nichts, weil jeder Reiter seinen eigenen Zustand hält.
struct ContentView: View {

    enum Tab: Hashable {
        case sha256
        case coleman
        case lookupTable
    }

    @StateObject private var probe = EnvironmentProbe()
    @State private var hasStarted = false
    @State private var showsHelp = false
    @State private var tab: Tab = .sha256

    var body: some View {
        content
            .environment(\.showHelp) { showsHelp = true }
            .sheet(isPresented: $showsHelp) {
                HelpView(onClose: { showsHelp = false }, probe: probe)
            }
    }

    @ViewBuilder
    private var content: some View {
        if !hasStarted {
            OnboardingView(probe: probe) { destination in
                // Die Wahl auf Seite 3 stellt den Reiter ein, sperrt aber keinen.
                if destination == .lookupTable { tab = .lookupTable }
                hasStarted = true
            }
        } else {
            TabView(selection: $tab) {
                RollingFlow(method: .sha256, probe: probe)
                    .tabItem { Label("SHA-256", systemImage: "number") }
                    .tag(Tab.sha256)

                RollingFlow(method: .coleman, probe: probe)
                    .tabItem { Label("Coleman", systemImage: "list.number") }
                    .tag(Tab.coleman)

                LookupView()
                    .tabItem { Label("Word table", systemImage: "tablecells") }
                    .tag(Tab.lookupTable)
            }
        }
    }
}

#Preview {
    ContentView()
}
```

- [x] **Step 2: Die Verfahrenswahl löschen**

```bash
cd "$REPO"
git rm Pips39/Pips39/MethodChoiceView.swift
```

> [!note] Was aus ihren Texten wird
> `"Seed length"` und `"The method travels with the result…"` wandern in `RollingFlow`
> und bleiben in Gebrauch. Verwaist sind danach: `"Roll dice, get a BIP39 seed phrase.
> Nothing is stored."`, `"Choose a method"`, `"DEFAULT"`, `"Roll without a printout"`,
> `"Lookup table"`, `"For dice and a hardware wallet…"`, `"Always 24 words."` und
> `"Method from the BitBox02 dice guide by Shift Crypto, CC BY-SA 4.0."` **Die
> Herkunftsangabe darf nicht verschwinden**, sie steht weiter im Abschluss von
> `LookupView` — vor dem Löschen prüfen:
> ```bash
> grep -c "Method from the BitBox02" Pips39/Pips39/LookupView.swift
> ```
> Expected: `1`

- [x] **Step 3: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | grep -E "error:|BUILD" | tail -3
```
Expected: `** BUILD SUCCEEDED **`

> [!warning] Synchronisierte Dateigruppen
> Das Projekt benutzt `PBXFileSystemSynchronizedRootGroup`. Eine gelöschte Datei
> verschwindet von selbst aus dem Ziel, die `project.pbxproj` wird **nicht** angefasst.
> Taucht sie im Diff trotzdem auf, hat Xcode etwas anderes hineingeschrieben; dann auf
> `DEVELOPMENT_TEAM` prüfen.

---

### Task 4: Der Rückfragetext stimmt nicht mehr

**Files:**
- Modify: `Pips39/Pips39/RollingView.swift`
- Modify: `Pips39/Pips39/de.lproj/Localizable.strings`

Zurück führt jetzt auf die Startseite desselben Reiters. Das Verfahren steht dort fest,
neu zu wählen ist nur die Seed-Länge.

- [x] **Step 1: Den Text austauschen**

In `RollingView.swift`:

```swift
            Text("Going back means choosing the seed length again. Your rolls so far cannot be carried over.")
```

- [x] **Step 2: Die Übersetzungen nachziehen**

In `de.lproj/Localizable.strings` die alte Zeile ersetzen und die neuen Schlüssel
anhängen:

```
"Going back means choosing the seed length again. Your rolls so far cannot be carried over." = "Zurückgehen heißt, die Seed-Länge neu zu wählen. Die bisherigen Würfe lassen sich nicht mitnehmen.";
"Start rolling" = "Loswürfeln";
"Start again" = "Von vorn";
"Word table" = "Worttabelle";
```

- [x] **Step 3: Verwaiste Schlüssel entfernen**

Die acht aus Task 3 Step 2. Danach prüfen, dass nichts Lebendiges getroffen wurde:

```bash
cd "$REPO/Pips39/Pips39"
awk -F'"' '/^"/{print $2}' de.lproj/Localizable.strings | sort -u | while IFS= read -r k; do
  grep -rqF --include='*.swift' "\"$k\"" . || echo "  ohne Fundstelle: $k"
done
```
Expected: nur die fünf Schlüssel mit Formatplatzhalter (`%lld`, `%@`). Alles andere in
der Liste ist ein Fehler und muss zurück.

> [!warning] Vier gerade Anführungszeichen je Zeile
> ```bash
> grep -n '^"' de.lproj/Localizable.strings | grep -v '\\"' \
>   | awk -F: '{n=gsub(/"/,"\"",$0); if (n!=4) print "FEHLER", $0}'
> ```

- [x] **Step 4: Bauen, installieren, committen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | grep -E "error:|BUILD" | tail -3
xcrun simctl install B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF \
  "$HOME/Library/Developer/Xcode/DerivedData/Pips39-aawmoserexodpgbwggjkeytgithp/Build/Products/Debug-iphonesimulator/Pips39.app"
cd "$REPO"
git add -A Pips39/Pips39
git commit -m "feat: drei Reiter statt Verfahrenswahl"
```

---

### Task 5: Bildschirmschutz nachprüfen

**Files:** keine

Der Wunsch war, die Ansicht mit Wurffolge und Entropie zu schützen. **Sie ist es
bereits**, seit Phase 5.

- [x] **Step 1: Nachsehen statt hinzufügen**

```bash
cd "$REPO/Pips39/Pips39"
grep -n "screenProtected()\|hiddenFromScreenCapture()" VerifyView.swift
```
Expected: beide Modifier, auf der äußersten Ebene der `ScrollView`.

- [x] **Step 2: Den Stand aller Ansichten festhalten**

```bash
for f in *.swift; do
  p=$(grep -c "screenProtected()" $f); h=$(grep -c "hiddenFromScreenCapture()" $f)
  [ "$p" != "0" -o "$h" != "0" ] && printf "%-28s %s %s\n" "$f" "$p" "$h"
done
```

Erwartet: `WordsView`, `VerifyView`, `LookupView` mit beidem, `TranscriptionView` nur mit
`screenProtected`.

> [!note] Warum die Würfelansicht ungeschützt bleibt
> Dort steht kein Seed-Material auf dem Schirm, nur sechs Würfelflächen und ein Zähler.
> Die Wurffolge selbst wird erst in `VerifyView` sichtbar, und die ist geschützt. Ein
> Schutz ohne Anlass würde die Verdeckung dorthin gewöhnen, wo sie nichts bedeutet.
>
> `TranscriptionView` zeigt bewusst nur Positionen und keine bestätigten Wörter, deshalb
> reicht dort `screenProtected` ohne die Aufnahmesperre.

---

### Task 6: Sichtprüfung

Vor jedem Durchgang bauen **und** installieren.

- [x] **Step 1: Der Zustand überlebt den Reiterwechsel**

Das ist die Prüfung, an der die ganze Phase hängt. Zuerst.

1. Onboarding überspringen, Reiter SHA-256, 12 Wörter, Loswürfeln
2. Fünf Würfe eingeben, Zähler steht auf „5 von 50 Würfen"
3. Auf Coleman wechseln, dort die Startseite ansehen
4. Zurück auf SHA-256

Erwartet: **„5 von 50 Würfen", dieselben fünf Würfe.** Steht dort wieder die Startseite,
trägt die Annahme nicht und der Zustand muss aus `RollingFlow` heraus nach `ContentView`
wandern (drei Zustandssätze dort, per Reiter durchgereicht). In dem Fall hier abbrechen
und Rücksprache halten.

- [x] **Step 2: Beide Würfel-Reiter arbeiten getrennt**

Unter Coleman ebenfalls würfeln, dann zwischen den Reitern hin und her. Die
Fortschrittsanzeigen müssen unterschiedlich bleiben, Coleman zählt Bits, SHA-256 Würfe.

- [x] **Step 3: Die Worttabelle**

Reiter Worttabelle, drei Würfel eingeben, Raster prüfen. Auf SHA-256 und zurück: Das
Raster muss noch stehen.

- [x] **Step 4: Die Hilfe auf allen Reitern**

Oben rechts, auf jeder der drei Startseiten und in jedem Schritt des Würfelablaufs.

- [x] **Step 5: Onboarding stellt den Reiter ein**

App neu starten, auf Seite 3 „Du liest den Seed ab" wählen, „Los". Erwartet: der Reiter
Worttabelle ist vorgewählt, und die beiden anderen sind trotzdem erreichbar.

---

## Abschluss der Phase

- [x] **Spec 2.1 revidieren:** Der Abschnitt verbietet einen dauerhaft sichtbaren
      Verfahrensumschalter. Die Begründung nennt jemanden, der eine Wurffolge aufhebt und
      später falsch nachrechnet. Seit Phase 12 sagt die App, dass hier keine Seeds für
      echtes Geld entstehen, damit gibt es diesen Menschen nicht mehr. Den Abschnitt um
      diese Revision ergänzen, die alte Begründung **stehen lassen** und datieren.
      Unverändert bleibt: Das Verfahren steht neben den Wörtern und in der Aufzeichnung.

- [x] **Spec 3 nachziehen:** Der Ablauf beginnt nicht mehr mit der Verfahrenswahl.

- [x] **README nachziehen:** Der Abschnitt zum Onboarding beschreibt eine Verzweigung,
      die einen Weg auswählt. Sie wählt jetzt nur noch einen Reiter vor.

> [!warning] Vor dem Push: der Hook prüft auf `DEVELOPMENT_TEAM`
> Er bricht den Commit ab, wenn eine zehnstellige Team-ID in den gestagten Änderungen
> steht. Aktiv nur mit `git config core.hooksPath scripts/githooks`.

## Was danach kommt (nicht Teil dieses Plans)

- App-Store-Einreichung: Beschreibung in beiden Sprachen, Screenshots
- Die Checkliste zum Abschotten steht doppelt, im Onboarding und in der Hilfe
- Offen aus Phase 4: `SecureLayer` ist nur auf echter Hardware prüfbar
