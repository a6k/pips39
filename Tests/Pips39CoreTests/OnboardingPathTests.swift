import XCTest
@testable import Pips39Core

final class OnboardingPathTests: XCTestCase {

    private let en = Locale(identifier: "en")
    private let de = Locale(identifier: "de")

    func testBothPathsHaveText() {
        for path in OnboardingPath.allCases {
            XCTAssertFalse(path.title(locale: en).isEmpty, "\(path)")
            XCTAssertFalse(path.summary(locale: en).isEmpty, "\(path)")
            XCTAssertFalse(path.exposure(locale: en).isEmpty, "\(path)")
        }
    }

    func testEverythingIsTranslated() {
        for path in OnboardingPath.allCases {
            XCTAssertNotEqual(path.title(locale: de), path.title(locale: en), "\(path)")
            XCTAssertNotEqual(path.summary(locale: de), path.summary(locale: en), "\(path)")
            XCTAssertNotEqual(path.exposure(locale: de), path.exposure(locale: en), "\(path)")
            XCTAssertFalse(path.summary(locale: de).contains("onboarding."), "\(path)")
            XCTAssertFalse(path.exposure(locale: de).contains("onboarding."), "\(path)")
        }
    }

    /// Die beiden Wege unterscheiden sich genau darin, was die App zu sehen bekommt.
    /// Stünde dort zweimal dasselbe, wäre die Verzweigung sinnlos.
    func testTheTwoPathsDifferInWhatTheAppSees() {
        XCTAssertNotEqual(OnboardingPath.rollAndCompute.exposure(locale: en),
                          OnboardingPath.lookupTable.exposure(locale: en))
    }

    /// Die Zahl ist die ganze Aussage des zweiten Wegs und darf nicht verlorengehen,
    /// wenn jemand den Text umformuliert. 118 kommt aus `LookupTable.hiddenBits`.
    func testTheLookupPathNamesTheNumber() {
        let text = OnboardingPath.lookupTable.exposure(locale: en)
        XCTAssertTrue(text.contains("\(LookupTable.hiddenBits(for: .twentyFour))"), text)
    }

    /// Genau ein Weg legt den Seed offen. Wäre das bei beiden so, hätte die
    /// Verzweigung keinen Zweck; wäre es bei keinem so, stimmte die Aussage nicht.
    func testExactlyOnePathExposesTheWholeSeed() {
        let offen = OnboardingPath.allCases.filter(\.appSeesEverything)
        XCTAssertEqual(offen, [.rollAndCompute])
    }

    /// Der Satz, der rot wird, muss ohne Pronomen auskommen. „Sie sieht ihn
    /// vollständig" liest sich in einem Text in Höflichkeitsform wie eine Aussage über
    /// den Leser, nicht über die App.
    func testTheCriticalSentenceNamesTheAppAndTheSeed() {
        let text = OnboardingPath.rollAndCompute.exposure(locale: de)
        XCTAssertTrue(text.hasPrefix("Die App sieht den Seed vollständig."), text)
    }

    /// Keine Entwarnung, nirgends — dieselbe Regel wie bei `EnvironmentProbe`.
    func testNoPathPromisesSafety() {
        let forbidden = ["safe", "secure", "protected", "guaranteed"]
        for path in OnboardingPath.allCases {
            let text = (path.summary(locale: en) + " " + path.exposure(locale: en)).lowercased()
            for word in forbidden {
                XCTAssertFalse(text.contains(word), "\(path) verspricht \(word): \(text)")
            }
        }
    }
}
