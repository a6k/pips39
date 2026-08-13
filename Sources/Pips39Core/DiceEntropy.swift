import Foundation

public enum DiceError: Error, Equatable {
    /// Der Wurf lag nicht zwischen 1 und 6.
    case invalidRoll(UInt8)
    /// Es wurde geworfen, obwohl bereits genug Entropie vorliegt.
    case alreadyComplete
}

/// Sammelt Würfelwürfe und macht daraus Entropie — nach dem beim Anlegen
/// gewählten Verfahren.
///
/// Speichert nichts über die Lebensdauer der Instanz hinaus. Das Verfahren wird beim
/// Anlegen festgelegt und kann nicht gewechselt werden: Ein Wechsel mitten im
/// Durchlauf würde aus derselben Wurffolge stillschweigend andere Wörter machen.
public struct DiceEntropy {

    /// Zielgröße der Entropie in Bit. 256 Bit ergeben 24 Wörter.
    public static let targetEntropyBits = 256

    /// Feste Wurfzahl für Verfahren B.
    public static let rollsForHashedMethod = 99

    public let method: DiceMethod
    public private(set) var rolls: [UInt8] = []

    public init(method: DiceMethod) {
        self.method = method
    }

    /// Nimmt einen Wurf entgegen. Wirft, wenn der Wert ungültig oder bereits genug
    /// gewürfelt ist.
    public mutating func append(_ roll: UInt8) throws {
        guard (1...6).contains(roll) else { throw DiceError.invalidRoll(roll) }
        guard !isComplete else { throw DiceError.alreadyComplete }
        rolls.append(roll)
    }

    /// Nimmt den letzten Wurf zurück. Auf einem leeren Puffer wirkungslos.
    public mutating func undo() {
        if !rolls.isEmpty {
            rolls.removeLast()
        }
    }

    /// **Vorläufig.** Task 6 ersetzt das durch die verfahrensabhängige Regel.
    /// `append` braucht die Abfrage schon jetzt, damit die Signatur später gleich
    /// bleibt.
    public var isComplete: Bool { false }
}
