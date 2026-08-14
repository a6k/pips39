import XCTest
@testable import Pips39Core

final class ExternalLinksTests: XCTestCase {

    private var all: [String] {
        [ExternalLinks.colemanTool, ExternalLinks.sourceCode]
    }

    func testAllLinksParseAsURLs() {
        for link in all {
            XCTAssertNotNil(URL(string: link), "Keine gültige Adresse: \(link)")
        }
    }

    /// Eine App, die zum Abschotten anleitet, darf nirgends auf http verweisen.
    func testEveryLinkUsesHTTPS() {
        for link in all {
            XCTAssertTrue(link.hasPrefix("https://"), "Kein https: \(link)")
        }
    }

    func testColemanToolPointsAtTheBIP39Page() {
        XCTAssertTrue(ExternalLinks.colemanTool.contains("iancoleman"))
        XCTAssertTrue(ExternalLinks.colemanTool.contains("bip39"))
    }

    func testSourcePointsAtTheRepository() {
        XCTAssertTrue(ExternalLinks.sourceCode.contains("github.com"))
        XCTAssertTrue(ExternalLinks.sourceCode.contains("pips39"))
    }

    func testLinksAreDistinct() {
        XCTAssertEqual(Set(all).count, all.count)
    }
}
