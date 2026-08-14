# Lokalisierung im Swift Package — was tatsächlich trägt

Gemessen am 2026-08-14 mit Swift 5.9 / Xcode 26.6, nicht aus der Dokumentation
abgeleitet. Drei Befunde, der dritte ist der wichtige.

## 1. String Catalogs (`.xcstrings`) funktionieren unter reinem SwiftPM **nicht**

`swift build` meldet:

```
[0/2] Copying Localizable.xcstrings
```

**Kopiert, nicht kompiliert.** Ein roher Katalog landet im Bundle, und das
Nachschlagen zur Laufzeit liefert den Schlüssel zurück:

```
PROBE en=probe.key de=probe.key
```

String Catalogs werden von Xcodes Build-System zu `.lproj/Localizable.strings`
übersetzt. `swift build` hat dieses Werkzeug nicht. Wer sie im Paket verwendet,
verliert die Kommandozeilen-Prüfbarkeit — und merkt es nicht am Build, sondern erst
daran, dass alle Texte als Schlüssel erscheinen.

## 2. Klassische `.lproj/Localizable.strings` funktionieren

```
Sources/Pips39Core/Localization/en.lproj/Localizable.strings
Sources/Pips39Core/Localization/de.lproj/Localizable.strings
```

dazu in `Package.swift`:

```swift
    defaultLocalization: "en",
    …
    resources: [
        .copy("Resources/english.txt"),
        .process("Localization")
    ]
```

Damit löst das Nachschlagen auf. **Das ist der gewählte Weg.**

## 3. `String(localized:locale:)` wählt **nicht** die Sprache aus

Der Stolperstein, der stillschweigend falsche Tests erzeugt hätte.

```swift
String(localized: "probe.key", bundle: .module, locale: Locale(identifier: "en"))
```

liefert auf einem deutschen Mac **„Sonde"** — die deutsche Fassung, obwohl `en`
verlangt wurde. Der `locale:`-Parameter steuert nur Formatierung (Zahlen, Daten,
Pluralformen), nicht die Auswahl des `.lproj`. Die kommt aus den bevorzugten Sprachen
des Prozesses.

Folgen, wenn man das nicht weiß:

- Tests, die eine bestimmte Sprache prüfen wollen, prüfen in Wahrheit die
  Systemsprache der Testmaschine.
- Auf einem englischen Mac wären sie grün, auf einem deutschen rot — oder umgekehrt.
- Ein Test, der beide Sprachen vergleicht, vergliche zweimal dieselbe.

**Sprache erzwingen geht nur über ein eigenes Bundle:**

```swift
func localized(_ key: String, _ locale: Locale) -> String {
    guard let path = Bundle.module.path(forResource: locale.identifier, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
        return key
    }
    return NSLocalizedString(key, bundle: bundle, comment: "")
}
```

Gegengeprüft: Damit liefert `en` „Probe" und `de` „Sonde", unabhängig von der
Systemsprache.

## 4. `Text(einString)` lokalisiert **nicht** — nur Literale und `LocalizedStringKey`

Der Fehler, der in dieser Phase viermal auftrat, jedes Mal an anderer Stelle, und der
sich nur im Bild zeigt: Der Build ist grün, der Text erscheint — nur eben englisch.

SwiftUI lokalisiert `Text("…")` mit einem **Literal**, weil daraus ein
`LocalizedStringKey` wird. Kommt der Text dagegen aus einer `String`-Variablen, greift
die andere Überladung, und die geht an der Tabelle vorbei.

Betroffen waren:

| Stelle | Warum |
|---|---|
| `OnboardingView.page(title:)` | Parameter war `String` |
| `OnboardingView.checklist` | Array war `[String]` |
| `VerifyView.field(title:)` | Parameter war `String` |
| `RollingView.progressText` | berechneter `String` mit Interpolation |

Die ersten drei sind mit `LocalizedStringKey` statt `String` erledigt. Der vierte ging
so nicht, weil dort Zahlen eingesetzt werden — dafür ein echter Formatstring:

```swift
String(format: NSLocalizedString("%lld of %lld rolls", comment: ""), done, needed)
```

**Faustregel:** Sobald ein Text durch eine Variable, einen Parameter oder ein Array
läuft, muss der Typ `LocalizedStringKey` sein — oder es braucht ein ausdrückliches
`NSLocalizedString`. Ein `String` an dieser Stelle ist immer ein Übersetzungsloch.

## 5. `.strings`-Werte vertragen keine geraden Anführungszeichen

Zwei deutsche Zeilen enthielten ein `"` mitten im Wert und rissen die Datei auf.
Der Build meldet dann nur:

```
validation failed: Couldn't parse property list because the input data was in an invalid format
```

— ohne Zeilennummer. Prüfen lässt sich das mit: jede Eintragszeile muss **genau vier**
gerade Anführungszeichen haben.

## Was das für die App bedeutet

Das **App-Target** ist davon nicht betroffen — dort baut Xcode, und String Catalogs
sind der bequemere Weg. Es ist also in Ordnung, wenn im Paket `.strings` und in der
App `.xcstrings` liegen. Zwei Mechanismen, aber jeder dort, wo er trägt.

## Verwaiste Schlüssel finden — und die zwei Fallen dabei

Nach einem Umbau bleiben Einträge zurück, die niemand mehr nachschlägt. Sie schaden
nicht, aber sie täuschen: Wer sie liest, hält sie für benutzt.

Der naheliegende Weg — jeden Schlüssel im Swift-Code suchen — meldet **falsch positiv**,
weil zwei Sorten Schlüssel nie wörtlich im Code stehen:

**1. Interpolierte Schlüssel.** `OnboardingPath` baut sie zusammen:

```swift
Localized.string("onboarding.path.\(rawValue).title", locale)
```

Im Code steht nie `"onboarding.path.rollAndCompute.title"`. Wer den Schlüssel löscht,
bekommt keinen Compilerfehler — nur eine Oberfläche, die plötzlich englisch ist.

**2. `Text` mit Interpolation.** SwiftUI macht daraus einen `LocalizedStringKey` mit
Formatplatzhaltern:

```swift
Text("Word \(check.position + 1) of \(check.total)")   // Schlüssel: Word %lld of %lld
Text("Method: \(session.method.title) — note this…")   // Schlüssel: Method: %@ — note…
```

Der Schlüssel enthält `%lld` bzw. `%@`, der Quelltext `\(…)`. Auch hier findet die Suche
nichts, obwohl der Eintrag gebraucht wird.

**Praktisch heißt das:** Die Suche liefert Kandidaten, keine Befunde. Jeder Treffer wird
von Hand geprüft — enthält er einen Formatplatzhalter, oder passt er auf ein Muster, das
irgendwo zusammengesetzt wird, ist er **nicht** verwaist. Beim Aufräumen am 2026-08-14
blieben von elf Kandidaten genau zwei übrig.

Danach bauen, installieren und die betroffenen Bildschirme ansehen. Ein fehlender
Eintrag fällt sonst erst dem Nutzer auf.
