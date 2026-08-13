import SwiftUI
import Pips39Core

/// Erster Schritt: das Verfahren wählen.
///
/// Bewusst hier und nicht in den Einstellungen: Eine Wurffolge sagt nicht, mit
/// welchem Verfahren sie gerechnet wurde. Ein Schalter, der zwischen zwei Sitzungen
/// still umspringt, lässt den Nutzer sein Backup für kaputt halten.
struct MethodChoiceView: View {

    let onChoose: (DiceMethod) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pips39")
                    .font(.largeTitle.bold())
                Text("Roll dice, get a BIP39 seed phrase. Nothing is stored.")
                    .foregroundStyle(.secondary)
            }

            Text("Choose a method")
                .font(.headline)

            ForEach(DiceMethod.allCases, id: \.rawValue) { method in
                Button {
                    onChoose(method)
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
                        Text(method.summary).font(.footnote)
                        Text(method.rollCountHint)
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

            Spacer()
        }
        .padding()
    }
}

#Preview {
    MethodChoiceView { _ in }
}
