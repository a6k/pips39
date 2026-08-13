import Foundation

/// Bytes, die niemals in Logs, Fehlermeldungen oder Debug-Ausgaben auftauchen sollen,
/// und die aktiv überschrieben werden können.
///
/// Das ist Sorgfalt, keine Garantie: Swift gibt keine Zusage darüber, ob der Puffer
/// zwischenzeitlich kopiert oder ausgelagert wurde. Der Typ macht die Absicht sichtbar
/// und verhindert versehentliches Ausgeben — mehr kann er nicht.
public struct SecretBytes: CustomStringConvertible, CustomDebugStringConvertible {

    public private(set) var bytes: [UInt8]

    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    /// Überschreibt den Inhalt mit Nullen, ohne die Länge zu ändern.
    public mutating func wipe() {
        for index in bytes.indices {
            bytes[index] = 0
        }
    }

    public var description: String { "SecretBytes(\(bytes.count) Bytes)" }
    public var debugDescription: String { description }
}
