import XCTest
@testable import Pips39Core

/// Fehlalarme auf dem **Live-Pfad**, also bei jedem einzelnen Wurf.
///
/// `RollPatternTests.testRandomSequencesAreNeverFlagged` prüft ganze Folgen: eine
/// Folge, eine Frage. Die Oberfläche fragt aber nach *jedem* Wurf, und damit gilt die
/// 10⁻⁹-Regel nicht mehr je Folge, sondern je Sitzung mit rund achtzig Fragen.
///
/// Rechnerisch steigt die Fehlalarmrate dadurch von etwa 10⁻⁹ auf 2,4·10⁻⁸ je
/// Sitzung, also ungefähr 1 zu 42 Millionen. Falsch ist damit nicht die App, sondern
/// die Herleitung, die nur die fertige Folge betrachtet. Dieser Test misst nach, dass
/// die tatsächliche Rate klein genug bleibt, um niemanden zu erziehen, Warnungen
/// wegzuklicken.
///
/// **Was er nicht kann:** eine Rate von 1 zu 42 Millionen belegen. Dafür bräuchte es
/// Milliarden Würfe. Er zeigt, dass sie nicht um Größenordnungen darüber liegt — was
/// genau der Fehler wäre, den ein Programmierfehler an dieser Stelle erzeugen würde.
final class LivePatternFalseAlarmTests: XCTestCase {

    /// Zweihundert vollständige Sitzungen mit je 99 Würfen, nach jedem Wurf gefragt.
    /// Das sind knapp 20 000 Fragen an `livePattern`, keine davon darf melden.
    func testNoLiveFindingDuringHonestSessions() {
        var rng = SeededGenerator(seed: 20260825)

        for round in 0..<200 {
            let session = DiceSession(method: .sha256, length: .standard)
            var sequence: [UInt8] = []

            for _ in 0..<99 {
                let face = UInt8.random(in: 1...6, using: &rng)
                session.roll(face)
                sequence.append(face)

                XCTAssertNil(session.livePattern,
                             "Fehlalarm in Sitzung \(round) nach \(sequence.count) Würfen: "
                             + sequence.map(String.init).joined())
            }
            XCTAssertTrue(session.isComplete)
        }
    }

    /// Dasselbe unter Verfahren A, wo die Wurfzahl nicht feststeht und die Sitzung
    /// irgendwann zwischen 128 und 256 Würfen endet.
    func testNoLiveFindingUnderColeman() {
        var rng = SeededGenerator(seed: 39_2026)

        for round in 0..<100 {
            let session = DiceSession(method: .coleman, length: .standard)
            var count = 0

            while !session.isComplete {
                session.roll(UInt8.random(in: 1...6, using: &rng))
                count += 1
                XCTAssertNil(session.livePattern,
                             "Fehlalarm in Coleman-Sitzung \(round) nach \(count) Würfen")
            }
            XCTAssertGreaterThanOrEqual(count, 128)
        }
    }

    /// Die Gegenprobe: Der Live-Pfad **schweigt nicht immer**. Ohne sie könnte der
    /// Test oben auch dann grün sein, wenn `livePattern` gar nichts prüft.
    func testTheLivePathStillReportsRealPatterns() {
        let session = DiceSession(method: .sha256, length: .standard)
        for _ in 0..<22 { session.roll(5) }
        XCTAssertEqual(session.livePattern, .singleFace)
    }
}
