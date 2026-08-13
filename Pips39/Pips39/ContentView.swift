import SwiftUI
import Pips39Core

/// Der Ablauf: Verfahren wählen → würfeln → Wörter → verwerfen.
struct ContentView: View {

    @State private var session: DiceSession?
    @State private var showsWords = false

    var body: some View {
        if let session {
            if showsWords {
                WordsView(session: session) {
                    self.session = nil
                    showsWords = false
                }
            } else {
                RollingView(session: session) {
                    showsWords = true
                }
            }
        } else {
            MethodChoiceView { method in
                session = DiceSession(method: method)
            }
        }
    }
}

#Preview {
    ContentView()
}
