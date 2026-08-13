# Pips39

Ein Rechner, der aus Würfelwürfen einen BIP39-Seed macht und beim korrekten
Abschreiben hilft. Keine Wallet: es wird nichts gespeichert, keine Adresse
abgeleitet, keine Transaktion signiert.

## Aufbau

- `Sources/Pips39Core` — Kernlogik ohne UI, per `swift test` prüfbar
- Die iOS-App kommt in einer späteren Phase als eigenes Target dazu

## Tests

    swift test

## Lizenz

MIT
