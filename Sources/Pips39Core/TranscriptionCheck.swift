import Foundation
import Combine

/// Prüft, ob der Nutzer die Wörter richtig abgeschrieben hat.
///
/// Geht Position für Position vor und bleibt stehen, wo es klemmt — so weiß der
/// Nutzer genau, welche Zeile auf seinem Zettel falsch ist. Nichts wird gespeichert,
/// der Vergleich passiert im Speicher.
///
/// Die Prüfung nennt **nie** das erwartete Wort, nur das abweichende Getippte. Wer
/// nachsehen will, geht bewusst zur Wortanzeige zurück.
public final class TranscriptionCheck: ObservableObject {

    private let expected: [String]

    /// Wie viele Positionen bereits stimmen.
    @Published public private(set) var position: Int = 0

    /// Das zuletzt getippte Wort, wenn es nicht passte — sonst `nil`.
    @Published public private(set) var mismatch: String?

    public init(expected: [String]) {
        self.expected = expected
    }

    public var total: Int { expected.count }
    public var isComplete: Bool { position == expected.count }

    /// Nimmt ein Wort für die aktuelle Position entgegen.
    public func submit(_ word: String) {
        guard !isComplete else { return }
        if word == expected[position] {
            mismatch = nil
            position += 1
        } else {
            mismatch = word
        }
    }

    /// Geht eine Position zurück, etwa weil der Nutzer sich vertan hat.
    public func undo() {
        mismatch = nil
        if position > 0 {
            position -= 1
        }
    }

    public func reset() {
        position = 0
        mismatch = nil
    }
}
