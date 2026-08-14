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

    /// Springt direkt in die Seiten eines Wegs — für den Hilfe-Knopf aus einem
    /// laufenden Durchlauf, wo die gemeinsamen Seiten nichts mehr beitragen.
    let startPath: OnboardingPath?

    let onDone: (OnboardingPath?) -> Void

    @State private var path: OnboardingPath?
    @State private var sharedPage = 0
    @State private var pathPage = 0

    private let lastSharedPage = 2
    private let lastPathPage = 1

    init(probe: EnvironmentProbe,
         startPath: OnboardingPath? = nil,
         onDone: @escaping (OnboardingPath?) -> Void) {
        self.probe = probe
        self.startPath = startPath
        self.onDone = onDone
        _path = State(initialValue: startPath)
    }

    var body: some View {
        if let path {
            VStack(spacing: 0) {
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

    /// Kein Verbot. „Nutze das nie für einen echten Seed" machte die App in sich
    /// widersprüchlich — Abschreibkontrolle, Bildschirmschutz und Lockdown-Checkliste
    /// ergeben nur für einen echten Seed Sinn — und wäre wirkungslos: Wer es trotzdem
    /// tut, hat dann von der App selbst gehört, dass ihre Hinweise nicht gelten.
    private var introPage: some View {
        OnboardingPage(title: "The safest way needs no app") {
            Text("Dice, a printed table, paper and a pen, no electronics in the room. That makes a seed no device has ever seen. There is a good guide for it at BitBox.")
                .font(.body)

            Link("bitbox.swiss", destination: URL(string: ExternalLinks.bitboxGuide)!)
                .font(.body.weight(.medium))

            Text("One catch, so nobody is surprised later: paper and a pen get you 23 of the 24 words. The last one carries a checksum over the others, and nobody works that out by hand — a wallet has to supply it.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Where Pips39 sits")
                    .font(.headline)
                Text("It is the step below: for an old iPhone you keep permanently offline. Weaker than paper, stronger than letting a wallet roll the seed for you and hoping it did it properly.")
                    .font(.footnote)
                Text("If you are securing serious money, take the paper route.")
                    .font(.footnote.weight(.medium))
            }
        }
    }

    // MARK: Seite 2 — die Grundlagen

    private var basicsPage: some View {
        OnboardingPage(title: "What a seed is") {
            Text("Your wallet is one very large number. Every key and every address is worked out from it. That number is the seed.")
                .font(.footnote)
            Text("It is written as words only so you can copy it by hand without mistakes. The words are not the secret — the number is.")
                .font(.footnote)
            Text("Nothing else protects it. No password, no device, no company. It is safe exactly as long as nobody can guess the number.")
                .font(.footnote)
            Text("Dice make a number nobody can guess, not even you afterwards. A wallet can make one too, and then you are trusting it to have done it well — which you cannot check. That is the whole reason to roll it yourself.")
                .font(.footnote)

            VStack(alignment: .leading, spacing: 8) {
                Text("About the dice")
                    .font(.headline)
                Text("While you roll, the app watches for sequences that cannot come from dice: all the same value, a repeated block, only two or three of the six values, or long blocks of one value. Each of those is rarer than one in a billion, so the notice never appears on a real run.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("What it cannot see is the dice themselves. A loaded die, or one that leans a little because it is worn, produces sequences that look ordinary. Testing for that would mean a distribution test, and such a test flags correct runs often enough that people learn to ignore it. So there is none. Use dice you trust, and roll them properly.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Seite 3 — die Verzweigung

    private var choicePage: some View {
        OnboardingPage(title: "Two ways from here") {
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
                        Text(option.exposure())
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Text("You can change your mind afterwards — both stay on the start screen.")
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
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }

    /// Zurück statt Überspringen: Wer sich für den falschen Weg entschieden hat, muss
    /// zur Wahl zurückkommen können, und „Los" ist von hier ohnehin ein Tipp entfernt.
    private func pathFooter(for path: OnboardingPath) -> some View {
        HStack {
            Button("Back") {
                if pathPage > 0 {
                    withAnimation { pathPage -= 1 }
                } else if startPath == nil {
                    withAnimation { self.path = nil }
                } else {
                    onDone(nil)
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
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

#Preview {
    OnboardingView(probe: EnvironmentProbe()) { _ in }
}
