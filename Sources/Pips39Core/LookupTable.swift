import Foundation

/// Die BitBox02-Diceware-Tabelle als Rechnung statt als Ausdruck.
///
/// **Herkunft:** Das Verfahren stammt aus der Anleitung *BitBox02 — Würfle deinen
/// eigenen Seed* von Shift Crypto AG, veröffentlicht unter CC BY-SA 4.0. Sie liegt im
/// Repo unter `BitBox-Anleitung/`. Übernommen ist die Idee, nicht ihr Dokument: Die
/// Zuordnung ist eine Formel über die BIP39-Wortliste, und die stammt aus BIP-39.
///
/// Fünf Würfel und eine Münze wählen ein Wort aus der BIP39-Liste. Würfel zeigen nur
/// 1 bis 4 — eine 5 oder 6 wird neu geworfen. Das ist Rejection Sampling und liefert
/// exakt 2 bit je Würfel, ohne Modulo-Bias und ohne Kürzung. Mit dem Münzbit sind es
/// 11 bit, also genau die 2048 Wörter.
///
/// ```
/// Index = (W1−1)·512 + (W2−1)·128 + (W3−1)·32 + (W4−1)·8 + (W5−1)·2 + Münze
/// ```
///
/// **Die App bekommt nur die ersten drei Würfel zu sehen.** Sie zeigt daraufhin den
/// Block von 32 Wörtern, in dem das gesuchte steht; welches davon es ist, liest der
/// Nutzer ab und tippt es nie ein. Deshalb kennt die App 6 von 11 bit je Wort — siehe
/// `hiddenBits(for:)`.
///
/// Hier wird bewusst **nichts** gerechnet, was über die Formel hinausgeht: Wer der App
/// nicht traut, prüft sie gegen eine beliebige BIP39-Wortliste und ist fertig.
public enum LookupTable {

    /// Wie viele Wörter die App zeigt, nachdem drei Würfel eingegeben wurden:
    /// 4 (Würfel 4) × 4 (Würfel 5) × 2 (Münze).
    public static let wordsPerBlock = 32

    /// Der Münzwurf. Wer keine Münze hat, wirft einen Würfel: 1 bis 3 ist Kopf,
    /// 4 bis 6 ist Zahl — beides drei von sechs, also unverfälscht.
    public enum Coin: CaseIterable, Equatable {
        case heads
        case tails

        var bit: Int { self == .heads ? 0 : 1 }
    }

    private static let validFaces = 1...4

    /// Der Wortindex, oder `nil` wenn ein Würfel außerhalb 1 bis 4 liegt.
    public static func index(page: Int, second: Int, third: Int,
                             fourth: Int, fifth: Int, coin: Coin) -> Int? {
        guard let base = blockStart(page: page, second: second, third: third),
              let offset = offsetInBlock(fourth: fourth, fifth: fifth, coin: coin)
        else { return nil }
        return base + offset
    }

    /// Die 32 Wörter, unter denen das gesuchte steht — in genau der Reihenfolge, die
    /// `offsetInBlock(fourth:fifth:coin:)` adressiert.
    public static func block(page: Int, second: Int, third: Int) -> [String]? {
        guard let start = blockStart(page: page, second: second, third: third) else {
            return nil
        }
        return Array(WordList.english[start..<(start + wordsPerBlock)])
    }

    /// Die Stelle im Block. Die Ansicht baut daraus ihr Raster, damit Formel und
    /// Anzeige nicht auseinanderlaufen können.
    public static func offsetInBlock(fourth: Int, fifth: Int, coin: Coin) -> Int? {
        guard validFaces.contains(fourth), validFaces.contains(fifth) else { return nil }
        return (fourth - 1) * 8 + (fifth - 1) * 2 + coin.bit
    }

    private static func blockStart(page: Int, second: Int, third: Int) -> Int? {
        guard validFaces.contains(page),
              validFaces.contains(second),
              validFaces.contains(third) else { return nil }
        return (page - 1) * 512 + (second - 1) * 128 + (third - 1) * 32
    }

    // MARK: Was der App verborgen bleibt

    /// So viele Wörter werden gewürfelt — das letzte kommt aus der Wallet, weil dafür
    /// die Prüfsumme über alle anderen nötig wäre.
    public static func rolledWords(for length: SeedLength) -> Int {
        length.wordCount - 1
    }

    /// Die Schwelle, an der die Entscheidung für 24 Wörter hängt.
    ///
    /// NIST SP 800-57 nennt 112 bit als kleinste Stärke, die über 2030 hinaus tragen
    /// soll. Bewusst nicht 128: Die 118 bit dieses Modus liegen darunter, und es wäre
    /// unehrlich, die Grenze so zu legen, dass die eigene Zahl gerade darüber landet.
    public static let minimumHiddenBits = 112

    /// Die Entropie, die diese App auch dann nicht kennt, wenn sie kompromittiert ist.
    ///
    /// Je gewürfeltem Wort bleiben 5 der 11 bit ungelesen. Dazu kommen die freien Bits
    /// im letzten Wort: 11 minus der Prüfsumme, also 3 bei 24 Wörtern und 7 bei 12.
    ///
    /// Das Ergebnis trägt die Entscheidung, dass es diesen Modus nur mit 24 Wörtern
    /// gibt: 118 bit gegen 62 bit.
    ///
    /// **Nicht schönreden:** 118 liegt unter den 256 bit, die ein gewürfelter
    /// 24-Wort-Seed sonst hat, und auch unter den üblichen 128. Gegenüber der
    /// gedruckten Tabelle kostet dieser Modus Sicherheit — er kauft dafür, dass man
    /// keinen Drucker braucht. Gegenüber dem normalen Pips39-Ablauf, wo die App alles
    /// sieht, gewinnt er 118 bit.
    public static func hiddenBits(for length: SeedLength) -> Int {
        let checksumBits = length.entropyBits / 32
        let freeBitsInLastWord = 11 - checksumBits
        return rolledWords(for: length) * 5 + freeBitsInLastWord
    }
}
