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
/// - **Screenshots:** lassen sich nicht verhindern. iOS meldet sie erst hinterher,
///   also kann die App nur sagen, was passiert ist — und das tut sie, weil die
///   Aufnahme sonst unbemerkt in der Mediathek und womöglich in iCloud landet.
struct ScreenProtection: ViewModifier {

    @State private var isObscured = false
    @State private var isCaptured = UIScreen.main.isCaptured
    @State private var screenshotTaken = false

    func body(content: Content) -> some View {
        ZStack {
            VStack(spacing: 0) {
                if screenshotTaken {
                    screenshotNotice
                }
                content
            }
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
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            screenshotTaken = true
        }
    }

    /// Eine Feststellung, keine Entwarnung und keine Beschwichtigung: Das Bild
    /// existiert bereits, die App kann es weder verhindern noch löschen.
    private var screenshotNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "camera.fill")
            Text("A screenshot was taken. That image is now in your photo library, and iCloud may sync it.")
                .font(.footnote.weight(.medium))
            Spacer(minLength: 0)
        }
        .foregroundStyle(.red)
        .padding(12)
        .background(Color.red.opacity(0.1))
    }
}

extension View {
    /// Auf jede Ansicht anwenden, die Wörter oder die Wurffolge zeigt.
    func screenProtected() -> some View {
        modifier(ScreenProtection())
    }
}
