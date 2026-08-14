import SwiftUI
import Pips39Core

/// Was vor dem ersten Wurf zu tun ist.
///
/// Erscheint bei jedem Start. Ein „nicht mehr anzeigen" wäre gespeicherter Zustand,
/// und die App speichert nichts — auch keine Häkchen.
struct IntroView: View {

    @ObservedObject var probe: EnvironmentProbe
    let onContinue: () -> Void

    private let checklist = [
        "Turn off Wi-Fi, cellular, Bluetooth and AirDrop in Settings — not in Control Center.",
        "Turn off iCloud completely: no backup, no keychain sync.",
        "Block USB accessories under Face ID & Passcode.",
        "Turn on Lockdown Mode.",
        "Turn off Settings, App Store, Offload Unused Apps — otherwise iOS may delete this app and need the network to restore it."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Before you start")
                        .font(.largeTitle.bold())
                    Text("Pips39 turns dice rolls into a BIP39 seed phrase. It stores nothing, derives no addresses and signs no transactions.")
                        .foregroundStyle(.secondary)
                }

                EnvironmentNotice(probe: probe)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Prepare the device")
                        .font(.headline)
                    ForEach(Array(checklist.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle")
                                .font(.caption2)
                                .padding(.top, 5)
                            Text(item).font(.footnote)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What this app cannot tell you")
                        .font(.headline)
                    Text("Bluetooth state is not readable by apps since iOS 13, and no network connection does not mean the device is isolated. This app reports what it can see and never claims you are safe. That judgement stays with you.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                verification

                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
    }

    /// Der Vertrauensbeweis — bewusst **hier** und nicht beim Ergebnis.
    ///
    /// Die Schritte brauchen eine Shell und einen Browser mit Netz. Auf dem
    /// abgeschotteten Gerät gibt es beides nicht, und neben einem scharfen Seed hätten
    /// sie ohnehin nichts zu suchen. Der richtige Zeitpunkt ist jetzt: einmal, vorher,
    /// auf einem gewöhnlichen Rechner, mit einer erfundenen Wurffolge.
    private var verification: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 16) {
                Text("Do this once on an ordinary computer, before you take this device offline. Make up a dice sequence for it. Never use the rolls behind a seed you intend to keep.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(DiceMethod.allCases, id: \.self) { method in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(method.title)
                            .font(.subheadline.weight(.semibold))
                        ForEach(Array(method.verificationSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Text(step).font(.footnote)
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Text("Verify the app before you trust it")
                .font(.headline)
        }
    }
}

#Preview {
    IntroView(probe: EnvironmentProbe()) { }
}
