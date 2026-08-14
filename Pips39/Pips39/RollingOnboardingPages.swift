import SwiftUI
import Pips39Core

/// Die zwei Seiten für den Weg, auf dem die App rechnet.
///
/// Prüfen kommt vor Abschotten: Die Prüfung braucht Shell und Browser, danach ist beides
/// weg. Neu gegenüber Phase 7 ist nur, dass diese Seiten nicht mehr die ersten der App
/// sind — davor stehen drei gemeinsame, die erklären, worum es überhaupt geht.
struct RollingOnboardingPages: View {

    @ObservedObject var probe: EnvironmentProbe
    @Binding var page: Int

    var body: some View {
        TabView(selection: $page) {
            verifyPage.tag(0)
            offlinePage.tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: A1 — prüfen, solange das Netz noch da ist

    private var verifyPage: some View {
        OnboardingPage(title: "First: check the app") {
            Text("Do this now, while this device is still online. Make up a dice sequence for it — never use the rolls behind a seed you intend to keep.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(DiceMethod.allCases, id: \.rawValue) { method in
                VStack(alignment: .leading, spacing: 6) {
                    Text(method.title)
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(method.verificationSteps(for: .standard).enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(step).font(.footnote)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Link("iancoleman.io/bip39", destination: URL(string: ExternalLinks.colemanTool)!)
                Link("Source code on GitHub", destination: URL(string: ExternalLinks.sourceCode)!)
            }
            .font(.footnote.weight(.medium))

            Text("Tapping a link opens Safari. That is fine now and not later — do it before you take the device offline.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: A2 — abschotten, und was danach offen bleibt

    private var offlinePage: some View {
        OnboardingPage(title: "Then: take it offline") {
            EnvironmentNotice(probe: probe)

            ForEach(Array(checklist.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .padding(.top, 5)
                    Text(item).font(.footnote)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What this app cannot tell you")
                    .font(.headline)
                Text("Bluetooth state is not readable by apps since iOS 13, and no network connection does not mean the device is isolated. This app reports what it can see and never claims you are safe. That judgement stays with you.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("How this ends")
                    .font(.headline)
                Text("Nothing is stored. Write the words on paper, note the method next to them, and check your copy with the app before you leave the screen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private let checklist: [LocalizedStringKey] = [
        "Turn off Wi-Fi, cellular, Bluetooth and AirDrop in Settings — not in Control Center.",
        "Turn off iCloud completely: no backup, no keychain sync.",
        "Block USB accessories under Face ID & Passcode.",
        "Turn on Lockdown Mode.",
        "Turn off Settings, App Store, Offload Unused Apps — otherwise iOS may delete this app and need the network to restore it."
    ]
}
