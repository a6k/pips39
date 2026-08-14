# BitBox02 Diceware — Quelle und Lizenz

Pips39 setzt im Modus **Nachschlagetabelle** ein Verfahren um, das nicht aus diesem
Projekt stammt.

| | |
|---|---|
| Werk | *BitBox02 — Würfle deinen eigenen Seed* und *BitBox02: Diceware lookup table* |
| Urheber | Shift Crypto AG, [bitbox.swiss](https://bitbox.swiss) |
| Lizenz | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) |
| Bezug | über bitbox.swiss |

Pips39 gehört nicht zu Shift Crypto.

> [!note] Die PDFs selbst liegen nicht im Repo
> Sie stehen unter CC BY-SA 4.0 und dürften weitergegeben werden, sind hier aber
> bewusst nicht mit eingecheckt: Sie sind bei ihrem Urheber besser aufgehoben und
> aktueller. Dieser Ordner enthält nur die Herkunftsangabe. Wer die Dateien lokal
> ablegt, findet sie hier wieder — Git ignoriert sie nicht, sie sind schlicht nicht
> Teil der Veröffentlichung.

## Was übernommen wurde und was nicht

**Übernommen ist die Idee**, kein Inhalt. `Sources/Pips39Core/LookupTable.swift`
berechnet den Wortindex aus derselben Formel:

```
Index = (W1−1)·512 + (W2−1)·128 + (W3−1)·32 + (W4−1)·8 + (W5−1)·2 + Münze
```

Die Wörter kommen aus BIP-39, nicht von Shift Crypto. Die Formel ist gegen die
offizielle Wortliste geprüft (`Tests/Pips39CoreTests/LookupTableTests.swift`), unter
anderem an allen acht Seitengrenzen der gedruckten Tabelle.

**Nicht übernommen wurde** der Rat, das 24. Wort „nach dem Zufallsprinzip" aus den acht
Möglichkeiten zu wählen. Die Anleitung schreibt auf Seite 1 selbst, dass Menschen
schlecht darin sind, zufällig zu wählen. Pips39 sagt an dieser Stelle: drei Münzwürfe —
acht Möglichkeiten sind genau drei Bit.

## Zur Lizenz

CC BY-SA 4.0 verlangt Namensnennung; Bearbeitungen des Werks müssten unter derselben
Lizenz stehen. Der Code in diesem Repo ist keine Bearbeitung der PDFs, sondern eine
eigenständige Umsetzung des beschriebenen Verfahrens, und steht unter MIT (siehe
`../README.md`). Die Namensnennung erfolgt trotzdem überall, wo der Modus auftaucht —
in der App, im Quelltext, im README und in der Spec.
