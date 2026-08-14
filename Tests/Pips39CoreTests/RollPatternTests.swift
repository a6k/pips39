import XCTest
@testable import Pips39Core

final class RollPatternTests: XCTestCase {

    private let en = Locale(identifier: "en")

    private func rolls(_ text: String) -> [UInt8] {
        text.compactMap { $0.wholeNumberValue.map(UInt8.init) }
    }

    // MARK: Erkannte Entartungen

    func testAllRollsIdentical() {
        XCTAssertEqual(RollPattern.finding(for: rolls(String(repeating: "4", count: 50))),
                       .singleFace)
    }

    func testRepeatingBlockOfSix() {
        let sequence = String(String(repeating: "123456", count: 20).prefix(96))
        XCTAssertEqual(RollPattern.finding(for: rolls(sequence)), .repeatingBlock(6))
    }

    func testRepeatingBlockOfTwo() {
        XCTAssertEqual(RollPattern.finding(for: rolls(String(repeating: "13", count: 30))),
                       .repeatingBlock(2))
    }

    func testOnlyTwoDistinctFaces() {
        // Zwei Augenzahlen, aber nicht periodisch — soll trotzdem auffallen.
        let sequence = "52522252222552225222252222552252225222255555552222"
        XCTAssertEqual(rolls(sequence).count, 50)
        XCTAssertEqual(RollPattern.finding(for: rolls(sequence)), .twoFacesOnly)
    }

    /// Die spezifischste Feststellung gewinnt: Eine Folge aus lauter Zweien ist
    /// auch periodisch und hat auch höchstens zwei Augenzahlen.
    func testMostSpecificFindingWins() {
        XCTAssertEqual(RollPattern.finding(for: rolls(String(repeating: "2", count: 99))),
                       .singleFace)
    }

    // MARK: Der entscheidende Test — keine Fehlalarme

    /// Zehntausend echte Zufallsfolgen dürfen **keine** Meldung erzeugen. Das ist die
    /// Behauptung, auf der die ganze Entscheidung ruht, also wird sie geprüft und
    /// nicht geglaubt. Der Generator ist bewusst deterministisch, damit ein
    /// Fehlschlag reproduzierbar ist.
    func testRandomSequencesAreNeverFlagged() {
        var rng = SeededGenerator(seed: 20260814)
        for length in [50, 99, 128, 154] {
            for _ in 0..<2500 {
                let sequence = (0..<length).map { _ in UInt8.random(in: 1...6, using: &rng) }
                XCTAssertNil(RollPattern.finding(for: sequence),
                             "Fehlalarm bei Länge \(length): \(sequence.map(String.init).joined())")
            }
        }
    }

    // MARK: Kurze Folgen

    /// Unter 20 Würfen sind die Wahrscheinlichkeiten nicht mehr vernachlässigbar.
    /// Die Prüfung schweigt dann lieber.
    func testShortSequencesAreNotJudged() {
        XCTAssertNil(RollPattern.finding(for: rolls("111111")))
        XCTAssertNil(RollPattern.finding(for: rolls("121212121212121212")))
    }

    func testEmptyInput() {
        XCTAssertNil(RollPattern.finding(for: []))
    }

    // MARK: Texte

    func testEveryFindingHasANotice() {
        let findings: [RollPattern.Finding] = [.singleFace, .repeatingBlock(3), .twoFacesOnly]
        for finding in findings {
            XCTAssertFalse(RollPattern.notice(for: finding, locale: en).isEmpty)
        }
    }

    /// Feststellung, kein Alarm — wie überall in dieser App.
    func testNoticesAreStatementsNotAlarms() {
        let findings: [RollPattern.Finding] = [.singleFace, .repeatingBlock(3), .twoFacesOnly]
        for finding in findings {
            let text = RollPattern.notice(for: finding, locale: en)
            XCTAssertFalse(text.contains("!"))
            XCTAssertFalse(text.lowercased().contains("error"))
            XCTAssertFalse(text.lowercased().contains("invalid"))
        }
    }

    func testNoticesExistInBothLanguages() {
        let de = Locale(identifier: "de")
        let findings: [RollPattern.Finding] = [.singleFace, .repeatingBlock(3), .twoFacesOnly]
        for finding in findings {
            XCTAssertNotEqual(RollPattern.notice(for: finding, locale: de),
                              RollPattern.notice(for: finding, locale: en),
                              "Nicht übersetzt: \(finding)")
            XCTAssertFalse(RollPattern.notice(for: finding, locale: de).contains("pattern."),
                           "Unübersetzter Schlüssel: \(finding)")
        }
    }
}

/// Deterministischer Generator, damit ein Fehlschlag nachstellbar ist.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    /// splitmix64 — ein reiner Zähler hätte schwache untere Bits, und genau die
    /// benutzt `random(in: 1...6)`.
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
