import Foundation

/// Die beiden grundsätzlich verschiedenen Wege durch diese App.
///
/// Das ist die **grobe** Wahl und fällt im Onboarding: Rechnet die App aus den Würfen,
/// oder liest der Nutzer ab? Die feine Wahl — SHA-256 oder Coleman, 12 oder 24 Wörter —
/// bleibt auf der Startseite, weil sie nur den ersten Weg betrifft.
///
/// Der Unterschied, auf den es ankommt, steht in `exposure(locale:)`: wie viel vom Seed
/// die App dabei zu sehen bekommt. Alles andere ist Bedienung.
public enum OnboardingPath: String, CaseIterable, Equatable, Identifiable {

    /// Würfeln, die App rechnet. Sie sieht den ganzen Seed.
    case rollAndCompute

    /// Nachschlagetabelle. Die App sieht 6 von 11 Bit je Wort.
    case lookupTable

    public var id: String { rawValue }

    /// Ob die App auf diesem Weg den ganzen Seed zu sehen bekommt.
    ///
    /// Steht hier und nicht in der Ansicht, weil es eine Aussage über das Verfahren ist
    /// und keine über die Gestaltung. Die Ansicht entscheidet daraufhin, dass dieser
    /// eine Satz rot wird: Er ist der wichtigste der Seite, und in Grau wird er
    /// überlesen.
    public var appSeesEverything: Bool {
        self == .rollAndCompute
    }

    public func title(locale: Locale = .current) -> String {
        Localized.string("onboarding.path.\(rawValue).title", locale)
    }

    /// Was der Nutzer tut.
    public func summary(locale: Locale = .current) -> String {
        Localized.string("onboarding.path.\(rawValue).summary", locale)
    }

    /// Was die App dabei erfährt. Der einzige Satz, der die Wahl wirklich trägt.
    public func exposure(locale: Locale = .current) -> String {
        switch self {
        case .rollAndCompute:
            return Localized.string("onboarding.path.rollAndCompute.exposure", locale)
        case .lookupTable:
            return Localized.string("onboarding.path.lookupTable.exposure", locale,
                                    LookupTable.hiddenBits(for: .twentyFour))
        }
    }
}
