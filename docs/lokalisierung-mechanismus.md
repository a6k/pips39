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

## Was das für die App bedeutet

Das **App-Target** ist davon nicht betroffen — dort baut Xcode, und String Catalogs
sind der bequemere Weg. Es ist also in Ordnung, wenn im Paket `.strings` und in der
App `.xcstrings` liegen. Zwei Mechanismen, aber jeder dort, wo er trägt.
