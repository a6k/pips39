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

                // Oben, damit es gelesen wird, *bevor* jemand abschreibt. Eine
                // Feststellung, keine Sperre: Die Wörter sind gültig, wer tatsächlich
                // so gewürfelt hat, darf sie behalten.
                if let finding = session.rollPattern {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(RollPattern.notice(for: finding, advice: .atResult))
                            .font(.footnote.weight(.medium))
                        Spacer(minLength: 0)
                    }
                    .noticePanel()
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

    /// Der Weg hinaus, der nichts abschließt. Deshalb steht er oben und getrennt von
    /// der Fußleiste, in der nur die Schritte nach vorn stehen.
    ///
    /// Als Papierkorb statt als Wort: Systemrot ist auf dem Verlauf mit 2,15:1
    /// unlesbar, und weiße Schrift wäre von „Hilfe" rechts daneben nicht zu
    /// unterscheiden. Den Unterschied trägt hier die Form. `role: .destructive` bleibt
    /// trotzdem stehen, es bestimmt auch, wie VoiceOver den Knopf ansagt.
    ///
    /// Hier wird **immer** nachgefragt, anders als beim Zurück in der Würfelansicht:
    /// dort kann der Puffer leer sein, hier stehen die Wörter bereits auf dem Schirm
    /// und es gibt keinen Weg, sie wiederzubekommen.
    private var discardBar: some View {
        TopBar {
            Button(role: .destructive) {
                showsDiscardConfirmation = true
            } label: {
                Label("Discard", systemImage: "trash")
                    .font(.body)
            }
            .tint(.white)
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
    /// Sie muss **deckend** sein, sonst laufen die Wörter sichtbar dahinter durch.
    /// Deshalb nicht durchscheinendes Weiß wie im Onboarding, sondern der untere
    /// Verlaufston: Am unteren Rand des Schirms steht der ohnehin, die Leiste fällt
    /// dort nicht als eigene Fläche auf.
    private var footer: some View {
        Button(action: onCheck) {
            Text("I wrote them down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.brandProminent)
        .padding(.horizontal)
        .padding(.top, 12)
        // Unten ebenfalls Abstand: Vor der Reiterleiste lag hier der sichere Bereich
        // um den Home-Indikator und gab den Abstand von selbst. Jetzt sitzt dort die
        // Leiste, und der Knopf stieße ohne diese Zeile direkt dagegen.
        .padding(.bottom, 12)
        .background(Brand.gradientBottom)
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
