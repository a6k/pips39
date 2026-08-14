import SwiftUI
import Pips39Core

/// Erster Schritt: das Verfahren wählen.
///
/// Bewusst hier und nicht in den Einstellungen: Eine Wurffolge sagt nicht, mit
/// welchem Verfahren sie gerechnet wurde. Ein Schalter, der zwischen zwei Sitzungen
/// still umspringt, lässt den Nutzer sein Backup für kaputt halten.
struct MethodChoiceView: View {

    let onChoose: (DiceMethod, SeedLength) -> Void
    let onChooseLookupTable: () -> Void

    @State private var length: SeedLength = .standard

    var body: some View {
        ScrollView {
            content
                .padding()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pips39")
                    .font(.largeTitle.bold())
                Text("Roll dice, get a BIP39 seed phrase. Nothing is stored.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Seed length")
                    .font(.headline)
                Picker("Seed length", selection: $length) {
                    ForEach(SeedLength.allCases) { option in
                        Text(option.title()).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Text("Choose a method")
                .font(.headline)

            ForEach(DiceMethod.allCases, id: \.rawValue) { method in
                Button {
                    onChoose(method, length)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(method.title).font(.title3.weight(.semibold))
                            if method == .standard {
                                Text("DEFAULT")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(method.summary()).font(.footnote)
                        Text(method.rollCountHint(for: length))
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Text("The method travels with the result. Write it down together with your words.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            lookupSection
        }
    }

    /// Bewusst abgesetzt und nicht als dritte Karte: Dieser Weg erzeugt den Seed nicht
    /// in der App, er führt in keine Würfelansicht, und der Längen-Schalter oben gilt
    /// für ihn nicht. Drei gleich aussehende Karten würden drei Wege zum selben Ziel
    /// versprechen.
    private var lookupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Roll without a printout")
                .font(.headline)

            Button(action: onChooseLookupTable) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lookup table")
                        .font(.title3.weight(.semibold))
                    Text("For dice and a hardware wallet. The seed is made on paper — this app only shows the words to read off, and never learns it.")
                        .font(.footnote)
                    Text("Always 24 words.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Text("Method from the BitBox02 dice guide by Shift Crypto, CC BY-SA 4.0.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MethodChoiceView(onChoose: { _, _ in }, onChooseLookupTable: { })
}
