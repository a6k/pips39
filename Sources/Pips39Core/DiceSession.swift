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

    /// Die Feststellung zum bisherigen Stand, unabhängig vom Fortschritt.
    ///
    /// Darf schon während des Würfelns gezeigt werden: `RollPattern` schweigt unter
    /// zwanzig Würfen von sich aus, und dort liegt das *häufigste* der erkannten
    /// Muster bereits bei etwa 10⁻⁹. Wer aus Langeweile durchtippt, erfährt es damit
    /// nach dem zwanzigsten Wurf statt nach dem fünfzigsten — solange Korrigieren
    /// noch billig ist.
    ///
    /// Eine Feststellung über den *aktuellen* Stand, kein Urteil, das stehen bleibt:
    /// Fällt eine dritte Augenzahl, verschwindet sie wieder.
    public var livePattern: RollPattern.Finding? {
        RollPattern.finding(for: buffer.rolls)
    }

    /// Dieselbe Feststellung, aber erst zum Ergebnis — für die Wortanzeige, wo sie
    /// über den Wörtern steht und sich auf die fertige Folge bezieht.
    public var rollPattern: RollPattern.Finding? {
        isComplete ? livePattern : nil
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
