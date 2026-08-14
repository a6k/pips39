import SwiftUI
import Pips39Core

/// Der Ablauf: Erklärseite → Verfahren wählen → würfeln → Wörter →
/// Abschreibkontrolle → verwerfen. Der Nachrechnen-Bereich hängt an der Wortanzeige.
struct ContentView: View {

    private enum Step {
        case rolling
        case words
        case verifying
        case checking(TranscriptionCheck)
    }

    @StateObject private var probe = EnvironmentProbe()
    @State private var hasStarted = false
    @State private var showsLookupTable = false
    @State private var session: DiceSession?
    @State private var step: Step = .rolling

    var body: some View {
        if !hasStarted {
            OnboardingView(probe: probe) { hasStarted = true }
        } else if showsLookupTable {
            // Steht vor der Sitzungsprüfung, weil dieser Modus keine Sitzung hat und
            // keinen Seed erzeugt — er ist ein Ausdruck, kein Ablauf.
            LookupView { showsLookupTable = false }
        } else if let session {
            switch step {
            case .rolling:
                RollingView(session: session) {
                    step = .words
                } onBack: {
                    startOver()
                } onHelp: {
                    hasStarted = false
                }
            case .words:
                WordsView(session: session) {
                    startOver()
                } onCheck: {
                    step = .checking(TranscriptionCheck(expected: session.words))
                } onVerify: {
                    step = .verifying
                }
            case .verifying:
                VerifyView(session: session) {
                    step = .words
                }
            case let .checking(check):
                TranscriptionView(check: check) {
                    startOver()
                } onShowWordsAgain: {
                    step = .words
                }
            }
        } else {
            VStack(spacing: 12) {
                EnvironmentNotice(probe: probe)
                MethodChoiceView { method, length in
                    session = DiceSession(method: method, length: length)
                    step = .rolling
                } onChooseLookupTable: {
                    showsLookupTable = true
                }
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
