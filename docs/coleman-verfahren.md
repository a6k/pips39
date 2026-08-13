# Colemans Würfel-Umrechnung — am Quelltext ermittelt

Beantwortet den Blocker aus Spec 2.1: Wie genau macht Ian Colemans BIP39-Werkzeug aus
einer Wurffolge Entropie? Alles hier steht mit Fundstelle im Quelltext; die Vektoren in
`Tests/Pips39CoreTests/Resources/coleman-vectors.json` stammen aus einem echten Lauf
seines Codes, nicht aus dieser Lesart.

**Untersuchter Stand:** `https://github.com/iancoleman/bip39`, `master` `de71c22328b2`
(2023-08-01).

- `src/js/entropy.js` — SHA-256 `10277942f7ce12507bf102e947fa8157602be88c9eab0f7a0b2c8d3610e38163`
- `src/js/index.js` — SHA-256 `3dd950f5d2f32cfe32963c1b3d4adea06e787ec7adb66daaaf19812e55a6f370`

Beide Codestellen sind in der ausgelieferten Seite `https://iancoleman.io/bip39/`
zeichengleich enthalten (geprüft am 2026-08-13 durch Textvergleich der normalisierten
Quelltexte). Der Nutzer rechnet also im Browser mit genau dem Code nach, der hier
zerlegt wurde. Zeilennummern beziehen sich auf die Dateien im Repository.

---

## Kurzfassung — und eine Korrektur an Spec 2.1

**Coleman wandelt die Wurffolge nicht als Base-6-Zahl um.** Spec 2.1 nimmt an, die Würfe
würden „als Base-6-Ziffern gelesen und nach binär gewandelt", also als eine große Zahl
zur Basis 6 mit rund 2,585 bit pro Wurf. Das tut sein Werkzeug nicht.

Coleman schlägt **jeden Wurf einzeln in einer Tabelle nach** und hängt die dort
hinterlegten Bits aneinander. Die Tabelle liefert für vier Augenzahlen zwei Bit und für
zwei Augenzahlen nur ein Bit. Das ist ein bias-freies Auszugsverfahren: Jedes ausgegebene
Bit ist gleichverteilt, dafür liefert ein Wurf im Mittel nur **1,667 bit statt 2,585 bit**.

Die praktische Folge steht unten unter „Folgen für `DiceEntropy`": Die Wurfzahl bestimmt
die Bitzahl **nicht mehr eindeutig** — 99 Würfe ergeben je nach Augenzahlen zwischen 99
und 198 Bit. 256 Bit sind mit 99 Würfen bei Coleman unerreichbar.

---

## Der Weg der Daten

`index.js:1874` `setMnemonicFromEntropy()` ist die einzige Stelle, an der aus dem
Eingabefeld ein Mnemonic wird:

1. `Entropy.fromString(entropyStr, base)` (`index.js:1881`/`1885`) → `entropy.binaryStr`
2. Werkseinstellung „Use Raw Entropy": `bits = entropy.binaryStr` (`index.js:1893`)
3. Auf ein Vielfaches von 32 kürzen (`index.js:1919-1922`)
4. In Bytes zerlegen (`index.js:1924-1929`) und `mnemonic.toMnemonic(entropyArr)`
   (`index.js:1931`) — ab hier normales BIP39.

Ein zweiter Pfad greift nur, wenn im Auswahlfeld *Mnemonic Length* eine feste Wortzahl
statt „Use Raw Entropy" steht; siehe eigenen Abschnitt weiter unten. Werkseinstellung ist
„Use Raw Entropy" (`src/index.html:118`: `<option value="raw" selected>`).

---

## Frage 1 — Wie werden die Augenzahlen 1–6 auf Base-6 abgebildet? Wird die 6 zur 0?

**Ja, die 6 wird zur 0, alle anderen Augenzahlen bleiben stehen.** `entropy.js:186-202`:

```js
// Convert dice to base6 entropy (ie 1-6 to 0-5)
// This is done by changing all 6s to 0s
if (base.str == "dice") {
    var newEvents = [];
    for (var i=0; i<base.events.length; i++) {
        var c = base.events[i];
        if ("12345".indexOf(c) > -1) {
            newEvents[i] = base.events[i];
        }
        else {
            newEvents[i] = "0";
        }
    }
    base.str = "base 6 (dice)";
```

Das ist eine reine Zeichenersetzung: `6` → `0`. Die Eingabe `123456` heißt intern danach
`123450` — das ist auch die Zeichenkette, die als „Filtered Entropy" angezeigt wird
(`entropy.js:220`, `index.js:1972`) und die im Hash-Pfad gehasht wird.

Damit ist der Würfel-Modus deckungsgleich mit dem Base-6-Modus: `6` tippen entspricht
exakt `0` tippen.

## Frage 2 — Wird die Base-6-Zahl als Ganzes nach binär gewandelt oder Wurf für Wurf?

**Wurf für Wurf, über eine Nachschlagetabelle mit unterschiedlich langen Bitfolgen.**
Es findet **keine** Umrechnung der Gesamtzahl statt. `entropy.js:212-215`:

```js
// Convert entropy events to binary
var entropyBin = base.events.map(function(e) {
    return eventBits[base.str][e.toLowerCase()];
}).join("");
```

Die Tabelle dazu, `entropy.js:39-50`:

```js
// log2(6) = 2.58496 bits per roll, with bias
// 4 rolls give 2 bits each
// 2 rolls give 1 bit each
// Average (4*2 + 2*1) / 6 = 1.66 bits per roll without bias
"base 6 (dice)": {
    "0": "00", // equivalent to 0 in base 6
    "1": "01",
    "2": "10",
    "3": "11",
    "4": "0",
    "5": "1",
},
```

Zusammen mit Frage 1 ergibt sich für den Würfel:

| Augenzahl | interne Ziffer | Bits | Anzahl Bits |
|---|---|---|---|
| 1 | 1 | `01` | 2 |
| 2 | 2 | `10` | 2 |
| 3 | 3 | `11` | 2 |
| 4 | 4 | `0` | 1 |
| 5 | 5 | `1` | 1 |
| 6 | 0 | `00` | 2 |

Colemans Kommentar nennt das Verfahren selbst „without bias": Bei einem fairen Würfel
sind die vier Zwei-Bit-Fälle untereinander gleich wahrscheinlich und die zwei Ein-Bit-Fälle
ebenso, jedes ausgegebene Bit ist also gleichverteilt. Der Preis ist die Ausbeute von
10/6 = 1,667 bit pro Wurf.

Die in `getBase()` nebenbei erzeugten Zahlenwerte (`ints`, `entropy.js:288`) werden für die
Entropie **nirgends** benutzt — eine Suche über `index.js` findet nur Verwendungen von
`entropy.base.events` und `entropy.base.asInt` zur Anzeige und zur Dubletten-Erkennung bei
Spielkarten (`index.js:1956`, `1975`, `1995`, `2000`). Es gibt also im ganzen Werkzeug keinen
zweiten, „ganzzahligen" Umrechnungsweg.

## Frage 3 — Überzählige Bits: von links oder von rechts?

**Überzählige Bits werden vorne abgeschnitten; erhalten bleiben die *rechten* Bits.**
`index.js:1919-1922`:

```js
// Discard trailing entropy
var bitsToUse = Math.floor(bits.length / 32) * 32;
var start = bits.length - bitsToUse;
var binaryStr = bits.substring(start);
```

Der Kommentar „Discard trailing entropy" ist irreführend: `substring(start)` schneidet den
**Anfang** weg. Bei 165 Rohbits bleiben die letzten 160 übrig, die ersten 5 fallen
weg — die *zuerst* gewürfelten Augen verlieren also Bits, nicht die zuletzt gewürfelten.
Der gemessene Vektor `99 × „142536"` zeigt genau das (165 → 160 Bit).

## Frage 4 — Was passiert bei einer Wurfzahl, die nicht glatt auf 128/256 bit trifft?

**Es wird nichts aufgefüllt und nichts verweigert: Coleman rundet die Bitzahl auf das
nächstkleinere Vielfache von 32 ab und macht daraus so viele Wörter, wie eben herauskommen**
(3 Wörter je 32 Bit, `index.js:1969`: `Math.floor(numberOfBits / 32) * 3`). Dieselbe
Zeile `index.js:1920` aus Frage 3 ist die ganze Regelung.

Daraus folgen drei Dinge, die für die App zählen:

- **Unter 32 Rohbits gibt es gar kein Mnemonic.** `bitsToUse` wird 0, das Byte-Array bleibt
  leer, `toMnemonic([])` liefert die leere Zeichenkette. Gemessen für die Eingaben `1`
  (2 Bit) und `123456` (10 Bit): das Werkzeug zeigt kein einziges Wort an.
- **Es gibt Wortzahlen außerhalb von BIP39.** 198 Rohbits → 192 Bit → **18 Wörter**;
  308 Rohbits → 288 Bit → **27 Wörter**. BIP39 kennt nur 128–256 bit (12–24 Wörter);
  Coleman erzeugt trotzdem ein 27-Wort-Mnemonic, denn `jsbip39.js:69` `toMnemonic()`
  prüft nur, ob die Bytezahl durch 4 teilbar ist. Wer bei Coleman gegenprüft, kann also
  ohne Warnung ein nicht standardkonformes Ergebnis bekommen.
- **Genau 256 Bit erreicht man nur über die Bitzahl, nicht über die Wurfzahl.**
  Gemessen (Colemans Code, Typ „Dice", Raw):

  | Würfe | nur 1en (2 Bit/Wurf) | nur 4en (1 Bit/Wurf) |
  |---|---|---|
  | 99 | 198 → 192 Bit → 18 Wörter | 99 → 96 Bit → 9 Wörter |
  | 100 | 200 → 192 Bit → 18 Wörter | 100 → 96 Bit → 9 Wörter |
  | 128 | 256 → 256 Bit → 24 Wörter | 128 → 128 Bit → 12 Wörter |
  | 154 | 308 → 288 Bit → **27 Wörter** | 154 → 128 Bit → 12 Wörter |
  | 256 | 512 → 512 Bit → 48 Wörter | 256 → 256 Bit → 24 Wörter |

---

## Der zweite Pfad: feste Wortzahl statt „Use Raw Entropy"

Steht im Auswahlfeld *Mnemonic Length* eine Zahl, spielt die ganze Bit-Tabelle keine Rolle
mehr. `index.js:1892-1906`:

```js
// Use entropy hash if not using raw entropy
var bits = entropy.binaryStr;
var mnemonicLength = DOM.entropyMnemonicLength.val();
if (mnemonicLength != "raw") {
    // Get bits by hashing entropy with SHA256
    var hash = sjcl.hash.sha256.hash(entropy.cleanStr);
    var hex = sjcl.codec.hex.fromBits(hash);
    bits = libs.BigInteger.BigInteger.parse(hex, 16).toString(2);
    while (bits.length % 256 != 0) {
        bits = "0" + bits;
    }
    // Truncate hash to suit number of words
    mnemonicLength = parseInt(mnemonicLength);
    var numberOfBits = 32 * mnemonicLength / 3;
    bits = bits.substring(0, numberOfBits);
```

Wichtig daran:

- Gehasht wird die **gefilterte Zeichenkette** `entropy.cleanStr`, also die Ziffernfolge
  *nach* der Ersetzung 6 → 0. `sha256("123450")` beginnt mit `eb76e225…`, `sha256("123456")`
  mit `8d969eef…` — gemessen wurde `eb76e225…`. Wer diesen Pfad nachbaut, muss die 6 vorher
  zur 0 machen, sonst kommt etwas anderes heraus.
- Hier werden die überzähligen Bits **von rechts** weggeworfen (`substring(0, numberOfBits)`),
  also anders herum als im Raw-Pfad.
- Dieser Pfad erzeugt aus *jeder* Eingabe 24 Wörter, auch aus einem einzigen Wurf. Das
  Werkzeug blendet dazu die Warnung „The mnemonic will appear more secure than it really is"
  ein (`index.js:1908-1910`), rechnet aber trotzdem.

Für Pips39 ist dieser Pfad kein Kandidat: Er ist genau das SHA-256-Verfahren, das Spec 2.1
verwirft. Er ist hier dokumentiert, weil ein Nutzer die Einstellung im Browser leicht
verstellt und dann eine Abweichung sieht, die nicht die App zu verantworten hat.

## Zwei Fallen bei Colemans Auto-Erkennung

`getBase()` (`entropy.js:245-319`) rät den Eingabetyp, solange der Nutzer keinen
Radio-Button angeklickt hat (`entropyTypeAutoDetect`, `index.js:19`, `278`, `400`). Geraten
wird die *niedrigste* passende Basis, und das trifft Würfelfolgen:

- **`1`** (ein einzelner Wurf) wird als **binär** gelesen (`entropy.js:252`: gleich viele
  Binär- wie Hex-Treffer) — nicht als Würfel.
- **99-mal die `1`** ebenso: 99 Bit → 96 Bit → 9 Wörter `zoo zoo … zebra`. Betroffen ist
  genau der Fall „die Folge besteht nur aus 1en" — gemessen: `12` und `1111111112` werden
  als Würfel erkannt, `11` und `111111111` als binär.

Auf der ausgelieferten Seite ist zudem **„Hex" vorausgewählt** (`src/index.html:173`:
`value="hexadecimal" checked`), die Auto-Erkennung überschreibt das aber, bis der Nutzer
selbst klickt. Die Anleitung in der App muss deshalb sagen: **erst „Dice" anklicken, dann
die Folge einfügen**. Die gemessenen Vektoren gelten für ausdrücklich gewählten Typ „Dice".

---

## Gemessene Vektoren

`Tests/Pips39CoreTests/Resources/coleman-vectors.json`. Erhoben am 2026-08-13, indem
Colemans unveränderte Dateien (`entropy.js`, `jsbip39.js`, `sjcl-bip39.js`,
`wordlist_english.js`) unter Node in einem `vm`-Kontext geladen und
`setMnemonicFromEntropy()` zeilengetreu nachgebildet wurde. Einzige Abweichung: `libs.BigInteger`
durch natives `BigInt` ersetzt — das betrifft nur den Hash-Pfad und wurde gegen Pythons
`hashlib.sha256` gegengeprüft. Die Werte stammen also aus Colemans Code, nicht aus diesem
Text; ein Lesefehler in diesem Dokument kann von den Vektoren auffallen.

Ausschließlich Wegwerf-Folgen. Keine davon wurde je für einen echten Seed benutzt.

| Eingabe | Rohbits | genutzt | Wörter | Entropie (hex) |
|---|---|---|---|---|
| `1` | 2 | 0 | 0 | *(leer)* |
| `123456` | 10 | 0 | 0 | *(leer)* |
| 99 × `1` | 198 | 192 | 18 | `5555…5555` |
| 99 × `6` | 198 | 192 | 18 | `0000…0000` |
| 99 × `142536` | 165 | 160 | 15 | `e2b8ae2b8ae2b8ae2b8ae2b8ae2b8ae2b8ae2b8a` |

Die JSON-Datei enthält zusätzlich die gefilterte Folge, die vollständige Rohbitfolge, das
Mnemonic und — zur Abgrenzung — die Ergebnisse des Hash-Pfads für 12 und 24 Wörter. Sie ist
reine Referenzdatenbank; in Phase 1 liest sie noch niemand.

---

## Folgen für `DiceEntropy`

**Was die Swift-Umsetzung tun muss, wenn sie bei Coleman nachrechenbar bleiben soll:**

1. Jeden Wurf einzeln nach Tabelle in Bits übersetzen: `1`→`01`, `2`→`10`, `3`→`11`,
   `4`→`0`, `5`→`1`, `6`→`00`. **Keine** Base-6-Zahlarithmetik, kein `BigInt`.
2. Die Bitfolgen in Wurfreihenfolge aneinanderhängen.
3. Vom Ergebnis das nächstkleinere Vielfache von 32 nehmen und dabei die Bits **vorne**
   abschneiden (die letzten `floor(n/32)*32` Bits behalten).
4. Diese Bits in Bytes zerlegen und in den bereits vorhandenen BIP39-Kern geben.
5. Der Fortschrittsbalken darf **nicht** in Würfen rechnen, sondern in gesammelten Bits.
   Spec 2.4 sagt „Fortschritt in tatsächlich gültigen Würfen" — das muss zu „Fortschritt in
   Bits" werden, sonst zeigt die App eine Sicherheit an, die von den Augenzahlen abhängt.
6. Abbruch, sobald ≥ 256 Bit gesammelt sind. Da ein Wurf höchstens 2 Bit liefert, landet man
   auf 256 oder 257 Bit; in beiden Fällen ergibt Colemans Regel exakt dieselben rechten
   256 Bit. Wer über 287 Bit hinaus weiterwürfeln lässt, bekommt bei Coleman plötzlich
   27 Wörter — also rechtzeitig aufhören.
7. In der Anleitung muss stehen: Typ **„Dice"** anklicken und *Mnemonic Length* auf
   **„Use Raw Entropy"** lassen. Sonst weicht das Vergleichsergebnis ab, ohne dass die App
   etwas falsch gemacht hat.

### 99 oder 100 Würfe für 256 bit?

**Weder noch — die Frage hat bei Coleman keine feste Antwort.** Die Wurfzahl bestimmt die
Bitzahl nicht.

- Die Rechnung aus Spec 11 (99 × log2(6) = 255,9 bit, also 100 Würfe) gilt für die
  *ganzzahlige* Base-6-Umrechnung. **Coleman rechnet so nicht** (Frage 2). Wer 100 Würfe
  fest verdrahtet, weil 255,9 knapp daneben liegt, baut ein Werkzeug, das sich im
  Referenztool nicht nachrechnen lässt — und verliert damit genau die Eigenschaft, für die
  Spec 2.1 dieses Verfahren gewählt hat.
- Bei Colemans Verfahren liefern 99 Würfe zwischen **99 und 198 bit**, im Mittel rund
  165 bit. 256 bit sind damit **prinzipiell unerreichbar**.
- Für 256 bit braucht es **mindestens 128 Würfe** (nur Augen mit 2 Bit), im Mittel
  **rund 154 Würfe** (256 / 1,667), im schlechtesten Fall **256 Würfe** (nur 4en und 5en).

**Empfehlung für die App:** keine feste Wurfzahl versprechen. Die App würfelt, bis 256 Bit
beisammen sind, und zeigt als Erwartung „etwa 154 Würfe, mindestens 128". Für 12 Wörter
(128 bit) entsprechend etwa 77 Würfe, mindestens 64.

Das ist eine Änderung an Spec 2.4 und Spec 11 und sollte dort nachgezogen werden, bevor
`DiceEntropy` gebaut wird.

### Ist das schlimm?

Nicht sicherheitstechnisch: Colemans Verfahren ist bias-frei und liefert am Ende volle
256 Bit echte Entropie, es kostet nur mehr Würfe als die theoretisch mögliche Ausbeute
(1,667 statt 2,585 bit pro Wurf — rund 55 % Mehraufwand). Wer das nicht will, muss die
Nachrechenbarkeit bei Coleman aufgeben; diese Abwägung gehört in die Spec, nicht in den
Code.
