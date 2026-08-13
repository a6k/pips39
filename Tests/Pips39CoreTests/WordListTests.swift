import XCTest
@testable import Pips39Core

final class WordListTests: XCTestCase {

    func testHasExactly2048Words() {
        XCTAssertEqual(WordList.english.count, 2048)
    }

    func testIsSortedAscending() {
        XCTAssertEqual(WordList.english, WordList.english.sorted())
    }

    func testHasNoDuplicates() {
        XCTAssertEqual(Set(WordList.english).count, 2048)
    }

    func testKnownBoundaryWords() {
        XCTAssertEqual(WordList.english.first, "abandon")
        XCTAssertEqual(WordList.english.last, "zoo")
    }

    func testIndexLookupIsConsistent() {
        for (index, word) in WordList.english.enumerated() {
            XCTAssertEqual(WordList.index(of: word), index, "Index für \(word) falsch")
        }
    }

    func testUnknownWordHasNoIndex() {
        XCTAssertNil(WordList.index(of: "nichtimwortschatz"))
    }
}
