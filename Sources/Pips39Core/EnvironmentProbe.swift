import Foundation
import Combine
import Network

/// Beobachtet, was über die Umgebung des Geräts feststellbar ist.
///
/// Die Trennung ist Absicht: `notice(isNetworkAvailable:)` ist eine reine Funktion
/// und damit prüfbar, der Monitor drumherum ist so dünn wie möglich.
public final class EnvironmentProbe: ObservableObject {

    /// Der anzuzeigende Hinweis, oder `nil` wenn nichts zu sagen ist.
    @Published public private(set) var notice: String?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "app.comodin.Pips39.environment")

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let available = path.status == .satisfied
            DispatchQueue.main.async {
                self?.notice = EnvironmentProbe.notice(isNetworkAvailable: available)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    /// Formuliert den Hinweis zu einem festgestellten Netzwerkzustand.
    ///
    /// > Wichtig: Es gibt **keinen** grünen „sicher"-Zustand. Ohne Verbindung sagt
    /// > die App gar nichts, statt eine Entwarnung zu geben, die sie nicht belegen
    /// > kann — Bluetooth ist seit iOS 13 nicht abfragbar, und wer den Flugmodus
    /// > kurz einschaltet, käme an jeder Sperre vorbei. Ein falsches
    /// > Sicherheitsversprechen ist schlechter als gar keins.
    public static func notice(isNetworkAvailable: Bool,
                              locale: Locale = .current) -> String? {
        guard isNetworkAvailable else { return nil }
        return Localized.string("env.connected", locale)
    }
}
