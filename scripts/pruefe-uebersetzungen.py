#!/usr/bin/env python3
"""Findet Oberflächentexte, die keine deutsche Übersetzung haben.

Der Anlass: Wer einen Satz im Swift-Code ändert, ändert damit den Schlüssel. Die
alte Übersetzung hängt danach an einem Schlüssel, den niemand mehr nachschlägt, und
der neue Satz erscheint in der deutschen Oberfläche auf Englisch. Auffallen tut das
erst, wenn jemand genau diesen Bildschirm ansieht.

Zwei Sorten Fehlalarm sind eingebaut abgefangen:

  * **Interpolierte Schlüssel.** `Text("Word \\(n) of \\(m)")` wird zu `Word %lld of
    %lld` und steht nirgends wörtlich im Quelltext.
  * **Namen und Adressen.** `iancoleman.io/bip39` oder ein Artikeltitel sind in
    beiden Sprachen dasselbe und stehen deshalb bewusst nicht in der Tabelle.

Aufruf aus dem Repo-Wurzelverzeichnis:

    python3 scripts/pruefe-uebersetzungen.py

Rückgabewert 1, wenn etwas fehlt, sonst 0.
"""

import glob
import os
import re
import sys

APP = "Pips39/Pips39"
AUSNAHMEN = {
    # In beiden Sprachen gleich, deshalb absichtlich nicht in der Tabelle.
    "Würfle deine eigene Bitcoin-Wallet",
    "github.com/a6k/pips39",
    "iancoleman.io/bip39",
    "git config core.hooksPath scripts/githooks",
}


def deutsche_schluessel() -> set[str]:
    pfad = os.path.join(APP, "de.lproj", "Localizable.strings")
    with open(pfad, encoding="utf-8") as datei:
        inhalt = datei.read()
    return set(re.findall(r'^"((?:[^"\\]|\\.)*)"\s*=', inhalt, re.M))


def literale() -> dict[str, str]:
    gefunden: dict[str, str] = {}
    for pfad in glob.glob(os.path.join(APP, "*.swift")):
        with open(pfad, encoding="utf-8") as datei:
            quelle = re.sub(r"^\s*//.*$", "", datei.read(), flags=re.M)
        for treffer in re.finditer(r'"((?:[^"\\\n]|\\.)+)"', quelle):
            text = treffer.group(1)
            if len(text) < 12:
                continue
            if "\\(" in text:            # interpoliert, siehe Kopf
                continue
            if re.fullmatch(r"[a-z0-9.]+", text):   # SF-Symbolnamen
                continue
            if text in AUSNAHMEN:
                continue
            gefunden.setdefault(text, os.path.basename(pfad))
    return gefunden


def main() -> int:
    bekannt = deutsche_schluessel()
    fehlend = {t: d for t, d in literale().items() if t not in bekannt}

    if not fehlend:
        print("Alle Oberflächentexte haben eine deutsche Fassung.")
        return 0

    print(f"{len(fehlend)} Text(e) ohne Übersetzung:\n")
    for text, datei in sorted(fehlend.items(), key=lambda paar: paar[1]):
        print(f"  {datei}")
        print(f'    "{text}" = "";\n')
    return 1


if __name__ == "__main__":
    sys.exit(main())
