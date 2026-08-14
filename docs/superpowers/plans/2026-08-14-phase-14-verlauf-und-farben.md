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

## Rot fällt aus, und ersetzt wird es nicht durch eine Farbe

Auf dem Verlauf kommt Systemrot auf **2,15:1**. Selbst ein aufgehelltes Rot bleibt bei
2,64. Damit sind die wichtigsten Sätze der App unlesbar: die Warnung auf
Onboarding-Seite 1 und „Die App sieht den Seed vollständig" auf der Verzweigungsseite.

Der naheliegende Ersatz wäre eine hellere Warnfarbe. Bernstein `FFC64D` trüge 4,69:1.
**Gemessen ist eine dunkle durchscheinende Fläche aber besser**, weil sie den Text nicht
schwächt, sondern stärkt:

| Fläche über dem Verlauf | sichtbar gegen Grund | weißer Text darauf |
|---|---|---|
| Schwarz 35 % | 1,54 bis 1,62:1 | **11,9 bis 12,9:1** |
| Bernstein 25 % | 1,47:1 | 5,69:1 |
| Weiß 25 % | 1,79:1 | 4,35:1 |
| blanker Verlauf | | 7,33 bis 8,37:1 |

Eine helle Fläche kauft Sichtbarkeit mit Lesbarkeit, eine dunkle bekommt beides. Damit
braucht die App **überhaupt keine zweite Farbe**: zwei Violetttöne, Weiß, Transparenz.

> [!important] Was das Signal trägt, wenn keine Farbe mehr da ist
> | Stelle | Mittel |
> |---|---|
> | Onboarding 1 und 2 | weiß fett, ohne Fläche. Der Satz ist der Inhalt der Seite. |
> | „Die App sieht den Seed vollständig" | weiß fett auf dunkler Fläche, weil er sich vom Fließtext darüber abheben muss |
> | Musterhinweis beim Würfeln | dunkle Fläche, weißer fetter Text, das vorhandene Warndreieck |
> | Verwerfen-Knopf | weiß mit `trash`-Symbol. Unterscheidung zu „Hilfe" über die Form, nicht die Farbe. |
>
> Fett allein reicht dort nicht, wo der Satz zwischen anderem weißen Text steht. Dieselbe
> Strichstärke in derselben Farbe übersieht man beim Überfliegen.

## Der Farbsatz

| Rolle | Wert | Wofür |
|---|---|---|
| `gradientTop` | `8E229D` | oben |
| `gradientBottom` | `6826B2` | unten |
| Akzent | `.white` | Links, Auswahl, Reiterleiste |
| prominenter Knopf | weiße Fläche, Schrift `6826B2` | Loswürfeln, Notiert, Weiter |
| `surface` | `Color.white.opacity(0.12)` | Würfelflächen, Karten |
| `panel` | `Color.black.opacity(0.35)` | Warnungen, Hinweise |

**Keine Warnfarbe.** Warnungen tragen weiße fette Schrift, eine dunkle Fläche und, wo
vorhanden, ihr Symbol.

## Dateien

- Create `Pips39/Pips39/BrandTheme.swift` — Farben, Verlauf, Knopfstil
- Modify `Pips39/Pips39/Pips39App.swift` — Farbschema und Akzent
- Modify `Pips39/Pips39/ContentView.swift` — Verlauf als Hintergrund
- Modify die neun Ansichten, die heute Systemfarben benutzen
- Modify `Pips39/Pips39/ScreenProtection.swift` — der Schnappschuss-Hinweis ist heute rot

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

    /// Flächen für Würfel und Karten. Durchscheinendes Weiß statt `Color.secondary`,
    /// das auf Violett schlammig wird.
    static let surface = Color.white.opacity(0.12)

    /// Die Fläche unter Warnungen und Hinweisen. **Es gibt keine Warnfarbe.**
    ///
    /// Auf diesem Violett kommt Systemrot auf 2,15:1 und ist unlesbar. Bernstein trüge
    /// 4,69:1, kostet aber Textkontrast. Eine dunkle durchscheinende Fläche gewinnt
    /// beides: Sie hebt sich mit 1,54 bis 1,62:1 vom Grund ab und trägt weißen Text
    /// mit 11,9 bis 12,9:1, also besser als der blanke Verlauf mit 7,3:1.
    ///
    /// Das Signal „Achtung" trägt danach das Symbol und die Strichstärke, nicht die
    /// Farbe. Die Palette bleibt bei zwei Violetttönen, Weiß und Transparenz.
    static let panel = Color.black.opacity(0.35)

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

- [ ] **Step 1: Die vier Stellen finden**

```bash
cd "$REPO/Pips39/Pips39"
grep -n "Color.red\|foregroundStyle(.red)\|\.orange\|Color.orange" *.swift
```

- [ ] **Step 2: Freistehende Warnungen — weiß und fett, keine Fläche**

Die beiden Warnsätze im Onboarding (`introPage`, `basicsPage`) sind der Inhalt ihrer
Seite und stehen für sich. Statt `.foregroundStyle(.red)`:

```swift
                .fontWeight(.semibold)
```

- [ ] **Step 3: Eingebettete Warnungen — weiß fett auf `Brand.panel`**

Der Satz auf der Verzweigungsseite steht mitten im Fließtext und braucht die Fläche,
weil dieselbe Strichstärke in derselben Farbe beim Überfliegen untergeht. In
`OnboardingView`, wo heute `.foregroundStyle(.red)` steht:

```swift
                        Text(option.exposure())
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Brand.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
```

Genauso die drei Hinweisleisten, die heute orange oder rot sind. In `RollingView`
(`patternNotice`), `WordsView` (Musterhinweis) und `ScreenProtection`
(`screenshotNotice`) die zwei Farbzeilen austauschen:

```swift
            .padding(12)
            .background(Brand.panel)
            .clipShape(RoundedRectangle(cornerRadius: 10))
```

Die Zeile `.foregroundStyle(.orange)` beziehungsweise `.foregroundStyle(.red)` fällt
ersatzlos weg. Das Symbol daneben (`exclamationmark.triangle.fill`, `camera.fill`)
bleibt und trägt jetzt die Bedeutung allein.

`ScreenProtection.swift:74` braucht zusätzlich die `clipShape`-Zeile, die dort heute
fehlt, sonst läuft die Fläche über die volle Breite.

- [ ] **Step 4: „Verwerfen" wird ein Papierkorb**

Der destruktive Knopf oben links in `WordsView` benutzt `role: .destructive` und ist
damit systemrot, auf Violett unlesbar. Weiße Schrift allein wäre von „Hilfe" rechts
daneben nicht zu unterscheiden. Deshalb trägt hier die **Form** den Unterschied:

```swift
            Button(role: .destructive) {
                showsDiscardConfirmation = true
            } label: {
                Label("Discard", systemImage: "trash")
                    .font(.body)
            }
            .tint(.white)
```

`role: .destructive` bleibt stehen: Es bestimmt nicht nur die Farbe, sondern auch, wie
VoiceOver den Knopf ansagt.

> [!warning] Der Rückfragedialog bleibt systemrot, und das ist richtig so
> `confirmationDialog` zeichnet iOS selbst, auf eigenem Grund. Dort ist Rot lesbar und
> bedeutet dasselbe wie überall im System. Nur die Knöpfe **in** der App wechseln.

- [ ] **Step 5: Bauen und committen**

```bash
cd "$REPO"
git add -A Pips39/Pips39
git commit -m "feat: Warnungen tragen Flaeche und Symbol statt Farbe"
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

Onboarding-Seite 1 und 2 tragen weiße fette Sätze ohne Fläche, die Verzweigungsseite
den Satz auf dunkler Fläche. Prüfen, dass die Fläche sich vom Grund abhebt, ohne wie ein
Loch im Verlauf zu wirken. Fällt sie zu schwach aus, `Brand.panel` auf 0,45 anheben.

- [ ] **Step 4: Der Musterhinweis**

50 gleiche Würfe. Die Meldung steht weiß auf dunkler Fläche, mit dem Warndreieck.
Prüfen, dass sie als Hinweis erkennbar ist, obwohl keine Farbe mehr mitspielt.

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
      Begründung für die Abdunklung und der dafür, dass Warnungen eine dunkle Fläche
      tragen statt einer Farbe. Die gemessenen Kontraste mit aufnehmen, sonst wird beim
      nächsten Umlackieren wieder Rot genommen.

- [ ] **README:** Der Abschnitt zu den Design-Entscheidungen bekommt einen Satz dazu.

> [!warning] Vor dem Push: der Hook prüft auf `DEVELOPMENT_TEAM`

## Was danach kommt (nicht Teil dieses Plans)

- App-Store-Einreichung: Beschreibung, Screenshots
- Offen aus Phase 13: Das 24. Wort in der App ausrechnen, zurückgestellt
- Offen aus Phase 4: `SecureLayer` ist nur auf echter Hardware prüfbar
