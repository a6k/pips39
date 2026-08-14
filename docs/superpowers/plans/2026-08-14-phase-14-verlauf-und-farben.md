# Pips39 — Phase 14: Verlauf über den ganzen Schirm — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die App trägt den Verlauf des App-Icons über den ganzen Schirm, bis hinter
Statusleiste und Home-Indikator, und bleibt dabei überall lesbar.

**Architektur:** Ein Farbsatz an einer Stelle, ein Verlauf als Hintergrund der
Wurzelansicht mit `.ignoresSafeArea()`, und `.preferredColorScheme(.dark)`, damit
System-Bausteine von selbst hell werden. Alle Flächen, die heute eine Systemfarbe
benutzen, wechseln auf durchscheinendes Weiß.

**Tech Stack:** SwiftUI, `LinearGradient`, `Color` im Asset-freien Code.

**Vorhanden:** 218 Tests grün, dreizehn Phasen umgesetzt, Repo öffentlich.

---

## Warum die Icon-Farben nicht direkt gehen

Gemessen nach WCAG, Kontrast gegen Weiß und gegen Schwarz:

| Farbe | Leuchtdichte | zu Weiß | zu Schwarz |
|---|---|---|---|
| `CB30E0` oben | 0,202 | **4,17:1** | 5,04:1 |
| `9437FF` unten | 0,163 | 4,94:1 | **4,25:1** |

Normaler Text braucht 4,5:1. Weißer Text reißt oben, schwarzer unten. Egal welchen
Textton man wählt, an einem Ende des Schirms fällt er durch, und das trifft die
Seed-Wörter.

**Lösung: beide Farben auf 70 Prozent ihrer Helligkeit.** Derselbe Farbton, satter.

| Farbe | neu | weißer Text |
|---|---|---|
| oben | `8E229D` | 7,33:1 |
| unten | `6826B2` | 8,37:1 |

7:1 ist die komfortable Stufe, nicht nur das Mindestmaß.

## Rot fällt aus, und das ist die eigentliche Arbeit

Auf dem Verlauf kommt Systemrot auf **2,15:1**. Selbst ein aufgehelltes Rot bleibt bei
2,64. Damit sind die beiden wichtigsten Sätze der App unlesbar: die Warnung auf
Onboarding-Seite 1 und „Die App sieht den Seed vollständig" auf der Verzweigungsseite.

Gemessen auf dem neuen Verlauf:

| Kandidat | | oben | unten |
|---|---|---|---|
| Systemrot | `FF453A` | 2,15:1 | 2,46:1 |
| Lachs | `FF8A80` | 3,21:1 | 3,67:1 |
| Rosé | `FFB4AB` | 4,32:1 | 4,93:1 |
| **Bernstein** | `FFC64D` | **4,69:1** | **5,36:1** |

> [!important] Warnfarbe wird Bernstein, nicht Rot
> `FFB4AB` läge knapp über der Grenze, sieht auf Violett aber wie ein blasses Rosa aus
> und liest sich nicht mehr als Warnung. Bernstein trägt sowohl den Kontrast als auch
> die Bedeutung.
>
> **Damit fällt der Unterschied zwischen der roten Warnung und dem orangen
> Musterhinweis weg.** Das ist hinnehmbar: Beide sagen dasselbe, nämlich „hier stimmt
> etwas nicht, lies genau". Zwei Warntöne, die sich auf Violett kaum unterscheiden
> lassen, wären schlechter als einer, der sitzt.

## Die Akzentfarbe zieht in zwei Richtungen

Ein Akzent muss zwei Dinge zugleich können, und die widersprechen sich:

- Als getönter Text auf dem Verlauf braucht er Kontrast **gegen Violett**
- Als Füllung eines `borderedProminent`-Knopfes trägt er eine weiße Beschriftung und
  braucht Kontrast **gegen Weiß**

Gelb schafft das Erste (5,19:1) und scheitert am Zweiten, weiße Schrift auf Gelb ist
unlesbar. Systemblau scheitert schon am Ersten mit 2,01:1.

**Lösung: der Akzent ist Weiß, und prominente Knöpfe drehen den Kontrast um.** Weiße
Fläche mit violetter Schrift:

- weiße Fläche auf dem Verlauf: 7,33:1 bis 8,37:1
- Schrift `6826B2` auf der weißen Fläche: 8,37:1

Damit sind Knopf und Beschriftung beide komfortabel, und der Knopf hebt sich als Form
vom Hintergrund ab, statt sich über die Farbe behaupten zu müssen.

## Der Farbsatz

| Rolle | Wert | Wofür |
|---|---|---|
| `gradientTop` | `8E229D` | oben |
| `gradientBottom` | `6826B2` | unten |
| Akzent | `.white` | Links, Auswahl, Reiterleiste |
| prominenter Knopf | weiße Fläche, Schrift `6826B2` | Loswürfeln, Notiert, Weiter |
| Warnung | `FFC64D` | Warnsätze und Musterhinweis |
| Flächen | `Color.white.opacity(0.12)` | Würfelflächen, Karten, Hinweisleisten |

## Dateien

- Create `Pips39/Pips39/BrandTheme.swift` — Farben, Verlauf, Knopfstil
- Modify `Pips39/Pips39/Pips39App.swift` — Farbschema und Akzent
- Modify `Pips39/Pips39/ContentView.swift` — Verlauf als Hintergrund
- Modify die neun Ansichten, die heute Systemfarben benutzen
- Modify `Pips39/Pips39/ScreenProtection.swift` — der Schutz blendet auf `Color.red.opacity(0.1)` ab

---

### Task 1: Der Farbsatz an einer Stelle

**Files:**
- Create: `Pips39/Pips39/BrandTheme.swift`

- [ ] **Step 1: Die Datei anlegen**

```swift
import SwiftUI

/// Die Farben der App an einer Stelle.
///
/// Die beiden Verlaufsfarben sind die des App-Icons auf 70 Prozent ihrer Helligkeit.
/// Im Original (`CB30E0` und `9437FF`) trägt weißer Text oben nur 4,17:1 und fällt
/// damit unter das Mindestmaß von 4,5. Abgedunkelt sind es 7,33:1 und 8,37:1, also
/// die komfortable Stufe. Derselbe Farbton, satter.
enum Brand {

    static let gradientTop = Color(red: 0x8E/255, green: 0x22/255, blue: 0x9D/255)
    static let gradientBottom = Color(red: 0x68/255, green: 0x26/255, blue: 0xB2/255)

    /// Warnungen und Hinweise. **Nicht Rot**: Auf diesem Violett kommt Systemrot auf
    /// 2,15:1 und ist damit unlesbar. Bernstein trägt 4,69:1 und liest sich weiterhin
    /// als Warnung.
    static let warning = Color(red: 0xFF/255, green: 0xC6/255, blue: 0x4D/255)

    /// Flächen für Würfel, Karten und Hinweisleisten. Durchscheinendes Weiß statt
    /// `Color.secondary`, das auf Violett schlammig wird.
    static let surface = Color.white.opacity(0.12)

    static var background: LinearGradient {
        LinearGradient(colors: [gradientTop, gradientBottom],
                       startPoint: .top, endPoint: .bottom)
    }
}

/// Prominente Knöpfe drehen den Kontrast um: weiße Fläche, violette Schrift.
///
/// Ein farbiger Knopf mit weißer Schrift ginge hier nicht. Der Akzent müsste zugleich
/// Kontrast gegen das violette Umfeld und gegen die eigene weiße Beschriftung tragen,
/// und das schließt sich aus.
struct BrandProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Brand.gradientBottom)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

extension ButtonStyle where Self == BrandProminentButtonStyle {
    static var brandProminent: BrandProminentButtonStyle { BrandProminentButtonStyle() }
}
```

- [ ] **Step 2: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | grep -E "error:|BUILD" | tail -3
```
Expected: `** BUILD SUCCEEDED **`

---

### Task 2: Verlauf und Farbschema

**Files:**
- Modify: `Pips39/Pips39/Pips39App.swift`
- Modify: `Pips39/Pips39/ContentView.swift`

- [ ] **Step 1: Farbschema und Akzent am Einstieg setzen**

`Pips39App.swift` vollständig:

```swift
import SwiftUI

@main
struct Pips39App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Erzwungen dunkel, damit `.primary` weiß wird, `.secondary` hell
                // grau und die Symbole der Statusleiste hell. Ohne das stünde auf
                // dem violetten Grund schwarzer Text.
                .preferredColorScheme(.dark)
                .tint(.white)
        }
    }
}
```

- [ ] **Step 2: Den Verlauf hinter alles legen**

In `ContentView.body`, der Verlauf **hinter** dem Inhalt und über den sicheren Bereich
hinaus:

```swift
    var body: some View {
        content
            .background {
                Brand.background.ignoresSafeArea()
            }
            .environment(\.showHelp) { showsHelp = true }
            .sheet(isPresented: $showsHelp) {
                HelpView(onClose: { showsHelp = false }, probe: probe)
            }
    }
```

> [!warning] Die Reiterleiste bringt ihren eigenen Grund mit
> `TabView` legt unter die Leiste ein Material, das den Verlauf dort abdeckt. Mit
> `.preferredColorScheme(.dark)` wird es dunkel und passt, es ist aber **nicht** der
> Verlauf. Wer das ändern will, braucht `.toolbarBackground(.hidden, for: .tabBar)`;
> dann steht die Leiste ohne Trennung im Bild und die Symbole schwimmen. In Task 6
> ansehen und entscheiden, nicht vorher festlegen.

- [ ] **Step 3: Bauen und ansehen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | grep -E "error:|BUILD" | tail -3
xcrun simctl install B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF \
  "$HOME/Library/Developer/Xcode/DerivedData/Pips39-aawmoserexodpgbwggjkeytgithp/Build/Products/Debug-iphonesimulator/Pips39.app"
```

Erwartet: violetter Grund bis in die Statusleiste, weiße Uhrzeit. Texte sind weiß, aber
die Flächen darauf sehen noch falsch aus. Das räumt Task 3 auf.

---

### Task 3: Die Flächen

**Files:**
- Modify: `EnvironmentNotice.swift`, `OnboardingView.swift`, `LookupView.swift`,
  `RollingView.swift`, `TranscriptionView.swift`, `WordKeyboardView.swift`,
  `WordsView.swift`

Neun Stellen benutzen heute `Color.secondary.opacity(…)` oder `Color(.systemBackground)`.
Auf Violett wird beides schlammig oder weiß.

- [ ] **Step 1: Ersetzen**

```bash
cd "$REPO/Pips39/Pips39"
grep -n "Color.secondary.opacity\|Color(.systemBackground)\|background(.bar)" *.swift
```

Jede Fundstelle nach dieser Regel:

| vorher | nachher |
|---|---|
| `Color.secondary.opacity(0.12)` | `Brand.surface` |
| `Color.secondary.opacity(0.1)` | `Brand.surface` |
| `Color.secondary.opacity(0.08)` | `Color.white.opacity(0.08)` |
| `Color.secondary.opacity(0.18)` | `Color.white.opacity(0.18)` |
| `Color.secondary.opacity(0.05)` | `Color.white.opacity(0.05)` |
| `Color(.systemBackground)` (Fußleiste `WordsView`) | `Brand.gradientBottom` |
| `.background(.bar)` (Fußleisten Onboarding) | `Color.white.opacity(0.08)` |

> [!note] Warum die Fußleiste der Wortanzeige den unteren Verlaufston bekommt
> Sie soll durchlaufende Wörter verdecken, muss also deckend sein. Am unteren Rand des
> Schirms steht ohnehin `gradientBottom`, damit fällt sie nicht auf.

- [ ] **Step 2: Prominente Knöpfe umstellen**

```bash
grep -n "buttonStyle(.borderedProminent)" *.swift
```

Jede Fundstelle auf `.buttonStyle(.brandProminent)`. Das mitgeführte
`.controlSize(.large)` entfällt, die Größe steckt im Stil.

- [ ] **Step 3: Bauen und committen**

```bash
cd "$REPO"
git add -A Pips39/Pips39
git commit -m "feat: Verlauf ueber den ganzen Schirm, Flaechen auf durchscheinendes Weiss"
```

---

### Task 4: Die Warnfarbe

**Files:**
- Modify: `OnboardingView.swift`, `WordsView.swift`, `RollingView.swift`,
  `HelpTopics.swift`, `ScreenProtection.swift`

- [ ] **Step 1: Rot ersetzen**

```bash
cd "$REPO/Pips39/Pips39"
grep -n "Color.red\|foregroundStyle(.red)\|\.orange\|Color.orange" *.swift
```

- Die beiden Warnsätze im Onboarding (`introPage`, `basicsPage`): `.foregroundStyle(Brand.warning)`
- Der Satz auf der Verzweigungsseite (`appSeesEverything`): `.foregroundStyle(Brand.warning)`
- Der Musterhinweis in `RollingView` und `WordsView`: `Brand.warning`, Fläche
  `Brand.warning.opacity(0.15)`
- `ScreenProtection.swift:73`, `Color.red.opacity(0.1)`: `Brand.warning.opacity(0.15)`

- [ ] **Step 2: „Verwerfen" bleibt unterscheidbar**

Der destruktive Knopf oben links in `WordsView` benutzt heute `role: .destructive`, was
ihn systemrot färbt. Auf Violett ist das unlesbar. Rolle behalten, Farbe überschreiben:

```swift
            Button("Discard", role: .destructive) {
                showsDiscardConfirmation = true
            }
            .font(.body)
            .foregroundStyle(Brand.warning)
```

> [!warning] Der Rückfragedialog bleibt systemrot, und das ist richtig so
> `confirmationDialog` zeichnet iOS selbst, auf eigenem Grund. Dort ist Rot lesbar und
> bedeutet dasselbe wie überall im System. Nur die Knöpfe **in** der App wechseln.

- [ ] **Step 3: Bauen und committen**

```bash
cd "$REPO"
git add -A Pips39/Pips39
git commit -m "feat: Warnfarbe Bernstein statt Rot, auf Violett unlesbar"
```

---

### Task 5: Die Hilfe

**Files:**
- Modify: `Pips39/Pips39/HelpView.swift`

Das Sheet bringt einen eigenen Grund mit, und die `List` ebenfalls.

- [ ] **Step 1: Beide durchsichtig machen**

```swift
            List {
                // ... unverändert ...
            }
            .scrollContentBackground(.hidden)
            .background { Brand.background.ignoresSafeArea() }
```

Und am `sheet` in `ContentView` nichts ändern: Das Sheet erbt `.preferredColorScheme`
von der Wurzel.

> [!note] Die Zeilen der Liste behalten ihren eigenen Grund
> `.insetGrouped` zeichnet die Zeilen als Flächen. Mit dunklem Farbschema sind die
> dunkelgrau, nicht violett. Das ist in Ordnung und sogar hilfreich: Die Hilfe ist ein
> anderer Ort als die App darunter. Wer sie auch violett will, setzt zusätzlich
> `.listRowBackground(Brand.surface)`.

- [ ] **Step 2: Bauen und committen**

---

### Task 6: Sichtprüfung

Vor jedem Durchgang bauen **und** installieren.

- [ ] **Step 1: Statusleiste und Ränder**

Verlauf muss oben hinter Uhrzeit und Batterie stehen und unten hinter dem
Home-Indikator. Die Symbole der Statusleiste müssen **hell** sein.

- [ ] **Step 2: Die Seed-Wörter**

12 Wörter würfeln, Wortanzeige. Die Wörter müssen klar lesbar sein, das ist der Fall,
an dem diese Phase gemessen wird. Ebenso die Aufzeichnung mit Wurffolge und Hex.

- [ ] **Step 3: Die Warnsätze**

Onboarding-Seite 1 und 2, Verzweigungsseite. Bernstein muss sich vom weißen Fließtext
abheben, ohne wie ein Hinweis auf einen Fehler auszusehen.

- [ ] **Step 4: Der Musterhinweis**

50 gleiche Würfe. Die Meldung erscheint in Bernstein auf durchscheinendem Bernstein.
Prüfen, dass sie sich vom Warnsatz-Bernstein unterscheidet, nämlich durch die Fläche.

- [ ] **Step 5: Die Reiterleiste**

Ansehen und entscheiden, ob sie mit ihrem eigenen dunklen Grund bleibt oder auf
`.toolbarBackground(.hidden, for: .tabBar)` wechselt. **Nicht vorher festlegen.**

- [ ] **Step 6: Die eigene Tastatur**

Abschreibkontrolle öffnen. Die Buchstaben sind der dichteste Bildschirm der App, dort
fällt zu wenig Kontrast zuerst auf. Gesperrte Buchstaben müssen sich weiterhin klar von
freien unterscheiden.

- [ ] **Step 7: Der Bildschirmschutz**

App in den Hintergrund schicken und im App-Umschalter ansehen. Die Verdeckung muss
greifen und darf nicht durchsichtig auf dem Verlauf stehen.

---

## Abschluss der Phase

- [ ] **Spec ergänzen:** Ein Abschnitt 2.9 „Farben" mit den beiden Verlaufsfarben, der
      Begründung für die Abdunklung und der für Bernstein statt Rot. Die gemessenen
      Kontraste mit aufnehmen, sonst wird beim nächsten Umlackieren wieder Rot genommen.

- [ ] **README:** Der Abschnitt zu den Design-Entscheidungen bekommt einen Satz dazu.

> [!warning] Vor dem Push: der Hook prüft auf `DEVELOPMENT_TEAM`

## Was danach kommt (nicht Teil dieses Plans)

- App-Store-Einreichung: Beschreibung, Screenshots
- Offen aus Phase 13: Das 24. Wort in der App ausrechnen, zurückgestellt
- Offen aus Phase 4: `SecureLayer` ist nur auf echter Hardware prüfbar
