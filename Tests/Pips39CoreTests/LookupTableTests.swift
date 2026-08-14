import XCTest
@testable import Pips39Core

final class LookupTableTests: XCTestCase {

    // MARK: Die Formel gegen die offizielle Wortliste

    /// Die acht Seitengrenzen der BitBox-Tabelle. Stimmen die, stimmt die Formel —
    /// sie sind die Ecken des Wertebereichs jeder der drei eingegebenen Stellen.
    func testPageBoundariesMatchTheOfficialList() {
        let expected: [(Int, String)] = [
            (0, "abandon"), (511, "divide"),
            (512, "divorce"), (1023, "lend"),
            (1024, "length"), (1535, "say"),
            (1536, "scale"), (2047, "zoo")
        ]
        for (index, word) in expected {
            XCTAssertEqual(WordList.english[index], word)
        }
    }

    func testIndexOfTheFirstEntry() {
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 1,
                                         fourth: 1, fifth: 1, coin: .heads), 0)
    }

    func testIndexOfTheLastEntry() {
        XCTAssertEqual(LookupTable.index(page: 4, second: 4, third: 4,
                                         fourth: 4, fifth: 4, coin: .tails), 2047)
    }

    /// Die Münze ist das niederwertigste Bit, der erste Würfel das höchstwertige.
    func testPlaceValues() {
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 1,
                                         fourth: 1, fifth: 1, coin: .tails), 1)
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 1,
                                         fourth: 1, fifth: 2, coin: .heads), 2)
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 1,
                                         fourth: 2, fifth: 1, coin: .heads), 8)
        XCTAssertEqual(LookupTable.index(page: 1, second: 1, third: 2,
                                         fourth: 1, fifth: 1, coin: .heads), 32)
        XCTAssertEqual(LookupTable.index(page: 1, second: 2, third: 1,
                                         fourth: 1, fifth: 1, coin: .heads), 128)
        XCTAssertEqual(LookupTable.index(page: 2, second: 1, third: 1,
                                         fourth: 1, fifth: 1, coin: .heads), 512)
    }

    /// Eine 5 oder 6 gibt es nicht — die wird neu geworfen, bevor etwas eingegeben wird.
    func testFacesOutsideOneToFourAreRejected() {
        XCTAssertNil(LookupTable.index(page: 5, second: 1, third: 1,
                                       fourth: 1, fifth: 1, coin: .heads))
        XCTAssertNil(LookupTable.index(page: 0, second: 1, third: 1,
                                       fourth: 1, fifth: 1, coin: .heads))
        XCTAssertNil(LookupTable.block(page: 1, second: 6, third: 1))
        XCTAssertNil(LookupTable.offsetInBlock(fourth: 5, fifth: 1, coin: .heads))
    }

    // MARK: Der Block, der auf dem Schirm landet

    func testBlockHasThirtyTwoWords() {
        XCTAssertEqual(LookupTable.block(page: 1, second: 1, third: 1)?.count, 32)
    }

    func testFirstBlockIsTheStartOfTheList() {
        XCTAssertEqual(LookupTable.block(page: 1, second: 1, third: 1),
                       Array(WordList.english.prefix(32)))
    }

    /// Die 64 Blöcke müssen die Wortliste lückenlos und überschneidungsfrei abdecken.
    /// Fehlt ein Wort, wäre es unerreichbar; käme eines doppelt vor, wäre die
    /// Verteilung schief.
    func testTheSixtyFourBlocksTileTheWholeList() {
        var seen: [String] = []
        for page in 1...4 {
            for second in 1...4 {
                for third in 1...4 {
                    guard let block = LookupTable.block(page: page, second: second,
                                                        third: third) else {
                        return XCTFail("Block fehlt: \(page)/\(second)/\(third)")
                    }
                    seen.append(contentsOf: block)
                }
            }
        }
        XCTAssertEqual(seen.count, 2048)
        XCTAssertEqual(seen, WordList.english)
    }

    /// Jede Zelle des Rasters muss genau dem Index entsprechen, den die Formel für
    /// dieselben Würfe liefert — sonst liest der Nutzer das falsche Wort ab.
    func testGridPositionMatchesTheFormula() throws {
        let block = try XCTUnwrap(LookupTable.block(page: 3, second: 2, third: 4))
        for fourth in 1...4 {
            for fifth in 1...4 {
                for coin in LookupTable.Coin.allCases {
                    let offset = try XCTUnwrap(
                        LookupTable.offsetInBlock(fourth: fourth, fifth: fifth, coin: coin))
                    let index = try XCTUnwrap(
                        LookupTable.index(page: 3, second: 2, third: 4,
                                          fourth: fourth, fifth: fifth, coin: coin))
                    XCTAssertEqual(block[offset], WordList.english[index])
                }
            }
        }
    }

    // MARK: Die Bit-Bilanz

    /// 23 gewürfelte Wörter mit je 5 ungelesenen Bit, dazu die 3 freien Bit im
    /// 24. Wort. Diese Zahl steht in der App und trägt die Entscheidung, dass es
    /// den Modus nur für 24 Wörter gibt.
    func testHiddenBitsForTwentyFourWords() {
        XCTAssertEqual(LookupTable.hiddenBits(for: .twentyFour), 118)
    }

    /// Die Grenze, an der die Entscheidung hängt, ist **112 bit** — NIST SP 800-57
    /// nennt das die kleinste Stärke, die über 2030 hinaus tragen soll.
    ///
    /// Bewusst nicht 128: 118 liegt darunter, und die Zwölf-Wort-Variante wird nicht
    /// deshalb verworfen, weil sie eine runde Zahl verfehlt, sondern weil 62 bit
    /// tatsächlich in Reichweite sind.
    func testTwelveWordsFallBelowTheThresholdAndTwentyFourDoesNot() {
        XCTAssertEqual(LookupTable.hiddenBits(for: .twelve), 62)
        XCTAssertLessThan(LookupTable.hiddenBits(for: .twelve),
                          LookupTable.minimumHiddenBits)
        XCTAssertGreaterThan(LookupTable.hiddenBits(for: .twentyFour),
                             LookupTable.minimumHiddenBits)
    }

    /// Und die unbequeme Hälfte derselben Zahl, damit sie niemand später zu 128
    /// aufrundet: Gegenüber dem Ausdruck kostet dieser Modus Sicherheit.
    func testTheModeCostsSecurityComparedToPaper() {
        XCTAssertLessThan(LookupTable.hiddenBits(for: .twentyFour), 128)
        XCTAssertEqual(SeedLength.twentyFour.entropyBits, 256)
    }

    func testRolledWordCount() {
        XCTAssertEqual(LookupTable.rolledWords(for: .twentyFour), 23)
        XCTAssertEqual(LookupTable.rolledWords(for: .twelve), 11)
    }
}
