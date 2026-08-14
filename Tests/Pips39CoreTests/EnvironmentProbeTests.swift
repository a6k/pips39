import XCTest
@testable import Pips39Core

final class EnvironmentProbeTests: XCTestCase {

    func testConnectedDeviceProducesAStatement() {
        let notice = EnvironmentProbe.notice(isNetworkAvailable: true)
        XCTAssertNotNil(notice)
        XCTAssertTrue(notice!.contains("network"))
    }

    /// Ohne Verbindung sagt die App nichts. Sie gibt keine Entwarnung.
    func testDisconnectedDeviceProducesNoNotice() {
        XCTAssertNil(EnvironmentProbe.notice(isNetworkAvailable: false))
    }

    /// Der Kern von Spec 2.5, als Test festgehalten: Die App darf Sicherheit
    /// niemals behaupten. Bluetooth ist seit iOS 13 gar nicht abfragbar, und
    /// keine Verbindung heisst nicht luftdicht.
    func testNoNoticeEverClaimsSafety() {
        let forbidden = ["safe", "secure", "protected", "offline", "air-gap", "airgap"]
        for available in [true, false] {
            let text = (EnvironmentProbe.notice(isNetworkAvailable: available) ?? "").lowercased()
            for word in forbidden {
                XCTAssertFalse(text.contains(word),
                               "Verbotenes Wort \(word) im Hinweis: \(text)")
            }
        }
    }

    func testNoticeIsAStatementNotAnInstruction() {
        let text = EnvironmentProbe.notice(isNetworkAvailable: true) ?? ""
        XCTAssertFalse(text.contains("!"), "Kein Ausrufezeichen — Feststellung, kein Alarm")
        XCTAssertFalse(text.lowercased().hasPrefix("warning"))
    }
}
