import SwiftUI
import Pips39Core

/// Die 24 Wörter, nummeriert, mit dem benutzten Verfahren daneben.
struct WordsView: View {

    @ObservedObject var session: DiceSession
    let onDiscard: () -> Void
    let onCheck: () -> Void
    let onVerify: () -> Void

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

                // Oben, damit es gelesen wird, *bevor* jemand abschreibt. Orange und
                // nicht rot: die Wörter sind gültig, wer tatsächlich so gewürfelt hat,
                // darf sie behalten. Die App stellt fest und blockiert nicht.
                if let finding = session.rollPattern {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(RollPattern.notice(for: finding))
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

                VStack(spacing: 10) {
                    Button {
                        onCheck()
                    } label: {
                        Text("I wrote them down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Show rolls and entropy", action: onVerify)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

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
        .hiddenFromScreenCapture()
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
