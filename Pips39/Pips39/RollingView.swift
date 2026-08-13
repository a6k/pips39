import SwiftUI
import Pips39Core

/// Die Würfeleingabe: sechs große Flächen, Rückgängig, Fortschritt.
struct RollingView: View {

    @ObservedObject var session: DiceSession
    let onFinished: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 20) {
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

            Spacer()
        }
        .padding()
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(session.method.title)
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
            return "\(done) of \(needed) rolls"
        case let .bits(done, needed):
            return "\(min(done, needed)) of \(needed) bits"
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
    RollingView(session: DiceSession(method: .sha256)) { }
}
