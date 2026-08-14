import SwiftUI
import Pips39Core

/// Die einzelnen Hilfeseiten. Jede beantwortet eine Frage und hört dann auf.

// MARK: Gerüst

/// Eine Hilfeseite: scrollbar, links ausgerichtet, mit Überschrift in der Leiste.
private struct HelpPage<Content: View>: View {

    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .padding(.bottom, 24)
        }
        .sheetBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Eine Zwischenüberschrift innerhalb einer Seite.
private struct HelpHeading: View {
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .font(.headline)
            .padding(.top, 6)
    }
}

/// Eine Zeile aus Angreifer und Dauer. Kein echtes Tabellenraster: Zwei Spalten
/// nebeneinander sind auf einem Telefon lesbar, drei nicht mehr.
private struct HelpRow: View {
    let label: LocalizedStringKey
    let value: LocalizedStringKey
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
            Spacer(minLength: 12)
            Text(value).fontWeight(.semibold).monospacedDigit()
        }
        .font(.footnote)
    }
}

/// Eine Befehls- oder Konfigurationszeile. Nichtproportional und auf eigener Fläche,
/// damit klar ist, dass sie genau so abgetippt wird.
private struct HelpCode: View {
    // `LocalizedStringKey`, nicht `String`: Ein einfacher String geht unübersetzt
    // durch. Der Schlüsselname bleibt in beiden Sprachen stehen, nur der Platzhalter
    // dahinter wird übersetzt.
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Brand.sheetRow)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: Was ein Seed ist

struct HelpSeedTopic: View {
    var body: some View {
        HelpPage(title: "What a seed is") {
            Text("Your wallet is one very large number. Every key and every address is worked out from it. That number is the seed.")
            Text("It is written as words only so you can copy it by hand without mistakes. The words are not the secret. The number is.")
            Text("Nothing else protects it. No password, no device, no company. Whoever guesses the number has the wallet.")
            Text("Dice make a number nobody can guess, not even you afterwards. A wallet can make one too, and then you are trusting it to have done it well, which you cannot check. That is the whole reason to roll it yourself.")
        }
        .font(.footnote)
    }
}

// MARK: Das letzte Wort und die Prüfsumme

struct HelpChecksumTopic: View {
    var body: some View {
        HelpPage(title: "The last word and the checksum") {
            Text("Every BIP39 phrase carries a checksum in its last word. With 12 words that is 4 bits, with 24 words 8 bits.")

            Text("12 words are 132 bits: 128 bits of entropy plus 4 bits of checksum. The twelfth word is therefore 7 entropy bits and 4 checksum bits. With 24 words it is 264 bits, 256 plus 8, and the last word is 3 entropy bits and 8 checksum bits.")

            HelpHeading(text: "Why you never notice it here")
            Text("SHA-256 and Coleman produce the whole entropy block first. The app works out the checksum itself and then cuts the block into words. The last word simply falls out, there is nothing to choose and nothing to ask.")

            HelpHeading(text: "Why you do notice it with the word table")
            Text("There the words arrive one at a time. After 23 words you have 253 bits and cannot look the last one up, because its checksum needs all the others. That is why a wallet has to supply it.")

            Text("This also explains how many options a wallet offers you. With 24 words, 3 bits are left free, so 8 options. With 12 words it would be 7 free bits, so 128.")

            HelpHeading(text: "Check it yourself")
            Text("Take a finished phrase into any BIP39 tool and swap the last word for another one from the list. In about fifteen of sixteen cases the phrase becomes invalid, because the 4 checksum bits no longer match.")
        }
        .font(.footnote)
    }
}

// MARK: Zu den Würfeln

struct HelpDiceTopic: View {
    var body: some View {
        HelpPage(title: "About the dice") {
            Text("While you roll, the app watches for sequences that cannot come from dice: all the same value, a repeated block, only two or three of the six values, or long blocks of one value. Each of those is rarer than one in a billion, so the notice never appears on a real run.")
            Text("What it cannot see is the dice themselves. A loaded die, or one that leans a little because it is worn, produces sequences that look ordinary. Testing for that would mean a distribution test, and such a test flags correct runs often enough that people learn to ignore it. So there is none. Use dice you trust, and roll them properly.")
        }
        .font(.footnote)
    }
}

// MARK: Wie sicher ist das wirklich

struct HelpStrengthTopic: View {
    var body: some View {
        HelpPage(title: "How safe is this really") {
            Text("On the SHA-256 and Coleman tabs the app sees your whole seed while it is on screen. So this page is about the word table, where it sees only a part.")

            Text("There the app gets three of the five dice per word. Five of the eleven bits per word stay hidden from it. Across 23 words plus the free bits of the last one, that is 118 bits.")

            HelpHeading(text: "Suppose the phone recorded everything")
            Text("Then someone with that recording would still have to try 2¹¹⁸ combinations, about 3 followed by 35 zeros. Every attempt has to go through PBKDF2 with 2048 rounds, which is slow on purpose.")

            HelpHeading(text: "24 words, 118 bits hidden")
            HelpRow(label: "10,000 GPUs", value: "10¹⁸ years")
            HelpRow(label: "1 million GPUs", value: "10¹⁶ years")
            HelpRow(label: "100 million GPUs", value: "10¹⁴ years")

            Text("For comparison, the universe is about 10¹⁰ years old.")
                .foregroundStyle(Brand.secondaryText)

            HelpHeading(text: "12 words, 62 bits hidden")
            Text("This is why the word table has no length switch. With 12 words only 62 bits would stay hidden, and that is a different world:")
            HelpRow(label: "10,000 GPUs", value: "15 years")
            HelpRow(label: "1 million GPUs", value: "53 days")
            HelpRow(label: "100 million GPUs", value: "13 hours")

            Text("Between the two lies a factor of 70 quadrillion. That is not a gradual difference. It is the line between something a well funded attacker manages and something nobody manages.")

            HelpHeading(text: "There is nothing to filter out")
            Text("Every one of those combinations gives a valid BIP39 phrase, because the checksum follows from the entropy. An attacker cannot discard any of them cheaply. They gain nothing from the checksum either.")

            HelpHeading(text: "What this calculation assumes")
            Text("That the phone recorded what it saw. Without that recording it is the full 128 or 256 bits, and no number in the tables above applies.")
            Text("And that the attacker knows what to look for, meaning they have an address to check against.")
            Text("What no number protects against: somebody photographing your paper.")
                .fontWeight(.medium)
        }
        .font(.footnote)
    }
}

// MARK: Der Quellcode

struct HelpSourceTopic: View {
    var body: some View {
        HelpPage(title: "The source code") {
            Text("You do not have to believe these pages. Everything this app does is open, and you can read it and build it yourself.")

            // Unterstrichen wie überall: Der Akzent ist Weiß, ohne Unterstrich wäre
            // der Link vom Fließtext nicht zu unterscheiden.
            Link("github.com/a6k/pips39",
                 destination: URL(string: ExternalLinks.sourceCode)!)
                .font(.footnote.weight(.medium))
                .underline()

            HelpHeading(text: "Building it")
            Text("Clone the repository and open Pips39/Pips39.xcodeproj. For the simulator that is everything you need.")

            HelpHeading(text: "Checking the maths without a simulator")
            Text("The part that turns dice into words is a Swift package with no interface, so it can be tested on its own. Running swift test in the repository checks it against the official BIP39 test vectors, among others.")

            HelpHeading(text: "Building for a real iPhone")
            Text("That needs an Apple development team, and this project carries none on purpose: the ID belongs to a person, and the repository is public.")
            Text("Put yours in Pips39/Local.xcconfig, a file that .gitignore keeps out of the repository:")
            HelpCode(text: "DEVELOPMENT_TEAM = your ten-character team id")
            Text("Pips39/Signing.xcconfig pulls that file in with an optional include, so a clone without it still builds for the simulator.")
            Text("Xcode writes the team ID back into project.pbxproj whenever you touch the team picker. If you contribute, install the commit hook once per clone; it refuses any commit that carries an ID into the repository.")
            HelpCode(text: "git config core.hooksPath scripts/githooks")
        }
        .font(.footnote)
    }
}

// MARK: Gerät abschotten

struct HelpOfflineTopic: View {

    @ObservedObject var probe: EnvironmentProbe

    private let checklist: [LocalizedStringKey] = [
        "Turn off Wi-Fi, cellular, Bluetooth and AirDrop in Settings, not in Control Center.",
        "Turn off iCloud completely: no backup, no keychain sync.",
        "Block USB accessories under Face ID & Passcode.",
        "Turn on Lockdown Mode.",
        "Turn off Settings, App Store, Offload Unused Apps. Otherwise iOS may delete this app and need the network to restore it."
    ]

    var body: some View {
        HelpPage(title: "Take it offline") {
            EnvironmentNotice(probe: probe)

            ForEach(Array(checklist.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .padding(.top, 5)
                    Text(item)
                }
            }

            Text("Bluetooth state is not readable by apps since iOS 13, and no network connection does not mean the device is isolated. This app reports what it can see and never claims you are safe. That judgement stays with you.")
                .foregroundStyle(Brand.secondaryText)
        }
        .font(.footnote)
    }
}

#Preview {
    NavigationStack { HelpStrengthTopic() }
}
