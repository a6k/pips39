# App-Store-Texte für Pips39

Stand 2026-08-15, Version 0.0.1. Zwei Lokalisierungen: **Deutsch (primär)** und
**Englisch**. Fehlt eine Sprache, zeigt der Store die primäre, ein Leser in den USA
bekäme also den deutschen Text.

Die Zeichengrenzen von App Store Connect stehen jeweils dabei. Untertitel und Keywords
sind die knappsten, dort ist jedes Zeichen gezählt.

---

## Deutsch

### Name (30 Zeichen)

```
Pips39
```

### Untertitel (30 Zeichen, hier 26)

```
BIP39-Seeds würfeln lernen
```

### Werbetext (170 Zeichen, jederzeit änderbar ohne neue Version)

```
Für ein altes iPhone, das offline bleibt. Würfel eintippen, Wörter ablesen, Abschrift prüfen. Nichts wird gespeichert.
```

### Beschreibung (4000 Zeichen)

```
Pips39 macht aus echten Würfelwürfen eine BIP39-Wortfolge. Die App ist für ein altes
iPhone gedacht, das du dauerhaft vom Netz nimmst, und vor allem dafür, das Verfahren
zu verstehen, bevor du es auf Papier anwendest.

Sie ist keine Wallet. Sie speichert nichts, leitet keine Adressen ab, signiert keine
Transaktionen und hat keinen Netzwerkcode. Es bleibt nichts zurück, wenn du sie
schließt.


DREI WEGE, DIE NEBENEINANDER STEHEN

SHA-256: Genau 99 Würfe für 24 Wörter, 50 für 12. Die Ziffernfolge wird gehasht.
Nachprüfbar mit shasum und jedem BIP39-Werkzeug.

Coleman: Bit für Bit identisch mit iancoleman.io/bip39. Jeder Wurf steht für eine
unterschiedliche Zahl von Bits, deshalb liegt die Wurfzahl nicht fest.

Worttabelle: Hier rechnet die App nicht, sondern ersetzt ein Blatt Papier. Fünf Würfel
und eine Münze wählen ein Wort; eingetippt werden nur die ersten drei Würfel. Die App
zeigt 32 Kandidaten, und welchen du genommen hast, erfährt sie nie.


WAS DIE APP ÜBER SICH SAGT

Auf dem ersten Bildschirm steht, dass du mit ihr keinen Seed für eine Wallet erzeugen
sollst, in die echtes Geld kommt. Dafür sind Würfel, eine gedruckte Tabelle und Papier
in einem Raum ohne Elektronik der richtige Weg.

Die App kann nicht beweisen, dass ein Gerät offline ist. iOS gibt keiner App diese
Möglichkeit. Sie benennt, was sie sieht, und behauptet nie, dass alles in Ordnung sei.


ABSCHREIBKONTROLLE MIT EIGENER TASTATUR

Nach dem Notieren tippst du die Wörter zurück, und die App bestätigt Position für
Position. Dafür bringt sie eine eigene Buchstabentastatur mit, die nur die Buchstaben
freigibt, mit denen ein BIP39-Wort weitergehen kann. Die Systemtastatur lernt Wörter,
korrigiert und lässt sich ersetzen, und käme deshalb für einen Seed nicht in Frage.


HILFE, DIE ERKLÄRT STATT ZU BERUHIGEN

Sechs Seiten zu dem, was hinter dem Verfahren steht: was ein Seed ist, warum das letzte
Wort eine Prüfsumme trägt, was die Wurffolgen-Prüfung leisten kann und was nicht, wie
lange ein Angreifer bei 118 verborgenen Bit tatsächlich rechnen müsste, wie du das
Gerät abschottest, und wie du die App selbst aus dem Quelltext baust.


QUELLTEXT OFFEN

github.com/a6k/pips39

Der Rechenkern liegt in einem Swift-Paket ohne Oberfläche und lässt sich mit swift test
gegen die offiziellen BIP39-Testvektoren prüfen, ohne Simulator.

Offener Quelltext heißt, dass der Quelltext nachprüfbar ist. Er heißt nicht, dass die
Fassung aus dem App Store es ist: Apple signiert und verschlüsselt sie neu. Wer Gewissheit
will, baut die App selbst.


Das Verfahren der Worttabelle stammt aus der Anleitung von Shift Crypto AG zum BitBox02,
veröffentlicht unter CC BY-SA 4.0. Pips39 gehört nicht zu Shift Crypto.
```

### Keywords (100 Zeichen, kommagetrennt, keine Leerzeichen)

```
bip39,seed,würfel,mnemonic,entropie,offline,airgap,dice,sha256,wortliste,selbstverwahrung
```

> [!warning] Zielkonflikt bei den Keywords
> `bitcoin` und `wallet` bringen die meisten Treffer, ziehen die App aber in die
> Finanz-Ecke, und genau dort greift Guideline 3.1.5 (b) für Kryptowährungen. Die
> Liste oben lässt beide weg. Wer sie aufnimmt, sollte damit rechnen, dass die Review
> genauer hinsieht.

---

## Englisch

### Name

```
Pips39
```

### Untertitel (30 Zeichen, hier 28)

```
Learn to roll a BIP39 seed
```

### Werbetext (170 Zeichen)

```
For an old iPhone you keep offline. Tap in your dice, read off the words, check what you copied. Nothing is stored.
```

### Beschreibung

```
Pips39 turns real dice rolls into a BIP39 word list. It is meant for an old iPhone you
take offline for good, and above all for understanding the method before you use it on
paper.

It is not a wallet. It stores nothing, derives no addresses, signs no transactions and
has no network code. Nothing stays behind when you close it.


THREE WAYS, SIDE BY SIDE

SHA-256: Exactly 99 rolls for 24 words, 50 for 12. The digit string is hashed.
Verifiable with shasum and any BIP39 tool.

Coleman: Bit for bit identical to iancoleman.io/bip39. Each roll stands for a varying
number of bits, which is why the roll count is not fixed.

Word table: Here the app does not compute, it replaces a sheet of paper. Five dice and
a coin pick one word; only the first three dice are typed in. The app shows 32
candidates and never learns which one you took.


WHAT THE APP SAYS ABOUT ITSELF

The first screen says not to use it for a seed that will hold real money. For that, use
dice, a printed table and paper in a room without electronics.

The app cannot prove a device is offline. iOS gives no app that ability. It states what
it can observe and never tells you that you are safe.


TRANSCRIPTION CHECK WITH ITS OWN KEYBOARD

After writing the words down you type them back, and the app confirms them one position
at a time. It brings its own letter keyboard, which only enables letters a BIP39 word
can continue with. The system keyboard learns words, autocorrects and can be replaced,
so it is no place for a seed.


HELP THAT EXPLAINS INSTEAD OF REASSURING

Six pages on what is behind the method: what a seed is, why the last word carries a
checksum, what the roll-pattern check can and cannot do, how long an attacker would
really need against 118 hidden bits, how to take the device offline, and how to build
the app yourself from source.


SOURCE OPEN

github.com/a6k/pips39

The computing core is a Swift package with no interface and can be checked against the
official BIP39 test vectors with swift test, no simulator needed.

Open source means the source is auditable. It does not mean the build from the App
Store is: Apple re-signs and encrypts it. If you want certainty, build it yourself.


The word table method comes from Shift Crypto AG's BitBox02 dice guide, published under
CC BY-SA 4.0. Pips39 is not affiliated with Shift Crypto.
```

### Keywords

```
bip39,seed,dice,mnemonic,entropy,offline,airgap,sha256,wordlist,selfcustody,rolls
```

---

## Review-Notizen (App Review Information, nur für Apple)

Nicht öffentlich. Hier zählt, dass der Reviewer die App in zwei Minuten bedienen kann
und die Einordnung versteht.

```
This app is a calculator and a teaching tool. It is NOT a wallet:
it stores nothing, derives no addresses, signs no transactions,
holds no keys and has no network code at all.

HOW TO TRY IT IN UNDER A MINUTE
1. Tap "Skip" on the onboarding.
2. On the SHA-256 tab, choose "12 words".
3. Tap "Start rolling".
4. Tap the same die face 50 times. The app then shows 12 words.
   (A notice will appear saying the sequence looks degenerate.
   That is correct and intended: 50 identical rolls cannot come
   from real dice. Tap "Show words" anyway.)
5. "I wrote them down" starts the transcription check.

WHY THE FIRST SCREEN WARNS AGAINST USING IT
The app is for learning how dice-generated seeds work. Telling
users not to put real money on the result is the honest thing to
do, and it is part of the teaching. It is not a disclaimer for a
broken app.

ABOUT GUIDELINE 3.1.5(b)
The app does not store, transmit or manage virtual currency. It
produces a word list on screen from user input and forgets it.
There is no wallet functionality of any kind.

The third tab ("Word table") does not even compute a seed. It
replaces a printed lookup sheet: the user enters three of five
dice, the app shows 32 candidate words, and the user reads one
off. The app never learns which one.

SOURCE
github.com/a6k/pips39
```

---

## Was noch fehlt, bevor eingereicht werden kann

- [ ] **Support-URL.** Pflicht. Eine Seite unter comodin.com genügt, mit einer
      Kontaktmöglichkeit.
- [ ] **Datenschutzerklärung-URL.** Pflicht, auch wenn nichts erhoben wird. Sie muss
      sagen, dass nichts erhoben wird.
- [ ] **App-Privacy-Fragebogen** in Connect. Antwort auf alles: „Data Not Collected".
- [ ] **Altersfreigabe.** Der Fragebogen führt bei dieser App zu 4+.
- [ ] **Kategorie.** Primär Education, sekundär Utilities.
- [ ] **Screenshots auf Englisch**, falls die englische Lokalisierung angelegt wird.
      Simulator auf Englisch stellen und dieselben vier Bildschirme aufnehmen.
