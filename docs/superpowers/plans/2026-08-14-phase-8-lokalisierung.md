# Pips39 — Phase 8: Lokalisierung (Englisch und Deutsch) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die App spricht Englisch und Deutsch. Die Regeln, die heute als Test an englischen Texten hängen, gelten danach für **jede** Sprache.

**Sprachen:** Englisch als Vorgabe (die Zielgruppe ist international, danach wurde der Name gewählt), Deutsch als zweite. Weitere kämen später ohne Umbau dazu.

**Vorhanden:** 161 Tests grün, sieben Phasen umgesetzt, Repo öffentlich.

---

## Der Knackpunkt: die Texte im Paket tragen geprüfte Regeln

Naheliegend wäre, alle Nutzertexte aus dem Paket in die App zu ziehen und nur dort zu
lokalisieren — ein Ziel statt zwei. **Das wäre ein Rückschritt.**

Drei Regeln dieses Projekts sind heute deshalb belastbar, weil die Texte im Paket
liegen und Tests sie greifen können:

| Regel | Test |
|---|---|
| Nie ein grünes „sicher" | `testNoNoticeEverClaimsSafety` verbietet *safe, secure, protected, offline, air-gap* |
| Colemans zwei Stolperstellen stehen in der Anleitung | `testColemanStepsWarnAboutBothPitfalls` verlangt *Dice* und *Raw Entropy* |
| Bei 12 Wörtern der Hinweis auf die ersten 32 Hex-Zeichen | `testHashedStepsExplainTheHexTruncationForTwelveWords` |

In die App verschoben wären das drei Absichtserklärungen statt drei Tests. Also wird
**das Paket mitlokalisiert**, und die Regeln werden dabei stärker: Sie prüfen künftig
jede Sprache, nicht nur Englisch. Eine deutsche Übersetzung, die versehentlich
„sicher" schreibt, fällt dann durch.

> [!danger] Was **nicht** übersetzt werden darf
> - **Shell-Befehle:** `printf '%s' "…" | shasum -a 256` bleibt wie er ist.
> - **Colemans Bedienelemente:** „Dice" und „Use Raw Entropy" sind Beschriftungen auf
>   seiner **englischen** Seite. Übersetzt zeigt die Anleitung auf Knöpfe, die es
>   dort nicht gibt — und produziert damit genau den Fehlalarm, den diese Hinweise
>   verhindern sollen.
> - **Verfahrensnamen:** „SHA-256" und „Coleman" sind Eigennamen.
> - **BIP39-Wörter:** die Wortliste ist normativ englisch.
>
> Task 2 nagelt das mit einem Test fest, der die deutschen Anleitungsschritte auf
> „Dice" und „Raw Entropy" prüft — genau wie die englischen.

---

### Task 1: Erkunden, ob Lokalisierung unter `swift test` trägt

**Diese Aufgabe schreibt kein Produktivfeature.** Sie beantwortet eine Frage, von der
alles Weitere abhängt, und hält die Antwort fest.

Der gesamte Kern dieses Projekts ist bisher mit `swift test` auf der Kommandozeile
prüfbar, ohne Simulator und ohne Xcode. Das war Absicht und hat sich mehrfach
ausgezahlt. **String Catalogs (`.xcstrings`) werden von Xcode kompiliert** — ob ein
reines `swift build`/`swift test` sie verarbeitet, ist nicht sicher. Fällt das aus,
verlieren wir die Kommandozeilen-Prüfbarkeit, und das wäre ein zu hoher Preis.

- [ ] **Step 1: `Package.swift` um die Vorgabesprache ergänzen**

```swift
let package = Package(
    name: "Pips39Core",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
```

- [ ] **Step 2: Einen String Catalog anlegen und ausprobieren**

`Sources/Pips39Core/Resources/Localizable.xcstrings` mit einem einzigen Eintrag
anlegen, in `Package.swift` als `.process("Resources")` einbinden, und im Code
abfragen:

```swift
String(localized: "probe.key", bundle: .module)
```

Dann:

```bash
cd "$REPO" && swift build 2>&1 | tail -5
```

- [ ] **Step 3: Falls das scheitert — klassische `.strings` probieren**

`Sources/Pips39Core/Resources/en.lproj/Localizable.strings` und
`de.lproj/Localizable.strings` anlegen, wieder `.process("Resources")`, und erneut
bauen. SwiftPM verarbeitet `.lproj`-Verzeichnisse seit jeher.

- [ ] **Step 4: Das Ergebnis festhalten**

`docs/lokalisierung-mechanismus.md` schreiben: welcher der beiden Wege funktioniert,
mit der tatsächlichen Ausgabe von `swift build` als Beleg, und welcher gewählt wurde.

> **Nicht raten.** Wenn beide Wege gehen, String Catalogs nehmen — sie sind der
> aktuelle Weg und Xcode pflegt sie. Wenn nur `.strings` geht, `.strings` nehmen und
> das im Dokument begründen. Wenn **keiner** geht, **BLOCKED melden** statt die
> Kommandozeilen-Tests aufzugeben.

- [ ] **Step 5: Commit**

```bash
cd "$REPO"
git add Package.swift Sources/Pips39Core/Resources docs/lokalisierung-mechanismus.md
git commit -m "docs: Lokalisierungsmechanismus erkundet und festgelegt"
git push
```

---

### Task 2: Die Texte im Paket lokalisieren

**Files:**
- Modify: `Sources/Pips39Core/DiceMethod.swift`, `SeedLength.swift`, `EnvironmentProbe.swift`
- Modify/Create: die in Task 1 gewählten Ressourcendateien
- Modify: `Tests/Pips39CoreTests/EnvironmentProbeTests.swift`, `SeedLengthHintTests.swift`
- Create: `Tests/Pips39CoreTests/LocalizationRuleTests.swift`

- [ ] **Step 1: Eine sprachbewusste Hilfsfunktion einführen**

Damit Tests eine Sprache erzwingen können, bekommen die Texte einen Locale-Parameter
mit Vorgabewert:

```swift
/// Nachschlagen im Paket-Bundle, mit erzwingbarer Sprache für die Tests.
func localized(_ key: String, _ locale: Locale = .current) -> String {
    String(localized: String.LocalizationValue(key), bundle: .module, locale: locale)
}
```

Und die öffentlichen Zugänge entsprechend:

```swift
    public func rollCountHint(for length: SeedLength, locale: Locale = .current) -> String
    public func verificationSteps(for length: SeedLength, locale: Locale = .current) -> [String]
    public var verificationWarning: String   // ebenso mit locale-Parameter
    public static func notice(isNetworkAvailable: Bool, locale: Locale = .current) -> String?
```

Die Vorgabewerte halten alle bestehenden Aufrufe am Leben.

- [ ] **Step 2: Den Regeltest auf alle Sprachen ausweiten**

`Tests/Pips39CoreTests/LocalizationRuleTests.swift`:

```swift
import XCTest
@testable import Pips39Core

/// Die Regeln des Projekts gelten sprachunabhängig. Eine Übersetzung, die
/// versehentlich Sicherheit behauptet oder Colemans Bedienelemente eindeutscht,
/// muss hier durchfallen.
final class LocalizationRuleTests: XCTestCase {

    private let locales = [Locale(identifier: "en"), Locale(identifier: "de")]

    /// Pro Sprache die Wörter, die eine Entwarnung bedeuten würden.
    private let forbidden: [String: [String]] = [
        "en": ["safe", "secure", "protected", "offline", "air-gap", "airgap"],
        "de": ["sicher", "geschützt", "offline", "isoliert", "getrennt", "unbedenklich"]
    ]

    func testNoNoticeClaimsSafetyInAnyLanguage() {
        for locale in locales {
            let words = forbidden[locale.identifier] ?? []
            for available in [true, false] {
                let text = (EnvironmentProbe.notice(isNetworkAvailable: available,
                                                    locale: locale) ?? "").lowercased()
                for word in words {
                    XCTAssertFalse(text.contains(word),
                                   "Verbotenes Wort \(word) in \(locale.identifier): \(text)")
                }
            }
        }
    }

    func testConnectedNoticeExistsInEveryLanguage() {
        for locale in locales {
            XCTAssertNotNil(EnvironmentProbe.notice(isNetworkAvailable: true, locale: locale))
            XCTAssertNil(EnvironmentProbe.notice(isNetworkAvailable: false, locale: locale))
        }
    }

    /// „Dice" und „Use Raw Entropy" sind Beschriftungen auf Colemans englischer
    /// Seite. Übersetzt zeigen sie auf Knöpfe, die es dort nicht gibt.
    func testColemanControlNamesStayEnglishInEveryLanguage() {
        for locale in locales {
            for length in SeedLength.allCases {
                let joined = DiceMethod.coleman
                    .verificationSteps(for: length, locale: locale)
                    .joined(separator: " ")
                XCTAssertTrue(joined.contains("Dice"),
                              "Dice fehlt in \(locale.identifier)")
                XCTAssertTrue(joined.contains("Raw Entropy"),
                              "Raw Entropy fehlt in \(locale.identifier)")
            }
        }
    }

    /// Der Shell-Befehl darf in keiner Sprache verunstaltet werden.
    func testShellCommandSurvivesTranslation() {
        for locale in locales {
            let joined = DiceMethod.sha256
                .verificationSteps(for: .twentyFour, locale: locale)
                .joined(separator: " ")
            XCTAssertTrue(joined.contains("shasum -a 256"),
                          "shasum-Befehl beschädigt in \(locale.identifier)")
        }
    }

    /// Der Fehlalarm-Fänger aus Phase 6 gilt ebenfalls in jeder Sprache.
    func testHexTruncationHintExistsInEveryLanguage() {
        for locale in locales {
            let joined = DiceMethod.sha256
                .verificationSteps(for: .twelve, locale: locale)
                .joined(separator: " ")
            XCTAssertTrue(joined.contains("32"),
                          "Hinweis auf die ersten 32 Hex-Zeichen fehlt in \(locale.identifier)")
        }
    }

    /// Verfahrensnamen sind Eigennamen.
    func testMethodTitlesAreNotTranslated() {
        for locale in locales {
            XCTAssertEqual(DiceMethod.sha256.title, "SHA-256")
            XCTAssertEqual(DiceMethod.coleman.title, "Coleman")
        }
    }

    /// Jeder Schlüssel muss in jeder Sprache eine Übersetzung haben — keine
    /// stillen Rückfälle auf Englisch.
    func testNoGermanStringFallsBackToEnglish() {
        let de = Locale(identifier: "de")
        let en = Locale(identifier: "en")
        for length in SeedLength.allCases {
            for method in DiceMethod.allCases {
                XCTAssertNotEqual(method.rollCountHint(for: length, locale: de),
                                  method.rollCountHint(for: length, locale: en),
                                  "Wurfzahl-Hinweis nicht übersetzt: \(method) \(length.wordCount)")
            }
        }
    }
}
```

- [ ] **Step 3: Die Texte in die Ressourcendateien überführen**

Alle heutigen englischen Literale aus `DiceMethod`, `SeedLength` und
`EnvironmentProbe` als Schlüssel anlegen, englische Werte übernehmen, deutsche
Werte in Task 4 füllen. Bis dahin dürfen die deutschen Werte identisch mit den
englischen sein — `testNoGermanStringFallsBackToEnglish` schlägt dann fehl und wird
in Task 4 grün. Das ist beabsichtigt und muss im Commit erwähnt werden.

- [ ] **Step 4: Bestehende Tests anpassen**

`EnvironmentProbeTests` und `SeedLengthHintTests` prüfen englische Texte; ihnen
`locale: Locale(identifier: "en")` mitgeben, damit sie unabhängig von der
Systemsprache der Testmaschine bleiben. **Das ist wichtig:** Ohne das würden sie auf
einem deutschen Mac plötzlich fehlschlagen.

- [ ] **Step 5: Tests laufen lassen**

```bash
cd "$REPO" && swift test 2>&1 | tail -5
```
Expected: alles grün außer `testNoGermanStringFallsBackToEnglish` — der bleibt bis
Task 4 rot.

- [ ] **Step 6: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core Tests/Pips39CoreTests
git commit -m "feat: Texte im Paket lokalisierbar, Regeltests gelten je Sprache

Die deutschen Werte sind noch Platzhalter; testNoGermanStringFallsBackToEnglish
bleibt bis zur Uebersetzung rot."
git push
```

---

### Task 3: Die Ansichten lokalisieren

**Files:**
- Create: `Pips39/Pips39/Localizable.xcstrings` (oder `.lproj`, je nach Task 1)
- Modify: alle sieben Ansichten

- [ ] **Step 1: Die Texte einsammeln**

SwiftUI zieht `Text("…")`, `Button("…")` und `Label("…")` automatisch durch die
Lokalisierung, sobald ein Katalog vorhanden ist — die Literale bleiben also als
Schlüssel stehen und müssen **nicht** umgeschrieben werden.

Betroffen sind rund 39 Stellen:

| Datei | Stellen |
|---|---|
| `OnboardingView.swift` | 11 |
| `RollingView.swift` | 7 |
| `MethodChoiceView.swift` | 6 |
| `WordsView.swift` | 6 |
| `VerifyView.swift` | 4 |
| `TranscriptionView.swift` | 4 |
| `ScreenProtection.swift` | 1 |

- [ ] **Step 2: Katalog anlegen und in Xcode einmal bauen**

Xcode füllt den String Catalog beim Bauen automatisch mit allen gefundenen
Schlüsseln. Danach steht die Liste, und Deutsch kann als Sprache ergänzt werden.

```bash
cd "$REPO/Pips39"
xcodebuild -project Pips39.xcodeproj -scheme Pips39 \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -3
```

- [ ] **Step 3: Zwei Stellen prüfen, die Sonderfälle sind**

- `RollingView`: „\(done) of \(needed) rolls" — braucht im Deutschen eine andere
  Wortstellung, also einen echten Formatstring, keine Verkettung.
- `TranscriptionView`: „Word \(position) of \(total)" — dasselbe.

- [ ] **Step 4: Commit**

```bash
cd "$REPO"
git add Pips39/Pips39
git commit -m "feat: Ansichten lokalisierbar, String Catalog angelegt"
git push
```

---

### Task 4: Die deutsche Übersetzung

**Das ist Schreibarbeit, keine Mechanik.** Die App hat einen bewusst nüchternen Ton:
Feststellungen statt Alarm, keine Beschwichtigung, keine Werbesprache. Das muss die
deutsche Fassung tragen, sonst klingt sie wie eine andere App.

- [ ] **Step 1: Alle Schlüssel übersetzen**, in beiden Katalogen

Leitlinien:

- **„This device is connected to a network."** → „Dieses Gerät ist mit einem Netzwerk
  verbunden." Feststellung, kein Ausrufezeichen, kein „Achtung".
- **Nie** ein Wort, das Sicherheit behauptet — der Test verbietet *sicher, geschützt,
  offline, isoliert, getrennt, unbedenklich*.
- Colemans Bedienelemente, Shell-Befehle und Verfahrensnamen bleiben englisch.
- Duzen oder siezen? **Siezen**, wie in iOS-Systemtexten üblich — oder durchgehend
  unpersönlich formulieren, was hier meist besser passt: „Zum Prüfen eine
  Wegwerf-Folge verwenden" statt „Verwende…".

- [ ] **Step 2: Tests laufen lassen**

```bash
cd "$REPO" && swift test 2>&1 | tail -5
```
Expected: **alles** grün, auch `testNoGermanStringFallsBackToEnglish`.

- [ ] **Step 3: Commit**

```bash
cd "$REPO"
git add Sources/Pips39Core Pips39/Pips39
git commit -m "feat: deutsche Übersetzung"
git push
```

---

### Task 5: Im Simulator auf Deutsch ansehen

- [ ] **Step 1: Die App auf Deutsch starten**

```bash
xcrun simctl spawn <UDID> defaults write -g AppleLanguages -array de
xcrun simctl spawn <UDID> defaults write -g AppleLocale -string de_DE
```

Alternativ im Schema unter *Run → Options → App Language: German* — der verlässlichere
Weg, weil er nur die App betrifft.

- [ ] **Step 2: Durchsehen**

- Onboarding, alle drei Seiten: passt der Ton, sind die Zeilen nicht abgeschnitten?
- Methodenkarten mit beiden Wortzahlen — die Wurfzahl-Sätze sind im Deutschen länger
- Würfelansicht: „37 von 99 Würfen" muss sitzen
- Prüfansicht: der Abweichungssatz mit Position
- Nachrechnen: die Anleitung, in der **englische Begriffe stehen bleiben müssen**

## Abschluss der Phase

- [ ] **Spec nachziehen:** Den offenen Punkt „Lokalisierung" in Abschnitt 11 abhaken,
      und in 2.5 ergänzen, dass die Kein-Entwarnung-Regel je Sprache geprüft wird.

## Was danach kommt (nicht Teil dieses Plans)

- Bias-Warnung (bewusst offen im Spec)
- Leerraum in der Prüfansicht
- App-Store-Einreichung: Beschreibung in beiden Sprachen, Screenshots, der Satz zu
  Quelltext gegen Binary
