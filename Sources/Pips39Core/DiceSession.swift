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
    public let length: SeedLength

    @Published private var buffer: DiceEntropy
    @Published public private(set) var words: [String] = []

    public init(method: DiceMethod, length: SeedLength = .standard) {
        self.method = method
        self.length = length
        self.buffer = DiceEntropy(method: method, length: length)
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

    /// Eine Feststellung zur Wurffolge, oder `nil` wenn nichts auffällt.
    ///
    /// Bewusst erst nach Abschluss: Während des Würfelns wären fünf gleiche Würfe
    /// hintereinander noch völlig gewöhnlich, und eine Meldung dazu wäre genau der
    /// Fehlalarm, den `RollPattern` vermeidet.
    public var rollPattern: RollPattern.Finding? {
        guard isComplete else { return nil }
        return RollPattern.finding(for: buffer.rolls)
    }

    /// Berechnet die Wörter, sobald genug gewürfelt wurde. Vorher wirkungslos.
    public func reveal() {
        guard var entropy = buffer.entropy() else { return }
        defer { entropy.wipe() }
        words = (try? BIP39.mnemonic(from: entropy.bytes)) ?? []
    }

    /// Wirft alles weg und beginnt von vorn — gleiches Verfahren, leerer Puffer.
    public func discard() {
        words = []
        buffer = DiceEntropy(method: method, length: length)
    }

    /// Die erzeugte Entropie als Hex, oder `nil` solange nicht genug gewürfelt wurde.
    ///
    /// Seed-gleichwertig. Wird nur im Nachrechnen-Bereich gezeigt, zusammen mit dem
    /// Hinweis, dafür eine Wegwerf-Folge zu benutzen.
    public var entropyHex: String? {
        guard var entropy = buffer.entropy() else { return nil }
        defer { entropy.wipe() }
        return entropy.bytes.map { String(format: "%02x", $0) }.joined()
    }
}
