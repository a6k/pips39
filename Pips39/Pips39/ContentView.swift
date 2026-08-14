import SwiftUI
import Pips39Core

/// Onboarding, danach drei Reiter, die nebeneinander stehen bleiben.
///
/// Vorher führte eine Verfahrenswahl in genau einen Weg, und der Rückweg verwarf alles.
/// Die App ist aber zum Ausprobieren da: Alle drei Wege bleiben erreichbar, und der
/// Wechsel kostet nichts, weil jeder Reiter seinen eigenen Zustand hält.
struct ContentView: View {

    enum Tab: Hashable {
        case sha256
        case coleman
        case lookupTable
    }

    @StateObject private var probe = EnvironmentProbe()
    @State private var hasStarted = false
    @State private var showsHelp = false
    @State private var tab: Tab = .sha256

    var body: some View {
        content
            .environment(\.showHelp) { showsHelp = true }
            .sheet(isPresented: $showsHelp) {
                HelpView(onClose: { showsHelp = false }, probe: probe)
            }
    }

    @ViewBuilder
    private var content: some View {
        if !hasStarted {
            OnboardingView(probe: probe) { destination in
                // Die Wahl auf Seite 3 stellt den Reiter ein, sperrt aber keinen.
                if destination == .lookupTable { tab = .lookupTable }
                hasStarted = true
            }
        } else {
            TabView(selection: $tab) {
                RollingFlow(method: .sha256, probe: probe)
                    .tabItem { Label("SHA-256", systemImage: "number") }
                    .tag(Tab.sha256)

                RollingFlow(method: .coleman, probe: probe)
                    .tabItem { Label("Coleman", systemImage: "list.number") }
                    .tag(Tab.coleman)

                LookupView()
                    .tabItem { Label("Word table", systemImage: "tablecells") }
                    .tag(Tab.lookupTable)
            }
        }
    }
}

#Preview {
    ContentView()
}
