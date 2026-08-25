import XCTest
@testable import Pips39Core

/// Coleman **durch den ganzen Ablauf**, mit gemischten Würfen.
///
/// `ColemanEncodingTests` und `ColemanRoundTripTests` prüfen die Rechnung direkt, an
/// jedem Vektor. Was dort nicht geprüft wird, ist die Schicht darüber: Wann hält
/// `DiceEntropy` an, welche Würfe nimmt es überhaupt noch entgegen, und kommt aus
/// `DiceSession` dasselbe heraus wie aus der reinen Rechnung.
///
/// Die bisherigen Tests dieser Schicht würfeln durchgehend **eine** Augenzahl. Damit
/// liefert jeder Wurf gleich viele Bits, und ein Fehler beim Zählen fiele nicht auf:
/// Ob 128 Würfe zu je zwei Bit oder eine Bitzählung gemeint war, sieht man an einer
/// einzigen Augenzahl nicht. Erst eine Folge, in der Ein- und Zwei-Bit-Würfe
/// unregelmäßig wechseln, trennt die beiden Lesarten.
final class ColemanThroughSessionTests: XCTestCase {

    /// Die zwei gemischten Vektoren: genau 256 Bit und der Überschussfall mit 257.
    private func mixedVectors() throws -> [ColemanVectors.Vector] {
        try ColemanVectors.load().filter { $0.name.hasPrefix("Gemischte Folge") }
    }

    func testBothMixedVectorsArePresent() throws {
        XCTAssertEqual(try mixedVectors().count, 2)
    }

    // MARK: DiceEntropy

    /// Der Puffer hält genau beim Vektor an: einen Wurf vorher noch nicht fertig.
    func testBufferCompletesExactlyAtTheVectorLength() throws {
        for vector in try mixedVectors() {
            var buffer = DiceEntropy(method: .coleman)
            let digits = vector.rollDigits

            for digit in digits.dropLast() {
                try buffer.append(digit)
            }
            XCTAssertFalse(buffer.isComplete,
                           "Zu früh fertig bei: \(vector.name)")

            try buffer.append(digits[digits.count - 1])
            XCTAssertTrue(buffer.isComplete, "Nicht fertig bei: \(vector.name)")
            XCTAssertEqual(buffer.rolls.count, digits.count)
            XCTAssertEqual(buffer.rawBitCount, vector.rohBits,
                           "Rohbits weichen ab bei: \(vector.name)")
        }
    }

    /// Nach dem letzten Wurf nimmt der Puffer nichts mehr an. Das ist keine
    /// Bequemlichkeit: Ein Wurf mehr würde bei Coleman anders gekürzt und damit
    /// stillschweigend andere Wörter ergeben.
    func testBufferRefusesFurtherRolls() throws {
        for vector in try mixedVectors() {
            var buffer = DiceEntropy(method: .coleman)
            for digit in vector.rollDigits { try buffer.append(digit) }

            XCTAssertThrowsError(try buffer.append(3)) { error in
                XCTAssertEqual(error as? DiceError, .alreadyComplete)
            }
            XCTAssertEqual(buffer.rolls.count, vector.rollDigits.count)
        }
    }

    /// Der Fortschritt zählt Bits, nicht Würfe — und bei gemischten Würfen wächst er
    /// deshalb ungleichmäßig.
    func testProgressCountsBitsAndGrowsUnevenly() throws {
        let vector = try XCTUnwrap(try mixedVectors().first)
        var buffer = DiceEntropy(method: .coleman)
        var steps: [Int] = []

        for digit in vector.rollDigits {
            let before = buffer.rawBitCount
            try buffer.append(digit)
            steps.append(buffer.rawBitCount - before)

            guard case .bits(let done, let needed) = buffer.progress else {
                return XCTFail("Verfahren A meldet keinen Bit-Fortschritt")
            }
            XCTAssertEqual(done, buffer.rawBitCount)
            XCTAssertEqual(needed, 256)
        }

        XCTAssertTrue(steps.contains(1), "Kein Ein-Bit-Wurf in der Folge")
        XCTAssertTrue(steps.contains(2), "Kein Zwei-Bit-Wurf in der Folge")
        XCTAssertEqual(steps.reduce(0, +), vector.rohBits)
    }

    /// Der Überschussfall: 257 Rohbits, 32 Byte Entropie. Das erste Bit fällt weg.
    func testOvershootDropsTheLeadingBit() throws {
        let vector = try XCTUnwrap(
            try mixedVectors().first { $0.rohBits == 257 },
            "Der Vektor mit Überschuss fehlt"
        )
        var buffer = DiceEntropy(method: .coleman)
        for digit in vector.rollDigits { try buffer.append(digit) }

        let entropy = try XCTUnwrap(buffer.entropy())
        XCTAssertEqual(entropy.bytes.count, 32)
        XCTAssertEqual(hexString(entropy.bytes), vector.entropieHex)

        // Dieselben Bits ohne das erste, von Hand nachgerechnet.
        let kept = vector.rohBinaer.dropFirst()
        XCTAssertEqual(kept.count, 256)
        XCTAssertEqual(hexString(bytes(fromBitString: String(kept))), vector.entropieHex)
    }

    // MARK: DiceSession

    /// Der ganze Weg: Würfe in die Sitzung, Wörter heraus, gegen Colemans Ausgabe.
    func testSessionProducesColemansWords() throws {
        for vector in try mixedVectors() {
            let session = DiceSession(method: .coleman)
            for digit in vector.rollDigits { session.roll(digit) }

            XCTAssertTrue(session.isComplete, "Nicht fertig bei: \(vector.name)")
            XCTAssertEqual(session.rollCount, vector.rollDigits.count)
            XCTAssertEqual(session.rollSequence, vector.wuerfe)
            XCTAssertEqual(session.entropyHex, vector.entropieHex,
                           "Entropie weicht ab bei: \(vector.name)")

            session.reveal()
            XCTAssertEqual(session.words.count, 24)
            XCTAssertEqual(session.words.joined(separator: " "), vector.mnemonic,
                           "Wörter weichen ab bei: \(vector.name)")
        }
    }

    /// Ein zurückgenommener Wurf macht die Sitzung wieder unfertig — bei gemischten
    /// Würfen um ein *oder* zwei Bit, je nachdem, welche Augenzahl zurückgeht.
    func testUndoReopensTheSession() throws {
        for vector in try mixedVectors() {
            let session = DiceSession(method: .coleman)
            for digit in vector.rollDigits { session.roll(digit) }

            session.undo()
            XCTAssertFalse(session.isComplete, "Nach Rücknahme noch fertig: \(vector.name)")
            XCTAssertNil(session.entropyHex)

            session.roll(vector.rollDigits[vector.rollDigits.count - 1])
            XCTAssertTrue(session.isComplete)
            XCTAssertEqual(session.entropyHex, vector.entropieHex)
        }
    }

    // MARK: Hilfsmittel

    private func hexString(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func bytes(fromBitString bits: String) -> [UInt8] {
        stride(from: 0, to: bits.count, by: 8).map { offset in
            let start = bits.index(bits.startIndex, offsetBy: offset)
            let end = bits.index(start, offsetBy: 8)
            return UInt8(bits[start..<end], radix: 2) ?? 0
        }
    }
}
