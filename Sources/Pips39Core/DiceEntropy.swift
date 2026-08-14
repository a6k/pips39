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

    public let method: DiceMethod
    public let length: SeedLength
    public private(set) var rolls: [UInt8] = []

    public init(method: DiceMethod, length: SeedLength = .standard) {
        self.method = method
        self.length = length
    }

    /// Zielgröße der Entropie in Bit.
    public var targetEntropyBits: Int { length.entropyBits }

    /// Feste Wurfzahl für Verfahren B.
    public var rollsForHashedMethod: Int { length.rollsForHashedMethod }

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

    /// Wie viele Rohbits die bisherigen Würfe unter Verfahren A ergeben.
    /// Unter Verfahren B ohne Bedeutung.
    public var rawBitCount: Int {
        ColemanEncoding.rawBits(for: rolls).count
    }

    /// Der Fortschritt, in der Einheit, die zum Verfahren passt.
    public var progress: DiceProgress {
        switch method {
        case .sha256:
            return .rolls(done: rolls.count, needed: rollsForHashedMethod)
        case .coleman:
            return .bits(done: rawBitCount, needed: targetEntropyBits)
        }
    }

    /// Ob genug gewürfelt wurde. Weitere Würfe werden danach abgelehnt — unter
    /// Verfahren A würden sie die Nachrechenbarkeit bei Coleman zerstören, weil er
    /// die längere Folge anders kürzt.
    public var isComplete: Bool {
        switch method {
        case .sha256:
            return rolls.count >= rollsForHashedMethod
        case .coleman:
            return rawBitCount >= targetEntropyBits
        }
    }

    /// Die fertige Entropie, oder `nil` solange nicht genug gewürfelt wurde.
    ///
    /// Immer `targetEntropyBits / 8` Byte. Unter Verfahren A werden dazu die
    /// vordersten überzähligen Rohbits verworfen, genau wie bei Coleman.
    public func entropy() -> SecretBytes? {
        guard isComplete else { return nil }
        switch method {
        case .sha256:
            return SecretBytes(HashedEncoding.entropy(from: rolls,
                                                      byteCount: targetEntropyBits / 8))
        case .coleman:
            return SecretBytes(ColemanEncoding.entropy(from: rolls))
        }
    }
}

/// Fortschritt beim Würfeln. Die Einheit hängt am Verfahren: Verfahren B hat eine
/// feste Wurfzahl, Verfahren A nicht — dort liefert jeder Wurf ein oder zwei Bit.
public enum DiceProgress: Equatable {
    /// Verfahren B: „37 von 99 Würfen".
    case rolls(done: Int, needed: Int)
    /// Verfahren A: „164 von 256 Bit". Es gibt keine verlässliche Restdauer.
    case bits(done: Int, needed: Int)
}
