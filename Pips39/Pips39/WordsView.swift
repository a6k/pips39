import SwiftUI
import Pips39Core

/// Die 24 Wörter, nummeriert, mit dem benutzten Verfahren daneben.
struct WordsView: View {

    @ObservedObject var session: DiceSession
    let onDiscard: () -> Void
    let onCheck: () -> Void
    let onVerify: () -> Void

    @State private var showsDiscardConfirmation = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                discardBar

                VStack(alignment: .leading, spacing: 4) {
                    Text("Write these down")
                        .font(.title2.bold())
                    Text("Method: \(session.method.title). Note this down too. The same rolls give different words under the other method.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Oben, damit es gelesen wird, *bevor* jemand abschreibt. Orange und
                // nicht rot: die Wörter sind gültig, wer tatsächlich so gewürfelt hat,
                // darf sie behalten. Die App stellt fest und blockiert nicht.
                if let finding = session.rollPattern {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(RollPattern.notice(for: finding, advice: .atResult))
                            .font(.footnote.weight(.medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(.orange)
                    .padding(12)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(Array(session.words.enumerated()), id: \.offset) { index, word in
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)
                            Text(word)
                                .font(.body.weight(.medium))
                            Spacer(minLength: 0)
                        }
                    }
                }

                // Steht bei den Wörtern, auf die es sich bezieht, und nicht in der
                // Fußleiste — dort bliebe nur der eine Schritt nach vorn.
                Button("Show rolls and entropy", action: onVerify)
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) { footer }
        .screenProtected()
        .hiddenFromScreenCapture()
    }

    /// Der Weg hinaus, der nichts abschließt — deshalb oben rechts und rot, getrennt
    /// von der Fußleiste, in der nur die Schritte nach vorn stehen.
    ///
    /// Hier wird **immer** nachgefragt, anders als beim Zurück in der Würfelansicht:
    /// dort kann der Puffer leer sein, hier stehen die Wörter bereits auf dem Schirm
    /// und es gibt keinen Weg, sie wiederzubekommen.
    private var discardBar: some View {
        TopBar {
            Button("Discard", role: .destructive) {
                showsDiscardConfirmation = true
            }
            .font(.body)
        }
        .confirmationDialog(
            "Discard these words?",
            isPresented: $showsDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard and start over", role: .destructive, action: onDiscard)
            Button("Keep them", role: .cancel) { }
        } message: {
            Text("Nothing is stored. If you have not written them down, these words are gone.")
        }
    }

    /// Bleibt stehen, während die Wörter darunter durchlaufen — der nächste Schritt
    /// ist immer erreichbar, ohne ans Listenende zu scrollen.
    ///
    /// Bewusst **kein** `.bar`-Material wie im Onboarding: dort grenzt die Leiste an
    /// den Seitenindikator und hat etwas abzugrenzen. Hier endet der Inhalt meist weit
    /// darüber, und das Material wird zum grauen Streifen zwischen zwei weißen Flächen.
    /// Deckende Seitenfarbe verdeckt durchlaufende Wörter genauso, ohne sichtbare Naht.
    private var footer: some View {
        Button(action: onCheck) {
            Text("I wrote them down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.top, 12)
        .background(Color(.systemBackground))
    }
}

/// Eigene Funktion, damit die Vorschau ein einzelner Ausdruck bleibt —
/// `#Preview` verträgt keine mehrzeilige Anweisungsfolge.
private func previewSession() -> DiceSession {
    let session = DiceSession(method: .sha256)
    for _ in 0..<99 { session.roll(1) }
    session.reveal()
    return session
}

#Preview {
    WordsView(session: previewSession(), onDiscard: { }, onCheck: { }, onVerify: { })
}
