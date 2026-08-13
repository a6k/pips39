import SwiftUI
import Pips39Core

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Pips39")
                .font(.largeTitle.bold())
            Text("\(WordList.english.count) BIP39 words loaded")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
