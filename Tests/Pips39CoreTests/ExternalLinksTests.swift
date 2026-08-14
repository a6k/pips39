import XCTest
@testable import Pips39Core

final class ExternalLinksTests: XCTestCase {

    private var all: [String] {
        [ExternalLinks.colemanTool, ExternalLinks.sourceCode, ExternalLinks.bitboxGuide]
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

    /// Die Adresse des stärkeren Verfahrens. Steht auf der ersten Onboarding-Seite,
    /// also an der Stelle mit der größten Reichweite — ein Tippfehler dort schickt
    /// Leute ins Leere, statt zu dem Weg, der ohne diese App auskommt.
    func testBitboxGuidePointsAtBitbox() {
        XCTAssertTrue(ExternalLinks.bitboxGuide.contains("bitbox.swiss"),
                      ExternalLinks.bitboxGuide)
    }

    func testLinksAreDistinct() {
        XCTAssertEqual(Set(all).count, all.count)
    }
}
