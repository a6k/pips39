import SwiftUI
import UIKit

/// Verdeckt den Inhalt, sobald er auf die Platte oder in eine Aufnahme geraten könnte.
///
/// Zwei verschiedene Fälle:
/// - **Hintergrund:** iOS legt beim Wechsel in den App-Umschalter einen Schnappschuss
///   des Bildschirms als Datei ab. Der Inhalt wird deshalb schon bei
///   `willResignActive` verdeckt, nicht erst bei `didEnterBackground`.
/// - **Aufnahme und Spiegelung:** `UIScreen.isCaptured` ist zuverlässig, hier wird
///   hart abgeblendet.
///
/// Screenshots lassen sich nicht verhindern — iOS meldet sie erst hinterher.
struct ScreenProtection: ViewModifier {

    @State private var isObscured = false
    @State private var isCaptured = UIScreen.main.isCaptured

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isObscured || isCaptured ? 0 : 1)

            if isObscured || isCaptured {
                VStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill").font(.largeTitle)
                    Text(isCaptured ? "Hidden while the screen is being recorded or mirrored."
                                    : "Hidden")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
                .padding()
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willResignActiveNotification)) { _ in
            isObscured = true
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification)) { _ in
            isObscured = false
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIScreen.capturedDidChangeNotification)) { _ in
            isCaptured = UIScreen.main.isCaptured
        }
    }
}

extension View {
    /// Auf jede Ansicht anwenden, die Wörter oder die Wurffolge zeigt.
    func screenProtected() -> some View {
        modifier(ScreenProtection())
    }
}
