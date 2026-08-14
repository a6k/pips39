# Pips39

Roll dice, get a BIP39 seed phrase. Nothing is stored.

Pips39 is a calculator for an old iPhone you keep permanently offline. You roll real
dice, tap the results in, and it shows you 24 words (or 12). Then it helps you check
that you copied them onto paper correctly. That is the whole app.

**It is not a wallet.** It never stores a seed, derives no addresses, signs no
transactions and has no network code. There is nothing in it to steal, because
nothing stays behind.

There is also a third mode, **Lookup table**, which does something different: it
replaces a printed sheet rather than computing a seed. See below.

## Not for real money

The first screen of the app says this, and so does this README:

> **Do not use this app to create a seed for a wallet that will hold real money.**
> Use dice, a printed table and paper for that, in a room without electronics. There is
> a very good guide at
> [Würfle deine eigene Bitcoin-Wallet](https://blog.bitbox.swiss/de/wurfle-deine-eigene-bitcoin-wallet/)
> on the bitbox.swiss blog. It is in German only.

One catch that applies either way: paper and a pen get you 23 of the 24 words. The last
one carries a checksum over the others and nobody works that out by hand, so a wallet
has to supply it.

## How the onboarding is laid out

Three shared pages, then a branch, then two pages for whichever way you chose:

| | Page | Content |
|---|---|---|
| **shared** | 1 · Not for real money | The warning, in two sentences, and the BitBox link |
| | 2 · What this app is for | Air-gapped iPhone, for learning, never for real money |
| | 3 · Two ways from here | The two cards — **this is where it branches** |
| **A** | A1 · Check the app | `shasum`, iancoleman, source — while still online |
| | A2 · Take it offline | The device checklist and what the app cannot tell you |
| **B** | B1 · What you need | Five dice, a coin, a hardware wallet, offline too |
| | B2 · What the app sees | 6 of 11 bits, the 118, the 24th word |

Checking comes before going offline, because checking needs a shell and a browser. The
branch decides only the coarse question — does the app compute, or do I read off? The
fine one (SHA-256 or Coleman, 12 or 24 words) stays on the start screen. Skipping the
onboarding lands you there too, with both ways still on offer.

## Read this before you trust it

> **"Open source" means the source is auditable. It does not mean the binary you
> installed is.**

If you install Pips39 from the App Store, Apple re-signs the app and encrypts the
executable with FairPlay. You cannot byte-compare that download against a build of
this repository — reproducible builds are not achievable on iOS in practice. What you
can verify is the source in front of you, and the app you build yourself from it.

So there are two honest positions, and you should pick one consciously:

- **Convenience:** install from the App Store, read the source here to see what it is
  supposed to do, and accept that the binary is Apple's word.
- **Certainty:** clone this repository and build it yourself in Xcode. The app is
  small enough that this is realistic, not theoretical.

The app also has no way to prove it is offline. iOS gives no app a way to guarantee
that. Pips39 states what it can observe — "this device is connected to a network" —
and never tells you that you are safe. That judgement stays with you.

## Verifying that it computes correctly

Do this **once, on an ordinary computer, with a dice sequence you made up.** Never
type the rolls behind a seed you intend to keep into a browser.

Pips39 offers two ways to turn dice into entropy. They produce **different** seeds
from the same rolls, which is why the method is shown next to the result and should be
written down with the words.

### SHA-256 (the default)

Exactly 99 rolls for 24 words, 50 for 12. The digit string is hashed:

```
printf '%s' "1111…" | shasum -a 256
```

Paste the hex into the Entropy field at [iancoleman.io/bip39](https://iancoleman.io/bip39/),
set Entropy type to `Hex`, and compare the words.

For **12 words, use only the first 32 hex characters** — 128 of the 256 bits. Pasting
all 64 gives you 24 words and a mismatch on a perfectly good seed.

Worked example, 50 rolls of `1`:

```
3dac51a65ec9fcfc409a1b5f1defe92b
diet glad hat rural panther lawsuit act drop gallery urge where fit
```

### Coleman

Bit-for-bit identical to iancoleman.io/bip39 with the Dice entropy type. Enter exactly
the rolls the app shows, no more, and compare.

Two things there will silently give you the wrong answer if you miss them:

1. **Select the Dice entropy type first.** Otherwise a sequence of only `1`s is read
   as binary.
2. **Leave Mnemonic Length on "Use Raw Entropy".** A fixed word count hashes the input
   instead and truncates from the other end.

Coleman does **not** convert dice as a base-6 number, which is what most people assume.
Each roll is looked up in a variable-length bit table (`1→01`, `2→10`, `3→11`, `6→00`,
`4→0`, `5→1`), yielding 1.67 bits per roll instead of 2.585. That is why the roll count
under this method is not fixed. The full analysis, with line references into Coleman's
source, is in [`docs/coleman-verfahren.md`](docs/coleman-verfahren.md).

## The lookup table mode

This one is not a third way to compute a seed. It is a replacement for a sheet of
paper, for people who own dice and a hardware wallet but no printer.

The method comes from *BitBox02 — Würfle deinen eigenen Seed* and its diceware lookup
table by **Shift Crypto AG** ([bitbox.swiss](https://bitbox.swiss)), published under
**CC BY-SA 4.0**. Pips39 is not affiliated with Shift Crypto. The guides themselves are
not redistributed here — see [`BitBox-Anleitung/`](BitBox-Anleitung/) for the
attribution and for what was taken from them and what was not.

Five dice and a coin pick one word from the BIP39 list. A die showing 5 or 6 is thrown
again, so each die carries exactly two unbiased bits — no modulo bias, no truncation:

```
index = (d1−1)·512 + (d2−1)·128 + (d3−1)·32 + (d4−1)·8 + (d5−1)·2 + coin
```

You enter only the **first three dice**. The app then shows the block of 32 words your
word is in; you read off the right one and never type it back. Nothing is computed
beyond that formula — check it against any BIP39 word list and you are done.

### What this costs, stated plainly

The app sees 6 of the 11 bits per word. What stays hidden from it, even if it were
compromised:

| | 24 words | 12 words |
|---|---|---|
| hidden from the app | **118 bit** | **62 bit** |
| for comparison: a printed table | 256 bit | 128 bit |
| for comparison: the normal Pips39 flow | 0 bit | 0 bit |

118 bit is beyond any feasible attack, but it is **below** the 256 bit a dice-rolled
24-word seed otherwise has, and below the usual 128 bit mark. 62 bit is not safe, which
is why the mode is 24 words only and has no length switch.

The 24th word is deliberately out of reach: working it out needs the checksum over all
the others, so a device would have to see all 23 words. Your wallet offers eight valid
options — pick between them with three coin flips, which is exactly the three bits
those eight options carry.

## Building and testing

The security-critical code lives in a Swift package with no UI, so it can be tested
without a simulator:

```
swift test
```

The app target is an ordinary Xcode project:

```
open Pips39/Pips39.xcodeproj
```

### Signing, and why there is no team ID in here

Building for the **simulator** needs nothing extra. Building for a **real device** needs
an Apple development team, and this project deliberately does not carry one: the ID
belongs to a person, and this repository is public.

Put yours in `Pips39/Local.xcconfig`, which `.gitignore` keeps out:

```
DEVELOPMENT_TEAM = <your ten-character team id>
```

`Pips39/Signing.xcconfig` pulls it in with an optional include, so a clone without that
file still builds for the simulator without a warning.

If you contribute, install the commit hook once per clone. It refuses any commit that
carries a team ID into the repository — Xcode writes one back into `project.pbxproj`
whenever you touch the team picker, and reading every diff is not a plan:

```
git config core.hooksPath scripts/githooks
```

Deployment target is iOS 16, deliberately — the point is to reuse an old iPhone. You
will need to select your own signing team.

### What the tests actually check

- All 24 official BIP39 vectors from `trezor/python-mnemonic`
- The word list is byte-identical to `bitcoin/bips` `english.txt`, 2048 entries,
  sorted and duplicate-free
- Five dice vectors produced by running Ian Coleman's **actual JavaScript** under
  node, matched on raw bits, entropy hex and the resulting words
- The SHA-256 path against values computed independently with `shasum`
- That the environment notice never contains the words *safe*, *secure*, *protected*,
  *offline* or *air-gap* — the "no false all-clear" rule, enforced rather than
  intended
- That all 49 BIP39 words which are a prefix of another word stay ambiguous in the
  keyboard, so nothing is ever auto-completed to the wrong word

## Design notes worth knowing

- **The custom keyboard is not decoration.** The iOS system keyboard learns typed
  words, has autocorrect and dictation, and can be replaced by third-party keyboards.
  Typing a seed through it would be a leak in the middle of the security core.
- **Nothing is persisted, not even a "don't show this again" flag.** That is why the
  onboarding appears on every launch.
- **The method and seed length are chosen at the start of a run, not in settings.**
  A setting that silently drifts between sessions would make a user believe a correct
  backup was broken.

## Licence

MIT.

The lookup table mode implements a method described by **Shift Crypto AG** in
*BitBox02 — Würfle deinen eigenen Seed* and its diceware lookup table, both published
under **CC BY-SA 4.0**. Those documents are not part of this repository; the code here
is an independent implementation of the method, not a derivative of them. Attribution
and the detail of what was taken:
[`BitBox-Anleitung/README.md`](BitBox-Anleitung/README.md).
