import SwiftUI
import Pips39Core

/// Die 24 Wörter, nummeriert, mit dem benutzten Verfahren daneben.
struct WordsView: View {

    @ObservedObject var session: DiceSession
    let onDiscard: () -> Void
    let onCheck: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Write these down")
                        .font(.title2.bold())
                    Text("Method: \(session.method.title) — note this down too. The same rolls give different words under the other method.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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

                VStack(spacing: 10) {
                    Button {
                        onCheck()
                    } label: {
                        Text("I wrote them down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        onDiscard()
                    } label: {
                        Text("Discard and start over")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top)
            }
            .padding()
        }
        .screenProtected()
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
    WordsView(session: previewSession(), onDiscard: { }, onCheck: { })
}
