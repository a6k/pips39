import SwiftUI
import Pips39Core

/// Alles zum Nachschlagen, von jeder Seite aus erreichbar.
///
/// Hier stehen die Texte, die vorher im Onboarding standen und dort im Weg waren. Ein
/// Onboarding wird einmal gelesen und dann weggetippt; diese Sachen braucht man
/// mittendrin, wenn die Frage auftaucht.
struct HelpView: View {

    let onClose: () -> Void

    @ObservedObject var probe: EnvironmentProbe

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    seedSection
                    diceSection
                    offlineSection
                }
                .padding()
                .padding(.bottom, 24)
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
    }

    // MARK: Was ein Seed ist

    private var seedSection: some View {
        section("What a seed is") {
            Text("Your wallet is one very large number. Every key and every address is worked out from it. That number is the seed.")
            Text("It is written as words only so you can copy it by hand without mistakes. The words are not the secret. The number is.")
            Text("Nothing else protects it. No password, no device, no company. Whoever guesses the number has the wallet.")
            Text("Dice make a number nobody can guess, not even you afterwards. A wallet can make one too, and then you are trusting it to have done it well, which you cannot check. That is the whole reason to roll it yourself.")
        }
    }

    // MARK: Zu den Würfeln

    private var diceSection: some View {
        section("About the dice") {
            Text("While you roll, the app watches for sequences that cannot come from dice: all the same value, a repeated block, only two or three of the six values, or long blocks of one value. Each of those is rarer than one in a billion, so the notice never appears on a real run.")
            Text("What it cannot see is the dice themselves. A loaded die, or one that leans a little because it is worn, produces sequences that look ordinary. Testing for that would mean a distribution test, and such a test flags correct runs often enough that people learn to ignore it. So there is none. Use dice you trust, and roll them properly.")
        }
    }

    // MARK: Gerät abschotten

    /// Steht hier, weil das Fragezeichen früher ins Onboarding sprang und die
    /// Checkliste sonst nach dem ersten Wurf nicht mehr erreichbar wäre.
    private var offlineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Take it offline")
                .font(.title3.weight(.semibold))

            EnvironmentNotice(probe: probe)

            ForEach(Array(checklist.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .padding(.top, 5)
                    Text(item).font(.footnote)
                }
            }

            Text("Bluetooth state is not readable by apps since iOS 13, and no network connection does not mean the device is isolated. This app reports what it can see and never claims you are safe. That judgement stays with you.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private let checklist: [LocalizedStringKey] = [
        "Turn off Wi-Fi, cellular, Bluetooth and AirDrop in Settings, not in Control Center.",
        "Turn off iCloud completely: no backup, no keychain sync.",
        "Block USB accessories under Face ID & Passcode.",
        "Turn on Lockdown Mode.",
        "Turn off Settings, App Store, Offload Unused Apps. Otherwise iOS may delete this app and need the network to restore it."
    ]

    // MARK: Gerüst

    private func section<Content: View>(_ title: LocalizedStringKey,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
            content()
                .font(.footnote)
        }
    }
}

#Preview {
    HelpView(onClose: { }, probe: EnvironmentProbe())
}
