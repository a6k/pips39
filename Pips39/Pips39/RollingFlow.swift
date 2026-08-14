import SwiftUI
import Pips39Core

/// Ein Würfel-Reiter: Startseite, würfeln, Wörter, Aufzeichnung, Abschreibkontrolle.
///
/// Das Verfahren steht fest und kommt von außen. Jeder Reiter hat seine eigene Instanz
/// und damit seinen eigenen `@State`. SwiftUI hält die Ansichten einer `TabView` über
/// den Wechsel hinweg am Leben, deshalb steht ein angefangener Durchlauf beim
/// Zurückkommen unverändert da.
///
/// Genau das ist der Zweck: Die App ist zum Ausprobieren da. Ein Wechsel, der 60 Würfe
/// wegwirft, hält niemanden zum Ausprobieren an.
struct RollingFlow: View {

    let method: DiceMethod
    @ObservedObject var probe: EnvironmentProbe

    private enum Step {
        case rolling
        case words
        case verifying
        case checking(TranscriptionCheck)
    }

    @State private var length: SeedLength = .standard
    @State private var session: DiceSession?
    @State private var step: Step = .rolling

    var body: some View {
        if let session {
            switch step {
            case .rolling:
                RollingView(session: session) {
                    step = .words
                } onBack: {
                    startOver()
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
            startPage
        }
    }

    // MARK: Die Startseite des Reiters

    private var startPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TopBar()

                EnvironmentNotice(probe: probe)

                VStack(alignment: .leading, spacing: 6) {
                    Text(method.title)
                        .font(.largeTitle.bold())
                    Text(method.summary())
                        .font(.footnote)
                    Text(method.rollCountHint(for: length))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Brand.secondaryText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Seed length")
                        .font(.headline)
                    Picker("Seed length", selection: $length) {
                        ForEach(SeedLength.allCases) { option in
                            Text(option.title()).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button {
                    session = DiceSession(method: method, length: length)
                    step = .rolling
                } label: {
                    Text("Start rolling")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.brandProminent)

                Text("The method travels with the result. Write it down together with your words.")
                    .font(.caption)
                    .foregroundStyle(Brand.secondaryText)
            }
            .padding()
        }
    }

    private func startOver() {
        session?.discard()
        session = nil
        step = .rolling
    }
}

#Preview {
    RollingFlow(method: .sha256, probe: EnvironmentProbe())
}
