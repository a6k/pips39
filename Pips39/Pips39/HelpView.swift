import SwiftUI
import Pips39Core

/// Das Inhaltsverzeichnis der Hilfe, von jeder Seite über den Knopf oben rechts.
///
/// Vorher lagen alle Texte in einer langen Rolle. Mit den Abschnitten zur Prüfsumme und
/// zur Angreifbarkeit wurde daraus eine Strecke, auf der man nichts wiederfindet. Ein
/// Verzeichnis kostet einen Tipp mehr und macht jede Seite für sich lesbar.
struct HelpView: View {

    let onClose: () -> Void

    @ObservedObject var probe: EnvironmentProbe

    var body: some View {
        NavigationStack {
            List {
                // Die Zeilenfarbe steht **innen**, an einer `Group` um die Zeilen.
                // Auf der `List` selbst wirkt `.listRowBackground` nicht: Er gilt für
                // die Zeile, auf die er angewandt wird, und außen gibt es keine.
                Group {
                    NavigationLink("What a seed is") { HelpSeedTopic() }
                    NavigationLink("The last word and the checksum") { HelpChecksumTopic() }
                    NavigationLink("About the dice") { HelpDiceTopic() }
                    NavigationLink("How safe is this really") { HelpStrengthTopic() }
                    NavigationLink("Take it offline") { HelpOfflineTopic(probe: probe) }
                    NavigationLink("The source code") { HelpSourceTopic() }
                }
                .listRowBackground(Brand.sheetRow)
            }
            // Die Liste bringt einen eigenen, systemgrauen Grund mit und stünde damit
            // als graue Insel auf dem violetten Sheet.
            .scrollContentBackground(.hidden)
            .sheetBackground()
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
    }
}

#Preview {
    HelpView(onClose: { }, probe: EnvironmentProbe())
}
