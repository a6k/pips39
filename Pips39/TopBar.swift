import SwiftUI

/// Die Knopfleiste am oberen Rand. Rechts steht **immer** die Hilfe.
///
/// Links kann jede Ansicht unterbringen, was sie braucht. Was vorher rechts stand,
/// wandert dorthin: Der Platz ganz rechts gehört der Hilfe, damit der Daumen ihn ohne
/// Hinsehen findet und keine Seite eine Ausnahme ist.
///
/// Die Aktion kommt über die Umgebung und nicht als Parameter. Sonst müsste jede der
/// sieben Ansichten eine Closure durchreichen, und die achte würde sie vergessen.
struct TopBar<Leading: View>: View {

    @ViewBuilder let leading: () -> Leading

    @Environment(\.showHelp) private var showHelp

    var body: some View {
        HStack {
            leading()
            Spacer(minLength: 0)
            Button("Help") { showHelp() }
                .font(.body)
        }
        .frame(minHeight: 28)
    }
}

extension TopBar where Leading == EmptyView {
    init() {
        self.init(leading: { EmptyView() })
    }
}

// MARK: Die Aktion in der Umgebung

private struct ShowHelpKey: EnvironmentKey {
    static let defaultValue: () -> Void = { }
}

extension EnvironmentValues {
    /// Öffnet die Hilfe. Wird einmal in `ContentView` gesetzt.
    var showHelp: () -> Void {
        get { self[ShowHelpKey.self] }
        set { self[ShowHelpKey.self] = newValue }
    }
}
