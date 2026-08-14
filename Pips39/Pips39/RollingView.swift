import SwiftUI
import Pips39Core

/// Die Würfeleingabe: sechs große Flächen, Rückgängig, Fortschritt.
struct RollingView: View {

    @ObservedObject var session: DiceSession
    let onFinished: () -> Void
    let onBack: () -> Void

    @State private var showsDiscardConfirmation = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 20) {
            backBar
            header

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...6, id: \.self) { face in
                    Button {
                        session.roll(UInt8(face))
                    } label: {
                        Image(systemName: "die.face.\(face).fill")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(session.isComplete)
                }
            }

            HStack {
                Button("Undo") { session.undo() }
                    .disabled(!session.canUndo)
                Spacer()
                Button("Show words") {
                    session.reveal()
                    onFinished()
                }
                .font(.body.weight(.semibold))
                .disabled(!session.isComplete)
            }

            patternNotice

            Spacer()
        }
        .padding()
        .animation(.default, value: session.livePattern)
    }

    /// Ab dem zwanzigsten Wurf, solange die Folge auffällig ist. Steht hier statt
    /// erst bei den Wörtern, weil Korrigieren jetzt noch billig ist — dreißig weitere
    /// Würfe zu tippen und danach zu verwerfen wäre umsonst.
    ///
    /// Dieselbe orange Feststellung wie in der Wortanzeige: nichts ist kaputt, wer
    /// tatsächlich so gewürfelt hat, würfelt weiter.
    @ViewBuilder
    private var patternNotice: some View {
        if let finding = session.livePattern {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(RollPattern.notice(for: finding, advice: .whileRolling))
                    .font(.footnote.weight(.medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.orange)
            .padding(12)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .transition(.opacity)
        }
    }

    /// Zurück zur Verfahrenswahl.
    ///
    /// Nachfragen nur, wenn tatsächlich etwas verloren geht. Ein Dialog auf einem
    /// leeren Puffer wäre reine Reiberei — er würde dazu erziehen, Rückfragen
    /// wegzutippen, und dann trifft es irgendwann die Rückfrage, die zählt.
    private var backBar: some View {
        TopBar {
            Button {
                if session.rollCount > 0 {
                    showsDiscardConfirmation = true
                } else {
                    onBack()
                }
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.body)
            }
        }
        .confirmationDialog(
            "Discard \(session.rollCount) rolls?",
            isPresented: $showsDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard and go back", role: .destructive, action: onBack)
            Button("Keep rolling", role: .cancel) { }
        } message: {
            Text("Going back means choosing the seed length again. Your rolls so far cannot be carried over.")
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            // Verfahren und Wortzahl stehen zusammen, weil beide zum Ergebnis gehören
            // und man sonst mitten im Würfeln nicht mehr weiß, worauf man zuläuft.
            // Zusammengesetzt statt als Formatstring: Beide Teile sind bereits
            // übersetzt, ein eigener Schlüssel dafür wäre eine Fehlerquelle mehr.
            Text(session.method.title + " " + session.length.title())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(progressText)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            ProgressView(value: fraction)
        }
    }

    private var progressText: String {
        switch session.progress {
        case let .rolls(done, needed):
            return String(format: NSLocalizedString("%lld of %lld rolls", comment: ""),
                          done, needed)
        case let .bits(done, needed):
            return String(format: NSLocalizedString("%lld of %lld bits", comment: ""),
                          min(done, needed), needed)
        }
    }

    private var fraction: Double {
        switch session.progress {
        case let .rolls(done, needed), let .bits(done, needed):
            return needed == 0 ? 0 : min(Double(done) / Double(needed), 1)
        }
    }
}

#Preview {
    RollingView(session: DiceSession(method: .sha256),
                onFinished: { }, onBack: { })
}
