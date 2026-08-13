import XCTest
@testable import Pips39Core

final class DiceMethodLabelTests: XCTestCase {

    func testEveryMethodHasANonEmptyLabel() {
        for method in DiceMethod.allCases {
            XCTAssertFalse(method.title.isEmpty, "Titel fehlt für \(method)")
            XCTAssertFalse(method.summary.isEmpty, "Kurzbeschreibung fehlt für \(method)")
            XCTAssertFalse(method.rollCountHint.isEmpty, "Wurfzahl-Hinweis fehlt für \(method)")
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
        XCTAssertTrue(DiceMethod.sha256.rollCountHint.contains("99"))
        XCTAssertFalse(DiceMethod.coleman.rollCountHint.contains("99"))
    }
}
