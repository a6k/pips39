import SwiftUI
import Pips39Core

/// Eine Tastatur, die nur Buchstaben anbietet, die zu einem BIP39-Wort führen.
///
/// Ersetzt die iOS-Systemtastatur, weil die getippte Wörter lernt, Autokorrektur und
/// Diktat mitbringt und durch Dritt-Tastaturen austauschbar ist (Spec 2.3).
struct WordKeyboardView: View {

    let allowed: Set<Character>
    let canDelete: Bool
    let onLetter: (Character) -> Void
    let onDelete: () -> Void

    /// `x` beginnt kein BIP39-Wort und taucht deshalb gar nicht erst auf.
    private let rows: [[Character]] = [
        Array("qwertyuiop"),
        Array("asdfghjkl"),
        Array("zcvbnm")
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 5) {
                    ForEach(rows[index], id: \.self) { letter in
                        key(letter)
                    }
                    if index == rows.count - 1 {
                        deleteKey
                    }
                }
            }
        }
    }

    private func key(_ letter: Character) -> some View {
        let enabled = allowed.contains(letter)
        return Button {
            onLetter(letter)
        } label: {
            Text(String(letter).uppercased())
                .font(.title3.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white.opacity(enabled ? 0.18 : 0.05))
                .foregroundStyle(enabled ? Color.primary : Color.white.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var deleteKey: some View {
        Button(action: onDelete) {
            Image(systemName: "delete.left")
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white.opacity(canDelete ? 0.18 : 0.05))
                .foregroundStyle(canDelete ? Color.primary : Color.white.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(!canDelete)
    }
}

#Preview {
    WordKeyboardView(allowed: Set("abcdefg"), canDelete: true, onLetter: { _ in }, onDelete: { })
        .padding()
}
