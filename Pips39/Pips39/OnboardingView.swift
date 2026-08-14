import SwiftUI
import Pips39Core

/// Zuerst drei Seiten für alle, dann die des gewählten Wegs.
///
/// Die alte Fassung begann mit `shasum` — der Antwort auf die Frage des Misstrauischen,
/// gestellt bevor die des Unwissenden beantwortet war. Wer das Thema nicht kennt, war
/// nach zehn Sekunden weg.
///
/// Die Verzweigung ist eine Abkürzung, keine Sperre: Wer überspringt, landet auf der
/// Startseite, auf der beide Wege weiterhin stehen.
struct OnboardingView: View {

    @ObservedObject var probe: EnvironmentProbe

    let onDone: (OnboardingPath?) -> Void

    @State private var path: OnboardingPath?
    @State private var sharedPage = 0
    @State private var pathPage = 0

    private let lastSharedPage = 2
    private let lastPathPage = 1

    var body: some View {
        if let path {
            VStack(spacing: 0) {
                TopBar().padding(.horizontal).padding(.top, 8)

                switch path {
                case .rollAndCompute:
                    RollingOnboardingPages(probe: probe, page: $pathPage)
                case .lookupTable:
                    LookupOnboardingPages(probe: probe, page: $pathPage)
                }
                pathFooter(for: path)
            }
        } else {
            VStack(spacing: 0) {
                TopBar().padding(.horizontal).padding(.top, 8)

                TabView(selection: $sharedPage) {
                    introPage.tag(0)
                    basicsPage.tag(1)
                    choicePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                sharedFooter
            }
        }
    }

    // MARK: Seite 1 — die Einordnung

    /// Zwei Sätze, sonst nichts.
    ///
    /// Die vorige Fassung ordnete die App auf einer Skala ein, statt zu warnen. Das
    /// las sich wie Werbung und ging an der Aussage vorbei, die hier stehen soll.
    /// Jeder weitere Satz auf dieser Seite schwächt die Warnung ab, deshalb stehen die
    /// Einzelheiten auf den folgenden Seiten und nicht hier.
    private var introPage: some View {
        OnboardingPage(title: "Not for real money") {
            // Weiß und fett, ohne Fläche: Der Satz steht für sich, er *ist* die
            // Seite. Rot war hier nie eine Wahl mehr, seit der Grund violett ist.
            Text("Do not use this app to create a seed for a wallet that will hold real money.")
                .font(.body.weight(.semibold))

            Text("Use dice, a printed table and paper for that, in a room without electronics.")
                .font(.body)

            VStack(alignment: .leading, spacing: 6) {
                Text("There is a very good guide for it on the bitbox.swiss site:")
                    .font(.body)
                // Als Beschriftung der Titel des Artikels und nicht die nackte
                // Adresse: Der Satz nennt die Seite bereits, und ein Slug über zwei
                // Zeilen sagt niemandem, was ihn erwartet.
                Link("Würfle deine eigene Bitcoin-Wallet",
                     destination: URL(string: ExternalLinks.bitboxGuide)!)
                    .font(.body.weight(.medium))
            }
        }
    }

    // MARK: Seite 2 — die Grundlagen

    /// Wofür die App da ist, in drei Sätzen.
    ///
    /// Hier stand vorher eine Einführung in BIP39 und die Grenzen der
    /// Wurffolgen-Prüfung. Beides gehört in eine Hilfe, nicht an die zweite Stelle
    /// eines Onboardings: Wer die App öffnet, will wissen, wofür sie gedacht ist, und
    /// nicht als Erstes einen Aufsatz lesen.
    private var basicsPage: some View {
        OnboardingPage(title: "What this app is for") {
            Text("For an old iPhone that you take offline and never connect to a network again.")
                .font(.body)

            Text("Mainly to try out and understand how rolling your own seed works.")
                .font(.body)

            Text("Never put real money on a seed that came out of this app.")
                .font(.body.weight(.semibold))
        }
    }

    // MARK: Seite 3 — die Verzweigung

    private var choicePage: some View {
        OnboardingPage(title: "Two ways to roll") {
            Text("What differs: what you tap in, and who turns it into words.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(OnboardingPath.allCases) { option in
                Button {
                    pathPage = 0
                    path = option
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(option.title())
                            .font(.title3.weight(.semibold))
                        Text(option.summary())
                            .font(.footnote)
                        // Eine dunkle Fläche nur auf dem Weg, der den Seed offenlegt.
                        // Das ist der wichtigste Satz der Seite; ohne Fläche steht er
                        // in derselben Farbe und Strichstärke wie der Rest und wird
                        // beim Überfliegen übersehen.
                        Text(option.exposure())
                            .font(.footnote.weight(option.appSeesEverything ? .semibold : .medium))
                            .foregroundStyle(option.appSeesEverything ? Color.primary : Color.secondary)
                            .modifier(ExposureBackground(highlighted: option.appSeesEverything))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Brand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Text("You can change your mind afterwards. Both stay on the start screen.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Fußleisten

    /// Überspringen bleibt ab der ersten Seite sichtbar. Es wird nichts gespeichert,
    /// das Onboarding läuft also bei **jedem** Start — ohne diesen Knopf würde der
    /// zweite Durchlauf zur Strafe.
    private var sharedFooter: some View {
        HStack {
            Button("Skip") { onDone(nil) }
                .buttonStyle(.bordered)

            Spacer()

            if sharedPage < lastSharedPage {
                Button("Next") {
                    withAnimation { sharedPage += 1 }
                }
                .buttonStyle(.brandProminent)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        // Kein `.bar`-Material: Es bringt auf dem Verlauf einen grauen Ton mit,
        // der zu keiner der beiden Verlaufsfarben passt. Durchscheinendes Weiß
        // hellt nur auf und lässt den Verlauf durch.
        .background(Color.white.opacity(0.08))
    }

    /// Zurück statt Überspringen: Wer sich für den falschen Weg entschieden hat, muss
    /// zur Wahl zurückkommen können, und „Los" ist von hier ohnehin ein Tipp entfernt.
    private func pathFooter(for path: OnboardingPath) -> some View {
        HStack {
            Button("Back") {
                if pathPage > 0 {
                    withAnimation { pathPage -= 1 }
                } else {
                    withAnimation { self.path = nil }
                }
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(pathPage == lastPathPage ? "Start" : "Next") {
                if pathPage == lastPathPage {
                    onDone(path)
                } else {
                    withAnimation { pathPage += 1 }
                }
            }
            .buttonStyle(.brandProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        // Kein `.bar`-Material: Es bringt auf dem Verlauf einen grauen Ton mit,
        // der zu keiner der beiden Verlaufsfarben passt. Durchscheinendes Weiß
        // hellt nur auf und lässt den Verlauf durch.
        .background(Color.white.opacity(0.08))
    }
}

/// Die Fläche unter dem Offenlegungssatz, und nur dort.
///
/// Als eigener Modifikator, weil `if` im Ansichtsbaum an dieser Stelle den Knopf-Inhalt
/// zerlegen würde und die Karte dann bei jedem Wechsel neu aufbaut.
private struct ExposureBackground: ViewModifier {
    let highlighted: Bool
    func body(content: Content) -> some View {
        if highlighted {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Brand.panel)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            content
        }
    }
}

#Preview {
    OnboardingView(probe: EnvironmentProbe()) { _ in }
}
