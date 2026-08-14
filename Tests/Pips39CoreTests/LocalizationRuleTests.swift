import XCTest
@testable import Pips39Core

/// Die Regeln dieses Projekts gelten sprachunabhängig. Eine Übersetzung, die
/// versehentlich Sicherheit behauptet oder Colemans Bedienelemente eindeutscht,
/// muss hier durchfallen.
///
/// Die Sprache wird über `Localized` erzwungen, nicht über `locale:` allein —
/// letzteres wählt keine Sprache aus, siehe `docs/lokalisierung-mechanismus.md`.
final class LocalizationRuleTests: XCTestCase {

    private let locales = [Locale(identifier: "en"), Locale(identifier: "de")]

    /// Pro Sprache die Wörter, die eine Entwarnung bedeuten würden.
    private let forbidden: [String: [String]] = [
        "en": ["safe", "secure", "protected", "offline", "air-gap", "airgap"],
        "de": ["sicher", "geschützt", "offline", "isoliert", "getrennt", "unbedenklich"]
    ]

    // MARK: Kein grünes „sicher", in keiner Sprache

    func testNoNoticeClaimsSafetyInAnyLanguage() {
        for locale in locales {
            let words = forbidden[locale.identifier] ?? []
            XCTAssertFalse(words.isEmpty, "Keine Verbotsliste für \(locale.identifier)")
            for available in [true, false] {
                let text = (EnvironmentProbe.notice(isNetworkAvailable: available,
                                                    locale: locale) ?? "").lowercased()
                for word in words {
                    XCTAssertFalse(text.contains(word),
                                   "Verbotenes Wort \(word) in \(locale.identifier): \(text)")
                }
            }
        }
    }

    func testConnectedNoticeExistsInEveryLanguage() {
        for locale in locales {
            XCTAssertNotNil(EnvironmentProbe.notice(isNetworkAvailable: true, locale: locale))
            XCTAssertNil(EnvironmentProbe.notice(isNetworkAvailable: false, locale: locale))
        }
    }

    // MARK: Was nicht übersetzt werden darf

    /// „Dice" und „Use Raw Entropy" sind Beschriftungen auf Colemans englischer
    /// Seite. Übersetzt zeigen sie auf Knöpfe, die es dort nicht gibt — und
    /// erzeugen damit genau den Fehlalarm, den sie verhindern sollen.
    func testColemanControlNamesStayEnglishInEveryLanguage() {
        for locale in locales {
            for length in SeedLength.allCases {
                let joined = DiceMethod.coleman
                    .verificationSteps(for: length, locale: locale)
                    .joined(separator: " ")
                XCTAssertTrue(joined.contains("Dice"),
                              "Dice fehlt in \(locale.identifier)")
                XCTAssertTrue(joined.contains("Raw Entropy"),
                              "Raw Entropy fehlt in \(locale.identifier)")
            }
        }
    }

    func testShellCommandSurvivesTranslation() {
        for locale in locales {
            let joined = DiceMethod.sha256
                .verificationSteps(for: .twentyFour, locale: locale)
                .joined(separator: " ")
            XCTAssertTrue(joined.contains("shasum -a 256"),
                          "shasum-Befehl beschädigt in \(locale.identifier)")
        }
    }

    /// Im Bild aufgefallen: In der .strings-Tabelle war `%s` als `%%s` maskiert,
    /// obwohl dieser Zugang kein `String(format:)` durchlaeuft — der Befehl erschien
    /// mit doppeltem Prozentzeichen. Ein `contains("shasum")` haette das durchgelassen.
    func testShellCommandHasNoDoubledPercent() {
        for locale in locales {
            let joined = DiceMethod.sha256
                .verificationSteps(for: .twentyFour, locale: locale)
                .joined(separator: " ")
            XCTAssertTrue(joined.contains("'%s'"),
                          "printf-Platzhalter fehlt in \(locale.identifier): \(joined)")
            XCTAssertFalse(joined.contains("%%"),
                           "Doppeltes Prozentzeichen in \(locale.identifier): \(joined)")
        }
    }

    func testMethodTitlesAreNotTranslated() {
        XCTAssertEqual(DiceMethod.sha256.title, "SHA-256")
        XCTAssertEqual(DiceMethod.coleman.title, "Coleman")
    }

    // MARK: Der Fehlalarm-Fänger aus Phase 6, jetzt je Sprache

    func testHexTruncationHintExistsInEveryLanguage() {
        for locale in locales {
            let joined = DiceMethod.sha256
                .verificationSteps(for: .twelve, locale: locale)
                .joined(separator: " ")
            XCTAssertTrue(joined.contains("32"),
                          "Hinweis auf die ersten 32 Hex-Zeichen fehlt in \(locale.identifier)")
        }
    }

    // MARK: Vollständigkeit

    /// Kein stiller Rückfall auf Englisch. Schlägt fehl, sobald ein Schlüssel in
    /// der deutschen Tabelle vergessen wurde.
    func testNoGermanStringFallsBackToEnglish() {
        let de = Locale(identifier: "de")
        let en = Locale(identifier: "en")

        for length in SeedLength.allCases {
            XCTAssertNotEqual(length.title(locale: de), length.title(locale: en),
                              "Wortzahl nicht übersetzt: \(length.wordCount)")

            for method in DiceMethod.allCases {
                XCTAssertNotEqual(method.rollCountHint(for: length, locale: de),
                                  method.rollCountHint(for: length, locale: en),
                                  "Wurfzahl-Hinweis nicht übersetzt: \(method)")
            }
        }

        for method in DiceMethod.allCases {
            XCTAssertNotEqual(method.summary(locale: de), method.summary(locale: en),
                              "Kurzbeschreibung nicht übersetzt: \(method)")
        }

        XCTAssertNotEqual(DiceMethod.verificationWarning(locale: de),
                          DiceMethod.verificationWarning(locale: en),
                          "Warnung nicht übersetzt")

        XCTAssertNotEqual(EnvironmentProbe.notice(isNetworkAvailable: true, locale: de),
                          EnvironmentProbe.notice(isNetworkAvailable: true, locale: en),
                          "Umgebungshinweis nicht übersetzt")
    }

    /// Kein Schlüssel darf ununterschlagen bleiben: Liefert das Nachschlagen den
    /// Schlüssel selbst zurück, fehlt der Eintrag in der Tabelle.
    func testNoLookupReturnsItsOwnKey() {
        for locale in locales {
            var texts = [EnvironmentProbe.notice(isNetworkAvailable: true, locale: locale) ?? "",
                         DiceMethod.verificationWarning(locale: locale)]
            for method in DiceMethod.allCases {
                texts.append(method.summary(locale: locale))
                for length in SeedLength.allCases {
                    texts.append(method.rollCountHint(for: length, locale: locale))
                    texts.append(contentsOf: method.verificationSteps(for: length, locale: locale))
                    texts.append(length.title(locale: locale))
                }
            }
            for text in texts {
                XCTAssertFalse(text.contains("verify.") || text.contains("method.")
                               || text.contains("env.") || text.contains("seedLength."),
                               "Unübersetzter Schlüssel in \(locale.identifier): \(text)")
            }
        }
    }
}
