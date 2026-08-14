# Pips39 — Phase 11: Onboarding für Fremde — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wer die App zum ersten Mal öffnet, versteht in drei Seiten, was ein Seed ist,
warum der stärkere Weg ohne diese App auskommt und welche zwei Wege es hier gibt —
bevor irgendein Shell-Befehl auftaucht.

**Architektur:** Das Onboarding zerfällt in zwei Phasen. Drei gemeinsame Seiten enden in
einer Verzweigung; danach folgen nur noch die Seiten des gewählten Wegs. Die grobe Wahl
(rechnet die App, oder lese ich ab?) fällt im Onboarding, die feine (SHA-256 oder
Coleman, 12 oder 24) bleibt auf der Startseite.

**Tech Stack:** SwiftUI, `TabView(.page)`, Swift Package `Pips39Core` für die Texte der
beiden Wege (dort testbar ohne Simulator).

**Vorhanden:** 210 Tests grün, zehn Phasen umgesetzt, Repo öffentlich.

---

## Das Problem, benannt

Die erste Seite der App zeigt heute:

```
printf '%s' "<Wurffolge>" | shasum -a 256
```

Das ist die Antwort auf die Frage des Misstrauischen („kann ich das nachrechnen?"),
gestellt bevor die Frage des Unwissenden beantwortet ist („was ist das hier?"). Wer
nicht ohnehin tief im Thema steckt, schließt die App.

Dazu fehlt Vokabular: Die App sagt „BIP39", „Entropie", „Prüfsumme", ohne eines davon je
erklärt zu haben.

> [!important] Was **nicht** gebaut wird: ein Verbot
> Die naheliegende Formulierung „nutze diese App niemals für einen echten Seed" wird
> bewusst nicht verwendet. Sie macht die App in sich widersprüchlich — Abschreibkontrolle,
> Bildschirmschutz, Lockdown-Checkliste und Entartungsprüfung ergeben nur für einen echten
> Seed Sinn. Und sie ist wirkungslos: Ein Teil der Leute benutzt die App trotzdem echt,
> und denen hat die App dann selbst gesagt, dass ihre Sicherheitshinweise nicht ernst
> gemeint sind. Dieselbe Mechanik wie beim Fehlalarm-Argument in Phase 9.
>
> Stattdessen wird **eingeordnet**: Der stärkere Weg braucht diese App nicht, hier ist der
> Link, und wer echtes Geld absichert, nimmt ihn.

> [!warning] Eine Sachaussage, die stimmen muss
> „Nur Papier und Stift" reicht für einen vollständigen BIP39-Seed **nicht**. Das letzte
> von 24 Wörtern trägt die Prüfsumme über die anderen 23; die rechnet niemand von Hand.
> Auch der BitBox-Weg braucht am Ende ein Gerät. Seite 1 muss das sagen, sonst steht dort
> ein Versprechen, das der Nutzer nicht einlösen kann.

## Die neue Abfolge

| | Seite | Inhalt |
|---|---|---|
| **gemeinsam** | 1 · Bevor du anfängst | Einordnung, BitBox-Link, die Prüfsummen-Einschränkung |
| | 2 · Was ein Seed ist | Zahl statt Wörter, warum Zufall alles ist, geladene Würfel |
| | 3 · Zwei Wege | die beiden Karten — **hier verzweigt es** |
| **Weg A** | A1 · Die App prüfen | `shasum`, iancoleman, Quelltext — solange noch Netz da ist |
| | A2 · Abschotten | Checkliste, Umgebungshinweis, was die App nicht wissen kann |
| **Weg B** | B1 · Was du brauchst | 5 Würfel, Münze, Hardware-Wallet, ebenfalls offline |
| | B2 · Was die App sieht | 6 von 11 Bit, die 118, das 24. Wort |

Die Prüf-Seite bleibt **vor** dem Abschotten — das war die Korrektur aus Phase 7 und gilt
weiter: Sie braucht Shell und Browser. Neu ist nur, dass sie nicht mehr das Erste ist, was
ein Fremder sieht.

> [!note] Umgeräumt, nicht gelöscht
> Die heutige Seite 3 („Bereit") verschwindet als Seite. Ihre Teile wandern: der
> Bluetooth-Vorbehalt nach A2, der Würfel-Abschnitt („Zu den Würfeln") auf die
> gemeinsame Seite 2 — dort wird gerade erklärt, warum Zufall zählt, und dort gehört
> die Einschränkung hin —, und „Wie es ausgeht" nach A2.

## Wohin es danach geht

| Wahl auf Seite 3 | Landet auf |
|---|---|
| Würfeln und rechnen lassen | `MethodChoiceView` (SHA-256/Coleman, 12/24) |
| Nachschlagetabelle | direkt `LookupView` |
| **Überspringen** | `MethodChoiceView` |

`MethodChoiceView` behält seinen Nachschlagetabellen-Block aus Phase 10. Das ist
Absicht: Wer überspringt oder sich umentscheidet, darf nicht in einem Weg festsitzen.
Die Verzweigung ist eine Abkürzung, keine Sperre.

## Dateien

**Paket** — hier liegen die Texte der beiden Wege, damit Tests sie erwischen:

- Create `Sources/Pips39Core/OnboardingPath.swift` — die zwei Wege mit Titel, Kurztext
  und der Aussage, was die App dabei sieht
- Modify `Sources/Pips39Core/ExternalLinks.swift` — die BitBox-Adresse
- Create `Tests/Pips39CoreTests/OnboardingPathTests.swift`
- Modify `Tests/Pips39CoreTests/ExternalLinksTests.swift` — neue Adresse in die Liste

**App** — vier Dateien statt einer, je eine Verantwortung:

- Create `Pips39/Pips39/OnboardingPage.swift` — das Seitengerüst, heute eine private
  Funktion in `OnboardingView`
- Rewrite `Pips39/Pips39/OnboardingView.swift` — Behälter, die drei gemeinsamen Seiten,
  die Verzweigung
- Create `Pips39/Pips39/RollingOnboardingPages.swift` — A1 und A2
- Create `Pips39/Pips39/LookupOnboardingPages.swift` — B1 und B2
- Modify `Pips39/Pips39/ContentView.swift` — das Ziel aus dem Onboarding entgegennehmen
- Modify `Pips39/Pips39/de.lproj/Localizable.strings`

---

### Task 1: `OnboardingPath` im Paket

**Files:**
- Create: `Sources/Pips39Core/OnboardingPath.swift`
- Create: `Tests/Pips39CoreTests/OnboardingPathTests.swift`

- [ ] **Step 1: Den fehlschlagenden Test schreiben**

`Tests/Pips39CoreTests/OnboardingPathTests.swift`:

```swift
import XCTest
@testable import Pips39Core

final class OnboardingPathTests: XCTestCase {

    private let en = Locale(identifier: "en")
    private let de = Locale(identifier: "de")

    func testBothPathsHaveText() {
        for path in OnboardingPath.allCases {
            XCTAssertFalse(path.title(locale: en).isEmpty, "\(path)")
            XCTAssertFalse(path.summary(locale: en).isEmpty, "\(path)")
            XCTAssertFalse(path.exposure(locale: en).isEmpty, "\(path)")
        }
    }

    func testEverythingIsTranslated() {
        for path in OnboardingPath.allCases {
            XCTAssertNotEqual(path.title(locale: de), path.title(locale: en), "\(path)")
            XCTAssertNotEqual(path.summary(locale: de), path.summary(locale: en), "\(path)")
            XCTAssertNotEqual(path.exposure(locale: de), path.exposure(locale: en), "\(path)")
            XCTAssertFalse(path.summary(locale: de).contains("onboarding."), "\(path)")
            XCTAssertFalse(path.exposure(locale: de).contains("onboarding."), "\(path)")
        }
    }

    /// Die beiden Wege unterscheiden sich genau darin, was die App zu sehen bekommt.
    /// Stünde dort zweimal dasselbe, wäre die Verzweigung sinnlos.
    func testTheTwoPathsDifferInWhatTheAppSees() {
        XCTAssertNotEqual(OnboardingPath.rollAndCompute.exposure(locale: en),
                          OnboardingPath.lookupTable.exposure(locale: en))
    }

    /// Die Zahl ist die ganze Aussage des zweiten Wegs und darf nicht verlorengehen,
    /// wenn jemand den Text umformuliert. 118 kommt aus `LookupTable.hiddenBits`.
    func testTheLookupPathNamesTheNumber() {
        let text = OnboardingPath.lookupTable.exposure(locale: en)
        XCTAssertTrue(text.contains("\(LookupTable.hiddenBits(for: .twentyFour))"), text)
    }

    /// Keine Entwarnung, nirgends — dieselbe Regel wie bei `EnvironmentProbe`.
    func testNoPathPromisesSafety() {
        let forbidden = ["safe", "secure", "protected", "guaranteed"]
        for path in OnboardingPath.allCases {
            let text = (path.summary(locale: en) + " " + path.exposure(locale: en)).lowercased()
            for word in forbidden {
                XCTAssertFalse(text.contains(word), "\(path) verspricht \(word): \(text)")
            }
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

```bash
cd "$REPO" && swift test 2>&1 | grep -E "error:" | head -3
```
Expected: `cannot find 'OnboardingPath' in scope`.

- [ ] **Step 3: `OnboardingPath` schreiben**

`Sources/Pips39Core/OnboardingPath.swift`:

```swift
import Foundation

/// Die beiden grundsätzlich verschiedenen Wege durch diese App.
///
/// Das ist die **grobe** Wahl und fällt im Onboarding: Rechnet die App aus den Würfen,
/// oder liest der Nutzer ab? Die feine Wahl — SHA-256 oder Coleman, 12 oder 24 Wörter —
/// bleibt auf der Startseite, weil sie nur den ersten Weg betrifft.
///
/// Der Unterschied, auf den es ankommt, steht in `exposure(locale:)`: wie viel vom Seed
/// die App dabei zu sehen bekommt. Alles andere ist Bedienung.
public enum OnboardingPath: String, CaseIterable, Equatable, Identifiable {

    /// Würfeln, die App rechnet. Sie sieht den ganzen Seed.
    case rollAndCompute

    /// Nachschlagetabelle. Die App sieht 6 von 11 Bit je Wort.
    case lookupTable

    public var id: String { rawValue }

    public func title(locale: Locale = .current) -> String {
        Localized.string("onboarding.path.\(rawValue).title", locale)
    }

    /// Was der Nutzer tut.
    public func summary(locale: Locale = .current) -> String {
        Localized.string("onboarding.path.\(rawValue).summary", locale)
    }

    /// Was die App dabei erfährt. Der einzige Satz, der die Wahl wirklich trägt.
    public func exposure(locale: Locale = .current) -> String {
        switch self {
        case .rollAndCompute:
            return Localized.string("onboarding.path.rollAndCompute.exposure", locale)
        case .lookupTable:
            return Localized.string("onboarding.path.lookupTable.exposure", locale,
                                    LookupTable.hiddenBits(for: .twentyFour))
        }
    }
}
```

- [ ] **Step 4: Die Texte in beide Tabellen eintragen**

`Sources/Pips39Core/Localization/en.lproj/Localizable.strings` anhängen:

```
/* ===== Die zwei Wege im Onboarding ===== */
"onboarding.path.rollAndCompute.title" = "Roll, and let the app do the maths";
"onboarding.path.rollAndCompute.summary" = "You roll dice and tap in every result. The app turns them into your words and shows all of them on this screen.";
"onboarding.path.rollAndCompute.exposure" = "The app sees your whole seed. Everything that follows is about making sure this device cannot pass it on.";
"onboarding.path.lookupTable.title" = "Roll, and read the word off a table";
"onboarding.path.lookupTable.summary" = "You roll five dice and a coin, enter only the first three dice, and read your word off the table the app shows. You need a hardware wallet for the last of the 24 words.";
"onboarding.path.lookupTable.exposure" = "The app sees part of each roll and never learns which word you took. %lld bits of your seed stay hidden from it — less than the 256 you would have on paper, more than the nothing you keep on the other path.";
```

`de.lproj/Localizable.strings` anhängen:

```
/* ===== Die zwei Wege im Onboarding ===== */
"onboarding.path.rollAndCompute.title" = "Würfeln, die App rechnet";
"onboarding.path.rollAndCompute.summary" = "Sie würfeln und tippen jedes Ergebnis ein. Die App macht daraus die Wörter und zeigt alle auf diesem Bildschirm.";
"onboarding.path.rollAndCompute.exposure" = "Die App sieht den ganzen Seed. Alles Weitere dreht sich darum, dass dieses Gerät ihn nicht weitergeben kann.";
"onboarding.path.lookupTable.title" = "Würfeln, das Wort ablesen";
"onboarding.path.lookupTable.summary" = "Sie werfen fünf Würfel und eine Münze, geben nur die ersten drei Würfel ein und lesen Ihr Wort aus der Tabelle ab, die die App zeigt. Für das letzte der 24 Wörter brauchen Sie eine Hardware-Wallet.";
"onboarding.path.lookupTable.exposure" = "Die App sieht von jedem Wurf nur einen Teil und erfährt nie, welches Wort genommen wurde. %lld Bit des Seeds bleiben ihr verborgen — weniger als die 256 auf Papier, mehr als die null auf dem anderen Weg.";
```

> [!warning] Zwei Fallen, beide in diesem Projekt schon zugeschnappt
> 1. **Vier gerade Anführungszeichen je Zeile.** Ein `"` im Text bricht die Datei ohne
>    Zeilenangabe. Nach dem Eintragen prüfen:
>    ```bash
>    cd "$REPO/Sources/Pips39Core/Localization"
>    for f in en.lproj de.lproj; do
>      grep -n '^"' $f/Localizable.strings | awk -F: -v f=$f '{n=gsub(/"/,"\"",$0); if (n!=4) print "FEHLER", f, $0}'
>    done
>    ```
> 2. **`%lld`, nicht `%d`.** `Localized.string(_:_:_:)` reicht ein `Int` an
>    `String(format:)` weiter; auf 64-Bit ist `%d` falsch. Die beiden `exposure`-Zeilen
>    sind die einzigen mit Platzhalter.

- [ ] **Step 5: Test laufen lassen**

```bash
cd "$REPO" && swift test 2>&1 | grep -E "error:|failed:|Executed [0-9]+ tests, with" | tail -3
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core/OnboardingPath.swift Sources/Pips39Core/Localization \
        Tests/Pips39CoreTests/OnboardingPathTests.swift
git commit -m "feat: OnboardingPath — die grobe Wahl mit dem Satz, der sie traegt"
```

---

### Task 2: Die BitBox-Adresse

**Files:**
- Modify: `Sources/Pips39Core/ExternalLinks.swift`
- Modify: `Tests/Pips39CoreTests/ExternalLinksTests.swift`

- [ ] **Step 1: Den Test erweitern**

In `ExternalLinksTests.swift` die Liste in Zeile 7 ergänzen und einen Test anhängen:

```swift
        [ExternalLinks.colemanTool, ExternalLinks.sourceCode, ExternalLinks.bitboxGuide]
```

```swift
    /// Die Adresse des stärkeren Verfahrens. Steht auf der ersten Onboarding-Seite,
    /// also an der Stelle mit der größten Reichweite — ein Tippfehler dort schickt
    /// Leute ins Leere, statt zu dem Weg, der ohne diese App auskommt.
    func testBitboxGuidePointsAtBitbox() {
        XCTAssertTrue(ExternalLinks.bitboxGuide.contains("bitbox.swiss"),
                      ExternalLinks.bitboxGuide)
    }
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag bestätigen**

```bash
cd "$REPO" && swift test --filter ExternalLinksTests 2>&1 | grep -E "error:" | head -2
```
Expected: `type 'ExternalLinks' has no member 'bitboxGuide'`.

- [ ] **Step 3: Die Adresse eintragen**

In `Sources/Pips39Core/ExternalLinks.swift`, nach `sourceCode`:

```swift
    /// Die Würfelanleitung von Shift Crypto — der Weg, der ohne diese App auskommt.
    ///
    /// Bewusst die Startseite und kein tiefer Link: Eine Unterseite, die umzieht,
    /// schickt Leute ins Leere, und dieser Link steht an der Stelle mit der größten
    /// Reichweite. Wer eine stabile Direktadresse zur Anleitung hat, trägt sie hier
    /// ein — dann bitte vorher im Browser öffnen.
    public static let bitboxGuide = "https://bitbox.swiss"
```

- [ ] **Step 4: Test laufen lassen**

```bash
cd "$REPO" && swift test --filter ExternalLinksTests 2>&1 | grep -E "Executed [0-9]+ tests, with" | tail -1
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core/ExternalLinks.swift Tests/Pips39CoreTests/ExternalLinksTests.swift
git commit -m "feat: Adresse der BitBox-Wuerfelanleitung"
```

---

### Task 3: Das Seitengerüst herauslösen

**Files:**
- Create: `Pips39/Pips39/OnboardingPage.swift`

- [ ] **Step 1: Die Datei anlegen**

Heute ist das eine private Funktion in `OnboardingView`. Sieben Seiten in drei Dateien
brauchen sie gemeinsam.

```swift
import SwiftUI

/// Eine Onboarding-Seite: Überschrift, scrollbarer Inhalt, Platz für die Fußleiste.
///
/// `title` ist ein `LocalizedStringKey` und kein `String`: `Text(einString)`
/// lokalisiert **nicht** — nur ein Literal oder ein `LocalizedStringKey` geht durch die
/// Übersetzungstabelle. Das ist in diesem Projekt schon viermal passiert.
struct OnboardingPage<Content: View>: View {

    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
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
}
```

- [ ] **Step 2: Bauen**

Der Build muss durchlaufen — die Datei wird noch nicht benutzt.

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

---

### Task 4: Die Seiten des Würfel-Wegs

**Files:**
- Create: `Pips39/Pips39/RollingOnboardingPages.swift`

Inhaltlich sind das die heutigen Seiten 1 und 2 plus die Reste der heutigen Seite 3.
**Die Reihenfolge bleibt: prüfen, dann abschotten.** Das war die Korrektur aus Phase 7 —
die Prüfung braucht Shell und Browser und ginge nach dem Abschotten nicht mehr.

- [ ] **Step 1: Die Datei anlegen**

```swift
import SwiftUI
import Pips39Core

/// Die zwei Seiten für den Weg, auf dem die App rechnet.
///
/// Prüfen kommt vor Abschotten: Die Prüfung braucht Shell und Browser, danach ist beides
/// weg. Neu gegenüber Phase 7 ist nur, dass diese Seiten nicht mehr die ersten der App
/// sind — davor stehen drei gemeinsame, die erklären, worum es überhaupt geht.
struct RollingOnboardingPages: View {

    @ObservedObject var probe: EnvironmentProbe
    @Binding var page: Int

    var body: some View {
        TabView(selection: $page) {
            verifyPage.tag(0)
            offlinePage.tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: A1 — prüfen, solange das Netz noch da ist

    private var verifyPage: some View {
        OnboardingPage(title: "First: check the app") {
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

    // MARK: A2 — abschotten, und was danach offen bleibt

    private var offlinePage: some View {
        OnboardingPage(title: "Then: take it offline") {
            EnvironmentNotice(probe: probe)

            ForEach(Array(checklist.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .padding(.top, 5)
                    Text(item).font(.footnote)
                }
            }

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

    private let checklist: [LocalizedStringKey] = [
        "Turn off Wi-Fi, cellular, Bluetooth and AirDrop in Settings — not in Control Center.",
        "Turn off iCloud completely: no backup, no keychain sync.",
        "Block USB accessories under Face ID & Passcode.",
        "Turn on Lockdown Mode.",
        "Turn off Settings, App Store, Offload Unused Apps — otherwise iOS may delete this app and need the network to restore it."
    ]
}
```

- [ ] **Step 2: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **` (die alte `OnboardingView` existiert noch parallel;
doppelte Texte in beiden Dateien sind in Ordnung, Task 6 räumt sie weg).

---

### Task 5: Die Seiten des Tabellen-Wegs

**Files:**
- Create: `Pips39/Pips39/LookupOnboardingPages.swift`

- [ ] **Step 1: Die Datei anlegen**

```swift
import SwiftUI
import Pips39Core

/// Die zwei Seiten für den Weg mit der Nachschlagetabelle.
///
/// Auch dieser Weg gehört auf ein abgeschottetes Gerät — die App sieht zwar nur einen
/// Teil, aber ein Teil ist nicht nichts. Die Checkliste wird hier nur genannt, nicht
/// wiederholt: Wer sie braucht, findet sie über den anderen Weg.
struct LookupOnboardingPages: View {

    @ObservedObject var probe: EnvironmentProbe
    @Binding var page: Int

    var body: some View {
        TabView(selection: $page) {
            needsPage.tag(0)
            exposurePage.tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: B1 — was auf dem Tisch liegen muss

    private var needsPage: some View {
        OnboardingPage(title: "What you need") {
            EnvironmentNotice(probe: probe)

            ForEach(Array(needs.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .padding(.top, 5)
                    Text(item).font(.footnote)
                }
            }

            Text("Take this device offline too. It sees less on this path, but less is not nothing.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private let needs: [LocalizedStringKey] = [
        "Five dice. One works too — throw it five times and keep the order.",
        "A coin. Or a sixth die: 1 to 3 is heads, 4 to 6 is tails.",
        "Paper and a pen for the 23 words.",
        "A hardware wallet. It supplies the 24th word, which this app cannot work out.",
        "A die showing 5 or 6 counts for nothing here. Throw it again until it shows 1 to 4."
    ]

    // MARK: B2 — was die App dabei sieht

    private var exposurePage: some View {
        OnboardingPage(title: "What the app sees") {
            Text(OnboardingPath.lookupTable.exposure())
                .font(.footnote)

            VStack(alignment: .leading, spacing: 8) {
                Text("Why it is 24 words only")
                    .font(.headline)
                Text("With 12 words too little would stay hidden — 62 bits, which is within reach of an attacker who got hold of what you typed. There is no length switch on this path for that reason.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("The 24th word")
                    .font(.headline)
                Text("It carries a checksum over the other 23, so working it out needs all of them. Your wallet offers eight valid options — pick between them with three coin flips, not by feel.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("Method from the BitBox02 dice guide by Shift Crypto, CC BY-SA 4.0.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 2: Bauen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

---

### Task 6: `OnboardingView` neu — gemeinsame Seiten und Verzweigung

**Files:**
- Modify: `Pips39/Pips39/OnboardingView.swift` (vollständig ersetzen)

- [ ] **Step 1: Die Datei ersetzen**

```swift
import SwiftUI
import Pips39Core

/// Zuerst drei Seiten für alle, dann die des gewählten Wegs.
///
/// Die alte Fassung begann mit `shasum` — der Antwort auf die Frage des Misstrauischen,
/// gestellt bevor die des Unwissenden beantwortet war. Wer das Thema nicht kennt, war
/// nach zehn Sekunden weg.
///
/// Die Verzweigung ist eine Abkürzung, keine Sperre: Wer überspringt, landet auf der
/// Startseite, auf der beide Wege weiterhin stehen.
struct OnboardingView: View {

    @ObservedObject var probe: EnvironmentProbe

    /// Springt direkt in die Seiten eines Wegs — für den Hilfe-Knopf aus einem
    /// laufenden Durchlauf, wo die gemeinsamen Seiten nichts mehr beitragen.
    var startPath: OnboardingPath?

    let onDone: (OnboardingPath?) -> Void

    @State private var path: OnboardingPath?
    @State private var sharedPage = 0
    @State private var pathPage = 0

    private let lastSharedPage = 2

    init(probe: EnvironmentProbe,
         startPath: OnboardingPath? = nil,
         onDone: @escaping (OnboardingPath?) -> Void) {
        self.probe = probe
        self.startPath = startPath
        self.onDone = onDone
        _path = State(initialValue: startPath)
    }

    var body: some View {
        if let path {
            VStack(spacing: 0) {
                switch path {
                case .rollAndCompute:
                    RollingOnboardingPages(probe: probe, page: $pathPage)
                case .lookupTable:
                    LookupOnboardingPages(probe: probe, page: $pathPage)
                }
                pathFooter(for: path)
            }
        } else {
            VStack(spacing: 0) {
                TabView(selection: $sharedPage) {
                    introPage.tag(0)
                    basicsPage.tag(1)
                    choicePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                sharedFooter
            }
        }
    }

    // MARK: Seite 1 — die Einordnung

    /// Kein Verbot. „Nutze das nie für einen echten Seed" machte die App in sich
    /// widersprüchlich — Abschreibkontrolle, Bildschirmschutz und Lockdown-Checkliste
    /// ergeben nur für einen echten Seed Sinn — und wäre wirkungslos: Wer es trotzdem
    /// tut, hat dann von der App selbst gehört, dass ihre Hinweise nicht gelten.
    private var introPage: some View {
        OnboardingPage(title: "The safest way needs no app") {
            Text("Dice, a printed table, paper and a pen, no electronics in the room. That makes a seed no device has ever seen. There is a good guide for it at BitBox.")
                .font(.body)

            Link("bitbox.swiss", destination: URL(string: ExternalLinks.bitboxGuide)!)
                .font(.body.weight(.medium))

            Text("One catch, so nobody is surprised later: paper and a pen get you 23 of the 24 words. The last one carries a checksum over the others, and nobody works that out by hand — a wallet has to supply it.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Where Pips39 sits")
                    .font(.headline)
                Text("It is the step below: for an old iPhone you keep permanently offline. Weaker than paper, stronger than letting a wallet roll the seed for you and hoping it did it properly.")
                    .font(.footnote)
                Text("If you are securing serious money, take the paper route.")
                    .font(.footnote.weight(.medium))
            }
        }
    }

    // MARK: Seite 2 — die Grundlagen

    private var basicsPage: some View {
        OnboardingPage(title: "What a seed is") {
            Text("Your wallet is one very large number. Every key and every address is worked out from it. That number is the seed.")
                .font(.footnote)
            Text("It is written as words only so you can copy it by hand without mistakes. The words are not the secret — the number is.")
                .font(.footnote)
            Text("Nothing else protects it. No password, no device, no company. It is safe exactly as long as nobody can guess the number.")
                .font(.footnote)
            Text("Dice make a number nobody can guess, not even you afterwards. A wallet can make one too, and then you are trusting it to have done it well — which you cannot check. That is the whole reason to roll it yourself.")
                .font(.footnote)

            VStack(alignment: .leading, spacing: 8) {
                Text("About the dice")
                    .font(.headline)
                Text("While you roll, the app watches for sequences that cannot come from dice: all the same value, a repeated block, only two or three of the six values, or long blocks of one value. Each of those is rarer than one in a billion, so the notice never appears on a real run.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("What it cannot see is the dice themselves. A loaded die, or one that leans a little because it is worn, produces sequences that look ordinary. Testing for that would mean a distribution test, and such a test flags correct runs often enough that people learn to ignore it. So there is none. Use dice you trust, and roll them properly.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Seite 3 — die Verzweigung

    private var choicePage: some View {
        OnboardingPage(title: "Two ways from here") {
            Text("They differ in one thing that matters: how much of your seed this app gets to see.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(OnboardingPath.allCases) { option in
                Button {
                    pathPage = 0
                    path = option
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(option.title())
                            .font(.title3.weight(.semibold))
                        Text(option.summary())
                            .font(.footnote)
                        Text(option.exposure())
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

            Text("You can change your mind afterwards — both stay on the start screen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Fußleisten

    /// Überspringen bleibt ab der ersten Seite sichtbar. Es wird nichts gespeichert,
    /// das Onboarding läuft also bei **jedem** Start — ohne diesen Knopf würde der
    /// zweite Durchlauf zur Strafe.
    private var sharedFooter: some View {
        HStack {
            Button("Skip") { onDone(nil) }
                .buttonStyle(.bordered)

            Spacer()

            if sharedPage < lastSharedPage {
                Button("Next") {
                    withAnimation { sharedPage += 1 }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }

    /// Zurück statt Überspringen: Wer sich für den falschen Weg entschieden hat, muss
    /// zur Wahl zurückkommen können, und „Los" ist von hier ohnehin ein Tipp entfernt.
    private func pathFooter(for path: OnboardingPath) -> some View {
        HStack {
            Button("Back") {
                if pathPage > 0 {
                    withAnimation { pathPage -= 1 }
                } else if startPath == nil {
                    withAnimation { self.path = nil }
                } else {
                    onDone(nil)
                }
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(pathPage == 1 ? "Start" : "Next") {
                if pathPage == 1 {
                    onDone(path)
                } else {
                    withAnimation { pathPage += 1 }
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
    OnboardingView(probe: EnvironmentProbe()) { _ in }
}
```

> [!warning] `pathPage == 1` heißt „letzte Seite", weil beide Wege genau zwei haben
> Das steht an zwei Stellen in `pathFooter` und bricht **still**, wenn ein Weg eine
> dritte Seite bekommt: Der Knopf hieße dann auf Seite 2 schon „Los" und würde das
> Onboarding zu früh beenden. Wer eine Seite ergänzt, ersetzt die beiden `1` durch die
> Seitenzahl des jeweiligen Wegs — dann gehört sie als Eigenschaft an `OnboardingPath`.

- [ ] **Step 2: Bauen**

Der Build **muss** jetzt an `ContentView` scheitern — die Signatur von `onDone` hat sich
geändert. Das ist der erwartete Zwischenstand, Task 7 schließt ihn.

---

### Task 7: Den Ablauf verdrahten

**Files:**
- Modify: `Pips39/Pips39/ContentView.swift`

- [ ] **Step 1: Zustand und Verzweigung**

Zwei geänderte Stellen. Erstens der Zustand:

```swift
    @State private var hasStarted = false
    @State private var showsLookupTable = false
    @State private var takenPath: OnboardingPath?
```

Zweitens der Kopf des Körpers — **so und nicht anders**, `startPath` gehört von Anfang an
dazu:

```swift
        if !hasStarted {
            OnboardingView(probe: probe, startPath: takenPath) { destination in
                takenPath = destination
                showsLookupTable = destination == .lookupTable
                hasStarted = true
            }
        } else if showsLookupTable {
            LookupView { showsLookupTable = false }
        } else if let session {
```

Und im Hilfe-Knopf der Würfelansicht: Wer mitten im Würfeln Hilfe sucht, will nicht bei
„Was ein Seed ist" anfangen.

```swift
                } onHelp: {
                    takenPath = .rollAndCompute
                    hasStarted = false
                }
```

> [!warning] `startPath` wirkt nur beim Aufbau der Ansicht
> `_path = State(initialValue:)` läuft im `init`. Das genügt hier, weil `hasStarted` die
> `OnboardingView` vollständig aus dem Baum nimmt und beim nächsten Mal neu aufbaut.
> Wer daraus später eine dauerhaft eingehängte Ansicht macht, braucht `.id(startPath)`
> oder ein `onChange`.

- [ ] **Step 2: Bauen und installieren**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | grep -E "error:|BUILD" | tail -3
xcrun simctl install B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF \
  "$HOME/Library/Developer/Xcode/DerivedData/Pips39-aawmoserexodpgbwggjkeytgithp/Build/Products/Debug-iphonesimulator/Pips39.app"
```
Expected: `** BUILD SUCCEEDED **`

> [!warning] Bauen ist nicht installieren
> In Phase 10 wurde ein Testwert zurückgesetzt und neu gebaut, aber nicht installiert —
> der Simulator zeigte danach noch stundenlang das alte Verhalten. Nach **jedem** Build,
> dessen Ergebnis man ansehen will, gehört das `simctl install` dazu.

- [ ] **Step 3: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39/OnboardingPage.swift Pips39/Pips39/OnboardingView.swift \
        Pips39/Pips39/RollingOnboardingPages.swift Pips39/Pips39/LookupOnboardingPages.swift \
        Pips39/Pips39/ContentView.swift
git commit -m "feat: Onboarding erklaert erst, verzweigt dann"
```

---

### Task 8: Die deutschen Texte

**Files:**
- Modify: `Pips39/Pips39/de.lproj/Localizable.strings`

- [ ] **Step 1: Prüfen, was schon da ist**

Die Checkliste, die Prüfschritte und die beiden Absätze zu den Würfeln sind **bereits**
übersetzt und wurden nur verschoben. Neu sind nur die Seiten 1 und 2 und der
Tabellen-Weg.

```bash
cd "$REPO/Pips39/Pips39"
grep -c "Turn on Lockdown Mode\|About the dice\|What this app cannot tell you" de.lproj/Localizable.strings
```
Expected: `3` — diese Zeilen bleiben unverändert stehen.

Die drei Schlüssel `"Ready"`, `"First: check the app"` und `"Then: take it offline"`
bleiben ebenfalls; nur `"Ready"` wird nicht mehr benutzt und kann stehenbleiben, ohne zu
stören.

- [ ] **Step 2: Die neuen Zeilen anhängen**

```
/* ===== Onboarding, gemeinsame Seiten ===== */
"The safest way needs no app" = "Der sicherste Weg braucht keine App";
"Dice, a printed table, paper and a pen, no electronics in the room. That makes a seed no device has ever seen. There is a good guide for it at BitBox." = "Würfel, eine gedruckte Tabelle, Papier und Stift, keine Elektronik im Raum. So entsteht ein Seed, den nie ein Gerät gesehen hat. Eine gute Anleitung dazu gibt es bei BitBox.";
"One catch, so nobody is surprised later: paper and a pen get you 23 of the 24 words. The last one carries a checksum over the others, and nobody works that out by hand — a wallet has to supply it." = "Ein Haken, damit später niemand überrascht ist: Papier und Stift bringen Sie bis Wort 23 von 24. Das letzte trägt eine Prüfsumme über die anderen, und die rechnet niemand von Hand — die muss eine Wallet liefern.";
"Where Pips39 sits" = "Wo Pips39 steht";
"It is the step below: for an old iPhone you keep permanently offline. Weaker than paper, stronger than letting a wallet roll the seed for you and hoping it did it properly." = "Eine Stufe darunter: für ein altes iPhone, das dauerhaft offline bleibt. Schwächer als Papier, stärker als eine Wallet, die den Seed für Sie auswürfelt und von der Sie hoffen, dass sie es ordentlich getan hat.";
"If you are securing serious money, take the paper route." = "Wer echtes Geld absichert, nimmt den Papierweg.";

"What a seed is" = "Was ein Seed ist";
"Your wallet is one very large number. Every key and every address is worked out from it. That number is the seed." = "Ihre Wallet ist eine einzige sehr große Zahl. Jeder Schlüssel und jede Adresse wird daraus berechnet. Diese Zahl ist der Seed.";
"It is written as words only so you can copy it by hand without mistakes. The words are not the secret — the number is." = "Sie wird nur deshalb als Wörter geschrieben, damit man sie ohne Fehler abschreiben kann. Nicht die Wörter sind das Geheimnis, sondern die Zahl.";
"Nothing else protects it. No password, no device, no company. It is safe exactly as long as nobody can guess the number." = "Sonst schützt sie nichts. Kein Passwort, kein Gerät, keine Firma. Sie hält genau so lange, wie niemand die Zahl erraten kann.";
"Dice make a number nobody can guess, not even you afterwards. A wallet can make one too, and then you are trusting it to have done it well — which you cannot check. That is the whole reason to roll it yourself." = "Würfel erzeugen eine Zahl, die niemand erraten kann — auch Sie selbst hinterher nicht. Eine Wallet kann das auch, dann vertrauen Sie darauf, dass sie es ordentlich gemacht hat, und nachprüfen können Sie es nicht. Genau deshalb würfelt man selbst.";

"Two ways from here" = "Zwei Wege von hier";
"They differ in one thing that matters: how much of your seed this app gets to see." = "Sie unterscheiden sich in einem Punkt, auf den es ankommt: wie viel vom Seed diese App zu sehen bekommt.";
"You can change your mind afterwards — both stay on the start screen." = "Sie können sich später umentscheiden — beide Wege bleiben auf der Startseite.";

/* ===== Onboarding, Tabellen-Weg ===== */
"What you need" = "Was Sie brauchen";
"Five dice. One works too — throw it five times and keep the order." = "Fünf Würfel. Einer geht auch — fünfmal werfen und die Reihenfolge merken.";
"A coin. Or a sixth die: 1 to 3 is heads, 4 to 6 is tails." = "Eine Münze. Oder ein sechster Würfel: 1 bis 3 ist Kopf, 4 bis 6 ist Zahl.";
"Paper and a pen for the 23 words." = "Papier und Stift für die 23 Wörter.";
"A hardware wallet. It supplies the 24th word, which this app cannot work out." = "Eine Hardware-Wallet. Sie liefert das 24. Wort, das diese App nicht berechnen kann.";
"A die showing 5 or 6 counts for nothing here. Throw it again until it shows 1 to 4." = "Ein Würfel mit 5 oder 6 zählt hier nicht. Neu werfen, bis er 1 bis 4 zeigt.";
"Take this device offline too. It sees less on this path, but less is not nothing." = "Dieses Gerät ebenfalls abschotten. Es sieht auf diesem Weg weniger, aber weniger ist nicht nichts.";
"What the app sees" = "Was die App sieht";
"Why it is 24 words only" = "Warum nur 24 Wörter";
"With 12 words too little would stay hidden — 62 bits, which is within reach of an attacker who got hold of what you typed. There is no length switch on this path for that reason." = "Bei 12 Wörtern bliebe zu wenig verborgen — 62 Bit, und die sind für jemanden, der Ihre Eingaben hat, in Reichweite. Deshalb gibt es auf diesem Weg keine Längenwahl.";
"It carries a checksum over the other 23, so working it out needs all of them. Your wallet offers eight valid options — pick between them with three coin flips, not by feel." = "Es trägt eine Prüfsumme über die anderen 23, zum Ausrechnen braucht man also alle. Ihre Wallet bietet acht gültige Möglichkeiten an — zwischen ihnen mit drei Münzwürfen wählen, nicht nach Gefühl.";
```

> [!warning] Vier gerade Anführungszeichen je Zeile
> ```bash
> cd "$REPO/Pips39/Pips39"
> grep -n '^"' de.lproj/Localizable.strings | awk -F: '{n=gsub(/"/,"\"",$0); if (n!=4) print "FEHLER", $0}'
> ```
> Ohne Ausgabe ist es in Ordnung. Zusätzlich auf doppelte Schlüssel prüfen:
> ```bash
> awk -F'"' '/^"/{print $2}' de.lproj/Localizable.strings | sort | uniq -d
> ```

- [ ] **Step 3: Bauen, installieren, committen**

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'id=B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF' build 2>&1 | grep -E "error:|BUILD" | tail -3
xcrun simctl install B3AA3F6E-A3D2-4F9F-B69A-05F507F090EF \
  "$HOME/Library/Developer/Xcode/DerivedData/Pips39-aawmoserexodpgbwggjkeytgithp/Build/Products/Debug-iphonesimulator/Pips39.app"
cd "$REPO"
git add Pips39/Pips39/de.lproj/Localizable.strings
git commit -m "i18n: Texte des neuen Onboardings"
git push
```

---

### Task 9: Sichtprüfung

Vor jedem Durchgang: bauen **und** installieren, dann starten.

- [ ] **Step 1: Die drei gemeinsamen Seiten**

Seite 1 muss mit der Einordnung beginnen, nicht mit einem Shell-Befehl. Der
BitBox-Link muss sichtbar sein. Der Überspringen-Knopf muss ab Seite 1 unten links
stehen.

- [ ] **Step 2: Die Verzweigung**

Auf Seite 3 stehen zwei Karten. Unter jeder muss die Aussage stehen, was die App sieht —
bei der zweiten mit der Zahl **118**.

- [ ] **Step 3: Weg A**

„Würfeln, die App rechnet" antippen. Es müssen genau zwei Seiten folgen: erst „Zuerst:
die App prüfen" (mit `shasum`), dann „Danach: abschotten". Unten links steht jetzt
„Zurück", nicht „Überspringen". Ein Tipp auf „Zurück" von Seite 1 dieses Wegs muss zur
Verzweigung zurückführen. „Los" auf der zweiten Seite landet auf der Verfahrenswahl.

- [ ] **Step 4: Weg B**

Neu starten, diesmal „Würfeln, das Wort ablesen" wählen. Zwei Seiten, dann muss „Los"
**direkt** in die Nachschlagetabelle führen — nicht auf die Verfahrenswahl.

- [ ] **Step 5: Überspringen**

Neu starten, auf Seite 1 „Überspringen" tippen. Landung auf der Verfahrenswahl, und dort
müssen **beide** Blöcke stehen: die zwei Verfahrenskarten und die Nachschlagetabelle.

- [ ] **Step 6: Der Hilfe-Knopf**

Einen Würfeldurchlauf beginnen (12 Wörter wählen — 50 statt 99 Würfe), oben rechts auf
„?" tippen. Es müssen **direkt** die beiden Seiten des Würfel-Wegs erscheinen, nicht die
gemeinsamen. „Zurück" von der ersten dieser Seiten muss zurück in den Durchlauf führen,
ohne die bisherigen Würfe zu verlieren.

---

## Abschluss der Phase

- [ ] **Spec nachziehen:** In `~/Documents/Doku/02 Projekte/Ideen und Tests/Pips39/würfel-tool-spec.md`
      den Abschnitt 3 „Ablauf" um die neue Onboarding-Abfolge ergänzen und in
      Abschnitt 10 „Verworfen" den Punkt aufnehmen, warum kein „nutze das nie für einen
      echten Seed" in der App steht.

- [ ] **README nachziehen:** Der Abschnitt „Read this before you trust it" beschreibt das
      Onboarding als drei Seiten. Auf die neue Abfolge anpassen und den Satz ergänzen,
      dass der stärkere Weg ohne die App auskommt.

> [!warning] Vor dem Push: `git diff` auf `DEVELOPMENT_TEAM` prüfen
> Xcode trägt die Team-ID beim nächsten Signieren auf einem Gerät neu ein. Sie darf
> nicht ins öffentliche Repo.

## Was danach kommt (nicht Teil dieses Plans)

- App-Store-Einreichung: Beschreibung in beiden Sprachen, Screenshots, der Satz zu
  Quelltext gegen Binary
- Offen aus Phase 6: Der Seed-Längen-Schalter springt beim Verwerfen auf 24 zurück
- Offen aus Phase 4: `SecureLayer` ist nur auf echter Hardware prüfbar
