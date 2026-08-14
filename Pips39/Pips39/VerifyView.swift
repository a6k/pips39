import SwiftUI
import Pips39Core

/// Zeigt Wurffolge und Hex-Entropie, damit der Nutzer das Ergebnis unabhängig
/// nachrechnen kann — und warnt davor, das mit dem echten Seed zu tun.
struct VerifyView: View {

    @ObservedObject var session: DiceSession
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Check this yourself")
                    .font(.title2.bold())

                warning

                field(title: "Method", value: session.method.title, monospaced: false)
                field(title: "Dice rolls", value: session.rollSequence, monospaced: true)
                field(title: "Entropy (hex)", value: session.entropyHex ?? "—", monospaced: true)

                VStack(alignment: .leading, spacing: 10) {
                    Text("How to verify")
                        .font(.headline)
                    ForEach(Array(session.method.verificationSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(step).font(.footnote)
                        }
                    }
                }

                Button("Back", action: onBack)
                    .buttonStyle(.bordered)
                    .padding(.top)
            }
            .padding()
        }
        .screenProtected()
    }

    private var warning: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(session.method.verificationWarning)
                .font(.footnote.weight(.medium))
        }
        .foregroundStyle(.red)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func field(title: String, value: String, monospaced: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(monospaced ? .system(.footnote, design: .monospaced) : .footnote)
                .textSelection(.enabled)
        }
    }
}

private func verifyPreviewSession() -> DiceSession {
    let session = DiceSession(method: .sha256)
    for _ in 0..<99 { session.roll(1) }
    session.reveal()
    return session
}

#Preview {
    VerifyView(session: verifyPreviewSession()) { }
}
