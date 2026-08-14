import SwiftUI

/// Die Farben der App an einer Stelle.
///
/// Die beiden Verlaufsfarben sind die des App-Icons auf 70 Prozent ihrer Helligkeit.
/// Im Original (`CB30E0` und `9437FF`) trägt weißer Text oben nur 4,17:1 und fällt
/// damit unter das Mindestmaß von 4,5. Abgedunkelt sind es 7,33:1 und 8,37:1, also
/// die komfortable Stufe. Derselbe Farbton, satter.
enum Brand {

    static let gradientTop = Color(red: 0x8E/255, green: 0x22/255, blue: 0x9D/255)
    static let gradientBottom = Color(red: 0x68/255, green: 0x26/255, blue: 0xB2/255)

    /// Flächen für Würfel und Karten. Durchscheinendes Weiß statt `Color.secondary`,
    /// das auf Violett schlammig wird.
    static let surface = Color.white.opacity(0.12)

    /// Die Fläche unter Warnungen und Hinweisen. **Es gibt keine Warnfarbe.**
    ///
    /// Auf diesem Violett kommt Systemrot auf 2,15:1 und ist unlesbar. Bernstein trüge
    /// 4,69:1, kostet aber Textkontrast. Eine dunkle durchscheinende Fläche gewinnt
    /// beides: Sie hebt sich mit 1,54 bis 1,62:1 vom Grund ab und trägt weißen Text
    /// mit 11,9 bis 12,9:1, also besser als der blanke Verlauf mit 7,3:1.
    ///
    /// Das Signal „Achtung" trägt danach das Symbol und die Strichstärke, nicht die
    /// Farbe. Die Palette bleibt bei zwei Violetttönen, Weiß und Transparenz.
    static let panel = Color.black.opacity(0.35)

    static var background: LinearGradient {
        LinearGradient(colors: [gradientTop, gradientBottom],
                       startPoint: .top, endPoint: .bottom)
    }
}

/// Prominente Knöpfe drehen den Kontrast um: weiße Fläche, violette Schrift.
///
/// Ein farbiger Knopf mit weißer Schrift ginge hier nicht. Der Akzent müsste zugleich
/// Kontrast gegen das violette Umfeld und gegen die eigene weiße Beschriftung tragen,
/// und das schließt sich aus.
struct BrandProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Brand.gradientBottom)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            // **Keine** Breitenvorgabe im Stil: In den Fußleisten steht der Knopf
            // neben „Überspringen" und dürfte dort nicht die ganze Zeile nehmen.
            // Wer volle Breite will, setzt sie auf die Beschriftung, so wie es die
            // Wortanzeige und die Wurfansicht ohnehin schon tun.
            .background(Color.white.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

extension ButtonStyle where Self == BrandProminentButtonStyle {
    static var brandProminent: BrandProminentButtonStyle { BrandProminentButtonStyle() }
}

/// Die Fläche unter einem Hinweis: dunkel, durchscheinend, mit runden Ecken.
///
/// Eigener Modifikator, weil dieselben drei Zeilen an vier Stellen stehen und dort
/// leicht auseinanderlaufen.
struct NoticePanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.panel)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension View {
    func noticePanel() -> some View { modifier(NoticePanel()) }
}
