import SwiftUI
import Pips39Core

/// Drei Seiten in der Reihenfolge, in der man sie abarbeiten kann.
///
/// Die alte einteilige Erklärseite widersprach sich selbst: Sie forderte oben das
/// Abschalten aller Funkwege und unten eine Prüfung, die Shell und Browser braucht.
/// Eine Abfolge lässt sich nicht falsch herum lesen.
struct OnboardingView: View {

    @ObservedObject var probe: EnvironmentProbe
    let onDone: () -> Void

    @State private var page = 0

    private let lastPage = 2

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                verifyPage.tag(0)
                offlinePage.tag(1)
                readyPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            footer
        }
    }

    // MARK: Seite 1 — prüfen, solange das Netz noch da ist

    private var verifyPage: some View {
        page(title: "First: check the app") {
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

    // MARK: Seite 2 — abschotten

    private var offlinePage: some View {
        page(title: "Then: take it offline") {
            EnvironmentNotice(probe: probe)

            ForEach(Array(checklist.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .padding(.top, 5)
                    Text(item).font(.footnote)
                }
            }

            Text("The notice above disappears once there is no connection left. That is a statement, not an all-clear — see the last page.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private let checklist = [
        "Turn off Wi-Fi, cellular, Bluetooth and AirDrop in Settings — not in Control Center.",
        "Turn off iCloud completely: no backup, no keychain sync.",
        "Block USB accessories under Face ID & Passcode.",
        "Turn on Lockdown Mode.",
        "Turn off Settings, App Store, Offload Unused Apps — otherwise iOS may delete this app and need the network to restore it."
    ]

    // MARK: Seite 3 — was bleibt

    private var readyPage: some View {
        page(title: "Ready") {
            EnvironmentNotice(probe: probe)

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

    // MARK: Gerüst

    private func page<Content: View>(title: String,
                                     @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.largeTitle.bold())
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .padding(.bottom, 28)
        }
    }

    /// Immer sichtbar, damit man zum Starten nicht ans Seitenende scrollen muss.
    private var footer: some View {
        HStack {
            Button("Skip", action: onDone)
                .buttonStyle(.bordered)

            Spacer()

            Button(page == lastPage ? "Start" : "Next") {
                if page == lastPage {
                    onDone()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

#Preview {
    OnboardingView(probe: EnvironmentProbe()) { }
}
