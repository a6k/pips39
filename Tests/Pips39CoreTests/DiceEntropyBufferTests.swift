import XCTest
@testable import Pips39Core

final class DiceEntropyBufferTests: XCTestCase {

    func testStartsEmpty() {
        let buffer = DiceEntropy(method: .sha256)
        XCTAssertEqual(buffer.rolls, [])
    }

    func testAppendsInOrder() throws {
        var buffer = DiceEntropy(method: .sha256)
        try buffer.append(3)
        try buffer.append(1)
        try buffer.append(6)
        XCTAssertEqual(buffer.rolls, [3, 1, 6])
    }

    func testUndoRemovesLastRoll() throws {
        var buffer = DiceEntropy(method: .sha256)
        try buffer.append(3)
        try buffer.append(1)
        buffer.undo()
        XCTAssertEqual(buffer.rolls, [3])
    }

    func testUndoOnEmptyBufferDoesNothing() {
        var buffer = DiceEntropy(method: .sha256)
        buffer.undo()
        XCTAssertEqual(buffer.rolls, [])
    }

    func testRejectsRollBelowOne() {
        var buffer = DiceEntropy(method: .sha256)
        XCTAssertThrowsError(try buffer.append(0)) { error in
            XCTAssertEqual(error as? DiceError, .invalidRoll(0))
        }
        XCTAssertEqual(buffer.rolls, [])
    }

    func testRejectsRollAboveSix() {
        var buffer = DiceEntropy(method: .sha256)
        XCTAssertThrowsError(try buffer.append(7)) { error in
            XCTAssertEqual(error as? DiceError, .invalidRoll(7))
        }
    }

    func testAcceptsAllSixFaces() throws {
        var buffer = DiceEntropy(method: .sha256)
        for face in UInt8(1)...UInt8(6) {
            try buffer.append(face)
        }
        XCTAssertEqual(buffer.rolls, [1, 2, 3, 4, 5, 6])
    }
}
