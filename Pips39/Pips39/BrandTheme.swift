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

    /// Nebentext statt `Color.secondary`.
    ///
    /// Das systemeigene Sekundärgrau ist Weiß bei 60 Prozent und kommt auf dem oberen
    /// Verlaufston nur auf 4,23:1. Das reißt das Mindestmaß von 4,5, und zwar bei
    /// genau den Zeilen, die klein gesetzt sind. Bei 78 Prozent sind es 5,84:1.
    static let secondaryText = Color.white.opacity(0.78)

    /// Der Grund der Hilfe. Flach und dunkel, **kein** Verlauf.
    ///
    /// Ein Sheet soll sich von der Seite darunter lösen. Trüge es denselben Verlauf,
    /// stünde oben in beiden dasselbe Magenta, und der Inhalt wiederholte den Grund,
    /// statt sich davon abzuheben. Weiß ginge nicht: Die App läuft erzwungen dunkel,
    /// ein heller Grund bräuchte dunkle Schrift und damit eine zweite Farbwelt nur
    /// für die Hilfe.
    ///
    /// Der Ton ist `gradientBottom` auf 60 Prozent seiner Helligkeit. Weißer Text
    /// trägt darauf 13,7:1, und gegen den Verlauf darunter hebt er sich mit 1,5:1 ab,
    /// also genauso deutlich wie die Hinweisflächen.
    static let sheet = Color(red: 0x3E/255, green: 0x17/255, blue: 0x69/255)

    /// Die Zeilen der Hilfe-Liste. Auf dem dunklen Sheet-Grund muss die Fläche
    /// **heller** werden, nicht dunkler wie sonst, sonst verschwindet sie darin.
    static let sheetRow = Color.white.opacity(0.15)

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

    /// Die Maße stehen hier, weil `BrandSecondaryButtonStyle` sie mitbenutzt. Mit 14
    /// Punkt oben und unten kommt der Knopf auf 44 Punkt, also genau auf Apples
    /// Mindestmaß für eine Trefferfläche. Weniger geht nicht.
    static let verticalPadding: CGFloat = 14
    static let horizontalPadding: CGFloat = 24

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Brand.gradientBottom)
            .padding(.vertical, Self.verticalPadding)
            // Etwas mehr als bei einem eckigen Knopf: An den Enden einer Kapsel
            // nimmt die Rundung Platz weg, den die Beschriftung sonst berührt.
            .padding(.horizontal, Self.horizontalPadding)
            // **Keine** Breitenvorgabe im Stil: In den Fußleisten steht der Knopf
            // neben „Überspringen" und dürfte dort nicht die ganze Zeile nehmen.
            // Wer volle Breite will, setzt sie auf die Beschriftung, so wie es die
            // Wortanzeige und die Wurfansicht ohnehin schon tun.
            .background(Color.white.opacity(configuration.isPressed ? 0.75 : 1))
            // Kapsel, nicht Rechteck. Daneben steht in jeder Fußleiste ein
            // `.bordered`-Knopf, und den zeichnet iOS 26 als Kapsel. Zwei Formen
            // nebeneinander sahen aus wie zwei verschiedene Arten von Knopf.
            .clipShape(Capsule())
    }
}

extension ButtonStyle where Self == BrandProminentButtonStyle {
    static var brandProminent: BrandProminentButtonStyle { BrandProminentButtonStyle() }
}

/// Der zweite Knopf in einer Fußleiste: „Überspringen", „Zurück".
///
/// Er ersetzt `.bordered`, und zwar aus einem messbaren Grund. Ein `.bordered`-Knopf
/// ohne `.controlSize` ist in iOS 26 rund **24 Punkt** hoch. Apple selbst nennt in den
/// Human Interface Guidelines **44 × 44 Punkt** als Mindestmaß für eine Trefferfläche,
/// die Vorgabe wird also fast um die Hälfte gerissen. Daneben stand ein prominenter
/// Knopf mit 44 Punkt, und der Unterschied war deutlich zu sehen.
///
/// Beide Stile rechnen jetzt mit denselben Zahlen. Wer die Polsterung oben ändert,
/// ändert sie hier mit, sonst laufen die Höhen wieder auseinander.
struct BrandSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundStyle(.white)
            .padding(.vertical, BrandProminentButtonStyle.verticalPadding)
            .padding(.horizontal, BrandProminentButtonStyle.horizontalPadding)
            // Durchscheinend statt deckend: Der Knopf ist der zweite Weg, nicht der
            // erste, und soll nicht mit dem weißen daneben um Aufmerksamkeit ringen.
            .background(Color.white.opacity(configuration.isPressed ? 0.28 : 0.18))
            .clipShape(Capsule())
    }
}

extension ButtonStyle where Self == BrandSecondaryButtonStyle {
    static var brandSecondary: BrandSecondaryButtonStyle { BrandSecondaryButtonStyle() }
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

    /// Der Verlauf hinter einer Ansicht, bis in Statusleiste und Home-Indikator.
    ///
    /// Muss an **jeden** Reiterinhalt einzeln, nicht nur an die Wurzel: `TabView`
    /// legt unter jeden Reiter einen eigenen deckenden Grund und verdeckt damit
    /// alles, was dahinter liegt.
    func brandBackground() -> some View {
        background { Brand.background.ignoresSafeArea() }
    }

    /// Der flache dunkle Grund der Hilfe. Siehe `Brand.sheet`.
    func sheetBackground() -> some View {
        background { Brand.sheet.ignoresSafeArea() }
    }
}
