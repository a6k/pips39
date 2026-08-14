import SwiftUI
import Pips39Core

/// Der Nutzer tippt seine notierten Wörter zurück, die App bestätigt Position
/// für Position.
struct TranscriptionView: View {

    @ObservedObject var check: TranscriptionCheck
    let onFinished: () -> Void
    let onShowWordsAgain: () -> Void

    @State private var entry = WordEntry()

    var body: some View {
        VStack(spacing: 16) {
            TopBar()

            header

            if check.isComplete {
                success
            } else {
                Spacer(minLength: 0)
                positionGrid
                Spacer(minLength: 0)
                candidates
                WordKeyboardView(
                    allowed: entry.allowedNextLetters,
                    canDelete: !entry.isEmpty,
                    // Der erste Buchstabe räumt die Fehlmeldung weg. Sonst stünde
                    // sie über einer neuen Eingabe und nennte ein Wort, das gar
                    // nicht mehr auf dem Schirm steht.
                    onLetter: { check.clearMismatch(); entry.append($0) },
                    onDelete: { entry.deleteLast() }
                )
            }
        }
        .padding()
        .screenProtected()
    }

    /// Füllt den Raum zwischen Kandidaten und Tastatur mit dem Fortschritt.
    ///
    /// Bewusst nur **Positionen**, keine bereits bestätigten Wörter. Der Nutzer hat
    /// sie zwar eben gesehen, aber je weniger Seed-Material und je kürzer es auf dem
    /// Schirm steht, desto besser — und für den Zweck der Kontrolle trägt die Position
    /// genauso viel.
    ///
    /// Die Tastatur bleibt unten, wo der Daumen sie erwartet.
    private var positionGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                  spacing: 8) {
            ForEach(0..<check.total, id: \.self) { index in
                marker(for: index)
            }
        }
    }

    private func marker(for index: Int) -> some View {
        let done = index < check.position
        let current = index == check.position
        return Text("\(index + 1)")
            .font(.footnote.monospacedDigit())
            .foregroundStyle(done || current ? Color.primary : Brand.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(done ? Color.accentColor.opacity(0.2)
                             : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.accentColor, lineWidth: current ? 2 : 0)
            )
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(check.isComplete ? "All \(check.total) match"
                                  : "Word \(check.position + 1) of \(check.total)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()

            Text(entry.prefix.uppercased())
                .font(.system(.title, design: .monospaced))
                .frame(minHeight: 34)

            if let typed = check.mismatch {
                VStack(spacing: 6) {
                    // Fett statt rot: Der Satz steht allein zwischen zwei Knöpfen,
                    // eine Fläche wäre hier zu schwer.
                    Text("\(typed) does not match position \(check.position + 1). Check your paper.")
                        .font(.footnote.weight(.semibold))
                        .multilineTextAlignment(.center)
                    // Unterstrichen wie die Links: Der Akzent ist Weiß, ohne
                    // Unterstrich wäre der Knopf von dem Satz darüber nicht zu
                    // unterscheiden.
                    Button("Show the words again", action: onShowWordsAgain)
                        .font(.footnote)
                        .underline()
                }
            }
        }
    }

    private var candidates: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(entry.candidates, id: \.self) { word in
                    Button {
                        check.submit(word)
                        entry.reset()
                    } label: {
                        Text(word)
                            .font(.body.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: 44)
    }

    private var success: some View {
        VStack(spacing: 16) {
            // Weiß, nicht grün: Grün kommt auf dem Verlauf nur auf 4:1, Weiß auf
            // 7,3 bis 8,4. Das Siegel sagt ohnehin von sich aus, dass etwas stimmt.
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
            Text("Your paper matches all \(check.total) words.")
                .multilineTextAlignment(.center)
            Button("Done") { onFinished() }
                .buttonStyle(.brandProminent)
            Spacer()
        }
    }
}

private func previewCheck() -> TranscriptionCheck {
    TranscriptionCheck(expected: Array(repeating: "abandon", count: 23) + ["art"])
}

#Preview {
    TranscriptionView(check: previewCheck(), onFinished: { }, onShowWordsAgain: { })
}
