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
            header

            if check.isComplete {
                success
            } else {
                candidates
                Spacer(minLength: 0)
                WordKeyboardView(
                    allowed: entry.allowedNextLetters,
                    canDelete: !entry.isEmpty,
                    onLetter: { entry.append($0) },
                    onDelete: { entry.deleteLast() }
                )
            }
        }
        .padding()
        .screenProtected()
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
                    Text("\(typed) does not match position \(check.position + 1). Check your paper.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    Button("Show the words again", action: onShowWordsAgain)
                        .font(.footnote)
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
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Your paper matches all \(check.total) words.")
                .multilineTextAlignment(.center)
            Button("Done") { onFinished() }
                .buttonStyle(.borderedProminent)
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
