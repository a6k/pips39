import SwiftUI
import Pips39Core

/// Die zwei Seiten für den Weg mit der Nachschlagetabelle.
///
/// Auch dieser Weg gehört auf ein abgeschottetes Gerät — die App sieht zwar nur einen
/// Teil, aber ein Teil ist nicht nichts. Die Checkliste wird hier nur genannt, nicht
/// wiederholt: Wer sie braucht, findet sie über den anderen Weg.
struct LookupOnboardingPages: View {

    @ObservedObject var probe: EnvironmentProbe
    @Binding var page: Int

    var body: some View {
        TabView(selection: $page) {
            needsPage.tag(0)
            exposurePage.tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: B1 — was auf dem Tisch liegen muss

    private var needsPage: some View {
        OnboardingPage(title: "What you need") {
            EnvironmentNotice(probe: probe)

            ForEach(Array(needs.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.caption2)
                        .padding(.top, 5)
                    Text(item).font(.footnote)
                }
            }

            Text("Take this device offline too. It sees less on this path, but less is not nothing.")
                .font(.footnote)
                .foregroundStyle(Brand.secondaryText)
        }
    }

    private let needs: [LocalizedStringKey] = [
        "Five dice. One works too. Throw it five times and keep the order.",
        "A coin. Or a sixth die: 1 to 3 is heads, 4 to 6 is tails.",
        "Paper and a pen for the 23 words.",
        "A hardware wallet. It supplies the 24th word, which this app cannot work out.",
        "A die showing 5 or 6 counts for nothing here. Throw it again until it shows 1 to 4."
    ]

    // MARK: B2 — was die App dabei sieht

    private var exposurePage: some View {
        OnboardingPage(title: "What the app sees") {
            // Eigener Text statt `OnboardingPath.exposure`: Auf der Karte muss dort
            // die kurze Folgerung stehen, hier ist Platz für die Begründung.
            Text("The app gets to see three of the five dice. Which of the 32 words you took from them, it never learns. That leaves 118 of the 256 bits hidden from it.")
                .font(.footnote)

            VStack(alignment: .leading, spacing: 8) {
                Text("Why it is 24 words only")
                    .font(.headline)
                Text("With 12 words too little would stay hidden: 62 bits, which is within reach of an attacker who got hold of what you typed. There is no length switch on this path for that reason.")
                    .font(.footnote)
                    .foregroundStyle(Brand.secondaryText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("The 24th word")
                    .font(.headline)
                Text("It carries a checksum over the other 23, so working it out needs all of them. Your wallet offers eight valid options. Pick between them with three coin flips, not by feel.")
                    .font(.footnote)
                    .foregroundStyle(Brand.secondaryText)
            }

            Text("Method from the BitBox02 dice guide by Shift Crypto, CC BY-SA 4.0.")
                .font(.caption)
                .foregroundStyle(Brand.secondaryText)
        }
    }
}
