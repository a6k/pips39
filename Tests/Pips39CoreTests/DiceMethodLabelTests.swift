import XCTest
@testable import Pips39Core

final class DiceMethodLabelTests: XCTestCase {

    /// Regeln werden gegen die englische Fassung geprueft, unabhaengig von der
    /// Systemsprache der Testmaschine.
    private let en = Locale(identifier: "en")

    func testEveryMethodHasANonEmptyLabel() {
        for method in DiceMethod.allCases {
            XCTAssertFalse(method.title.isEmpty, "Titel fehlt für \(method)")
            XCTAssertFalse(method.summary(locale: en).isEmpty, "Kurzbeschreibung fehlt für \(method)")
            XCTAssertFalse(method.rollCountHint(for: .standard, locale: en).isEmpty,
                           "Wurfzahl-Hinweis fehlt für \(method)")
        }
    }

    func testTitlesAreDistinct() {
        let titles = Set(DiceMethod.allCases.map(\.title))
        XCTAssertEqual(titles.count, DiceMethod.allCases.count)
    }

    func testHashedIsTheDefault() {
        XCTAssertEqual(DiceMethod.standard, .sha256)
    }

    /// Verfahren B nennt eine feste Wurfzahl, Verfahren A darf das nicht.
    func testOnlyHashedPromisesAFixedRollCount() {
        XCTAssertTrue(DiceMethod.sha256.rollCountHint(for: .twentyFour, locale: en).contains("99"))
        XCTAssertFalse(DiceMethod.coleman.rollCountHint(for: .twentyFour, locale: en).contains("99"))
    }
}
