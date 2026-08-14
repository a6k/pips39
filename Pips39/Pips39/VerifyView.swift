import SwiftUI
import Pips39Core

/// Eine Aufzeichnung dieses Durchlaufs: Verfahren, Wurffolge, Hex-Entropie.
///
/// **Bewusst ohne Nachrechen-Anleitung.** Die stand hier ursprünglich und war ein
/// Konstruktionsfehler: Ihre Schritte brauchen eine Shell und einen Browser mit Netz,
/// beides gibt es auf dem abgeschotteten Gerät nicht — und daneben stand ausgerechnet
/// der scharfe Seed. Der Bildschirm forderte damit genau die Handlung, die die Warnung
/// darüber verbietet. Die Anleitung sitzt jetzt auf der Erklärseite, wo sie vor dem
/// Abschotten gelesen und mit einer Wegwerf-Folge ausgeführt wird.
struct VerifyView: View {

    @ObservedObject var session: DiceSession
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your rolls and entropy")
                    .font(.title2.bold())

                warning

                field(title: "Method", value: session.method.title, monospaced: false)
                field(title: "Seed length", value: session.length.title(), monospaced: false)
                field(title: "Dice rolls", value: session.rollSequence, monospaced: true)
                field(title: "Entropy (hex)", value: session.entropyHex ?? "—", monospaced: true)

                Text("Keep these exactly as private as the words themselves, or do not keep them at all. If you write the rolls down, write the method down with them. The same rolls give different words under the other method.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Back", action: onBack)
                    .buttonStyle(.bordered)
                    .padding(.top)
            }
            .padding()
        }
        .screenProtected()
        .hiddenFromScreenCapture()
    }

    private var warning: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("These are seed-equivalent. Anyone who sees them can recreate your wallet. Never type them into another device.")
                .font(.footnote.weight(.medium))
        }
        .foregroundStyle(.red)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func field(title: LocalizedStringKey, value: String, monospaced: Bool) -> some View {
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
