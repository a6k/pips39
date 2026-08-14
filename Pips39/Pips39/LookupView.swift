import SwiftUI
import Pips39Core

/// Der Ausdruck auf dem Schirm. Die App zeigt 32 Kandidaten und erfährt nie, welcher
/// davon genommen wurde.
///
/// Das Verfahren stammt aus der Anleitung *BitBox02 — Würfle deinen eigenen Seed* von
/// Shift Crypto AG (CC BY-SA 4.0); die Herkunft steht auch in der App, auf der
/// Einstiegsseite dieses Modus.
///
/// Was hier bewusst fehlt: eine Sitzung. Gespeichert wird die Wortnummer, sonst
/// nichts — die eingegebenen Würfel werden nach jedem Wort gelöscht. Lägen die 23
/// Tripel im Speicher, wären das 138 bit an einer Stelle statt 6 bit für einen
/// Augenblick.
///
/// Das Raster ist gegenüber dem Ausdruck transponiert: acht Wortspalten passen auf
/// keinem iPhone hochkant nebeneinander, vier Spalten und acht Zeilen zeigen dieselben
/// 32 Wörter in derselben Reihenfolge.
struct LookupView: View {

    private let totalWords = LookupTable.rolledWords(for: .twentyFour)

    @State private var dice: [Int] = []
    @State private var wordNumber = 1
    @State private var isFinished = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                bar

                if isFinished {
                    closing
                } else {
                    header
                    diceInput
                    if let block = currentBlock {
                        grid(for: block)
                        nextButton
                    } else {
                        hint
                    }
                }
            }
            .padding()
        }
        .screenProtected()
        .hiddenFromScreenCapture()
    }

    private var currentBlock: [String]? {
        guard dice.count == 3 else { return nil }
        return LookupTable.block(page: dice[0], second: dice[1], third: dice[2])
    }

    // MARK: Kopf

    /// Nur die Hilfe. Ein Reiter hat kein Zurück, der Weg hinaus ist der Reiterwechsel.
    private var bar: some View {
        TopBar()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Word \(wordNumber) of \(totalWords)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()
            Text("Throw five dice and the coin. Re-throw any die showing 5 or 6. Then enter the first three dice.")
                .font(.footnote)
                .foregroundStyle(Brand.secondaryText)
        }
    }

    // MARK: Eingabe der ersten drei Würfel

    private var diceInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ForEach(1...4, id: \.self) { face in
                    Button {
                        if dice.count < 3 { dice.append(face) }
                    } label: {
                        Image(systemName: "die.face.\(face).fill")
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .background(Brand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(dice.count == 3)
                }
            }

            HStack {
                ForEach(Array(dice.enumerated()), id: \.offset) { _, face in
                    Image(systemName: "die.face.\(face).fill")
                        .font(.title3)
                }
                Spacer()
                Button("Undo") { _ = dice.popLast() }
                    .font(.footnote)
                    .disabled(dice.isEmpty)
            }
            .frame(minHeight: 28)
        }
    }

    private var hint: some View {
        Text("A die showing 5 or 6 carries no value here. Throw it again until it shows 1 to 4.")
            .font(.footnote)
            .foregroundStyle(Brand.secondaryText)
    }

    // MARK: Das Raster

    private func grid(for block: [String]) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(" ").frame(width: 46)
                ForEach(1...4, id: \.self) { fourth in
                    Image(systemName: "die.face.\(fourth).fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.footnote)
            .foregroundStyle(Brand.secondaryText)

            ForEach(rowKeys, id: \.offset) { row in
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "die.face.\(row.fifth).fill")
                        Text(row.coin == .heads ? "H" : "T")
                            .font(.caption2.weight(.bold))
                    }
                    .frame(width: 46, alignment: .leading)
                    .foregroundStyle(Brand.secondaryText)

                    ForEach(1...4, id: \.self) { fourth in
                        Text(word(in: block, fourth: fourth, row: row))
                            .font(.footnote)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Text("H = heads (or a die showing 1 to 3), T = tails (4 to 6).")
                .font(.caption2)
                .foregroundStyle(Brand.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
    }

    /// Die Stelle kommt aus dem Paket, damit Formel und Anzeige nicht auseinander
    /// laufen können. `nil` kann hier nicht auftreten — die Schleifen laufen über
    /// 1...4 und `Coin.allCases` —, wird aber trotzdem abgefangen statt entpackt.
    private func word(in block: [String], fourth: Int, row: RowKey) -> String {
        guard let offset = LookupTable.offsetInBlock(fourth: fourth,
                                                     fifth: row.fifth,
                                                     coin: row.coin),
              block.indices.contains(offset) else { return "" }
        return block[offset]
    }

    private struct RowKey {
        let fifth: Int
        let coin: LookupTable.Coin
        var offset: Int { (fifth - 1) * 2 + (coin == .heads ? 0 : 1) }
    }

    private var rowKeys: [RowKey] {
        (1...4).flatMap { fifth in
            LookupTable.Coin.allCases.map { RowKey(fifth: fifth, coin: $0) }
        }
    }

    // MARK: Weiter

    private var nextButton: some View {
        Button {
            if wordNumber == totalWords {
                isFinished = true
            } else {
                wordNumber += 1
            }
            dice = []
        } label: {
            Text(wordNumber == totalWords ? "Done" : "Next word")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.brandProminent)
        .padding(.top, 4)
    }

    // MARK: Der Abschluss

    private var closing: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The 24th word")
                .font(.title2.weight(.semibold))
            Text("This app cannot work it out. It never saw your words, and the last word carries a checksum over all the others.")
                .font(.footnote)
            Text("Enter your 23 words into your wallet. It will offer eight valid options for the last one. Pick between them with three coin flips, not by feel. Eight options are exactly three bits.")
                .font(.footnote)
            Button("Start again") {
                wordNumber = 1
                dice = []
                isFinished = false
            }
                .buttonStyle(.brandProminent)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("Method from the BitBox02 dice guide by Shift Crypto, CC BY-SA 4.0.")
                .font(.caption)
                .foregroundStyle(Brand.secondaryText)
                .padding(.top, 4)
        }
    }
}

#Preview {
    LookupView()
}
