import Foundation
import Combine

/// Der Ablauf eines Würfel-Durchlaufs, wie die Oberfläche ihn sieht.
///
/// Enthält die gesamte Entscheidungslogik, damit die SwiftUI-Ansichten dumm bleiben
/// und ohne Simulator geprüft werden kann. Das Verfahren wird beim Anlegen gewählt
/// und ist danach unveränderlich — ein Wechsel mitten im Durchlauf würde aus
/// derselben Wurffolge stillschweigend andere Wörter machen.
public final class DiceSession: ObservableObject {

    public let method: DiceMethod

    @Published private var buffer: DiceEntropy
    @Published public private(set) var words: [String] = []

    public init(method: DiceMethod) {
        self.method = method
        self.buffer = DiceEntropy(method: method)
    }

    // MARK: Würfeln

    public var rollCount: Int { buffer.rolls.count }
    public var progress: DiceProgress { buffer.progress }
    public var isComplete: Bool { buffer.isComplete }
    public var canUndo: Bool { !buffer.rolls.isEmpty }

    /// Die Wurffolge als Ziffernkette — das, was der Nutzer notiert hätte.
    public var rollSequence: String {
        buffer.rolls.map(String.init).joined()
    }

    /// Nimmt einen Wurf entgegen. Ungültige Werte und Würfe nach Abschluss werden
    /// stillschweigend übergangen: Die Oberfläche sperrt die Tasten ohnehin, und ein
    /// Fehlerdialog an dieser Stelle hilft niemandem.
    public func roll(_ face: UInt8) {
        try? buffer.append(face)
    }

    /// Nimmt den letzten Wurf zurück.
    public func undo() {
        buffer.undo()
    }

    // MARK: Ergebnis

    /// Berechnet die Wörter, sobald genug gewürfelt wurde. Vorher wirkungslos.
    public func reveal() {
        guard var entropy = buffer.entropy() else { return }
        defer { entropy.wipe() }
        words = (try? BIP39.mnemonic(from: entropy.bytes)) ?? []
    }

    /// Wirft alles weg und beginnt von vorn — gleiches Verfahren, leerer Puffer.
    public func discard() {
        words = []
        buffer = DiceEntropy(method: method)
    }
}
