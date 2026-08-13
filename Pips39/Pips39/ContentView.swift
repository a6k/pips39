import SwiftUI
import Pips39Core

/// Der Ablauf: Verfahren wählen → würfeln → Wörter → abschreiben prüfen → verwerfen.
struct ContentView: View {

    private enum Step {
        case rolling
        case words
        case checking(TranscriptionCheck)
    }

    @State private var session: DiceSession?
    @State private var step: Step = .rolling

    var body: some View {
        if let session {
            switch step {
            case .rolling:
                RollingView(session: session) {
                    step = .words
                }
            case .words:
                WordsView(session: session) {
                    startOver()
                } onCheck: {
                    step = .checking(TranscriptionCheck(expected: session.words))
                }
            case let .checking(check):
                TranscriptionView(check: check) {
                    startOver()
                } onShowWordsAgain: {
                    step = .words
                }
            }
        } else {
            MethodChoiceView { method in
                session = DiceSession(method: method)
                step = .rolling
            }
        }
    }

    private func startOver() {
        session?.discard()
        session = nil
        step = .rolling
    }
}

#Preview {
    ContentView()
}
