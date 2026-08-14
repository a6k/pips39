import SwiftUI
import UIKit

/// Hängt Inhalte in die Zeichenebene eines `UITextField` mit `isSecureTextEntry`.
/// iOS nimmt genau diese Ebene von Screenshots, Bildschirmaufnahmen und Spiegelung
/// aus — die Stelle bleibt im aufgenommenen Bild leer.
///
/// > [!warning] Kein Versprechen, nur eine zusätzliche Schicht
/// > Das ist **undokumentiertes Verhalten**. Apple hat die interne View-Hierarchie
/// > des sicheren Textfelds mehrfach umgebaut; der Griff darauf kann mit jedem
/// > iOS-Update still aufhören zu wirken, ohne Fehlermeldung. Deshalb steht in der
/// > Oberfläche **nirgends**, dass Screenshots geschützt seien, und die Meldung aus
/// > `ScreenProtection` bleibt bestehen: Sie funktioniert auch dann noch, wenn dieser
/// > Griff bricht.
///
/// Findet sich die Zeichenebene nicht, wird der Inhalt **ungeschützt, aber sichtbar**
/// angezeigt. Ein leerer Bildschirm wäre der schlechtere Ausfall.
struct SecureLayer<Content: View>: UIViewRepresentable {

    let content: Content

    func makeCoordinator() -> SecureLayerCoordinator {
        SecureLayerCoordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        context.coordinator.host = host

        // Das Textfeld muss am Leben bleiben, sonst verschwindet seine Ebene mit ihm.
        let field = context.coordinator.field
        field.isSecureTextEntry = true

        guard let canvas = field.layer.sublayers?.first?.delegate as? UIView else {
            let plain = UIView()
            plain.addSubview(host.view)
            pin(host.view, to: plain)
            context.coordinator.isProtected = false
            return plain
        }

        canvas.subviews.forEach { $0.removeFromSuperview() }
        canvas.isUserInteractionEnabled = true
        canvas.addSubview(host.view)
        pin(host.view, to: canvas)
        context.coordinator.isProtected = true
        return canvas
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (context.coordinator.host as? UIHostingController<Content>)?.rootView = content
    }

    private func pin(_ view: UIView, to parent: UIView) {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: parent.topAnchor),
            view.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
        ])
    }

}

/// Der Zustand hinter `SecureLayer`, **bewusst außerhalb** des generischen Structs
/// und ohne eigenen Typparameter.
///
/// Als verschachtelte Klasse hieße sie `SecureLayer<Content>.Coordinator` und wäre
/// damit selbst generisch, auch wenn sie den Parameter gar nicht mehr benutzt. Genau
/// daran ist der Swift-Optimizer abgestürzt: Ein Archive baut mit `-O`, und der
/// `EarlyPerfInliner` fiel über den generischen Deinit dieser Klasse. Debug baut
/// weiter sauber, weil der Pass dort nicht läuft, deshalb fiel es erst beim ersten
/// Archive auf.
///
/// **Den Typparameter nicht wieder einführen.** Das `UIHostingController<Content>`
/// wird deshalb als `UIViewController` gehalten und beim Aktualisieren zurückgecastet.
final class SecureLayerCoordinator {
    let field = UITextField()
    var host: UIViewController?
    /// Nur zur Diagnose — wird bewusst nirgends angezeigt.
    var isProtected = false
}

extension View {
    /// Zusätzliche Schicht gegen Screenshots. Bewusst ohne Zusage in der Oberfläche.
    func hiddenFromScreenCapture() -> some View {
        SecureLayer(content: self)
    }
}
