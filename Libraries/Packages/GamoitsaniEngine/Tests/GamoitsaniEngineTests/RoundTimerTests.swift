import XCTest
@testable import GamoitsaniEngine

final class RoundTimerTests: XCTestCase {
    func testRemainingIsDerivedFromTheDeadline() {
        let start = Date()
        let timer = RoundTimer(startingAt: start, duration: 60)
        XCTAssertEqual(timer.remaining(at: start), 60, accuracy: 0.001)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(25)), 35, accuracy: 0.001)
    }

    func testRemainingNeverGoesNegative() {
        let start = Date()
        let timer = RoundTimer(startingAt: start, duration: 10)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(999)), 0)
        XCTAssertTrue(timer.hasExpired(at: start.addingTimeInterval(10)))
    }

    /// The reason this is deadline-based. A tick-counting timer loses time while the app
    /// is suspended; deriving from a deadline cannot, because nothing is being counted.
    func testTimeSpentBackgroundedStillElapses() {
        let start = Date()
        let timer = RoundTimer(startingAt: start, duration: 30)
        let afterLongSuspension = start.addingTimeInterval(31)
        XCTAssertTrue(timer.hasExpired(at: afterLongSuspension))
    }
}
