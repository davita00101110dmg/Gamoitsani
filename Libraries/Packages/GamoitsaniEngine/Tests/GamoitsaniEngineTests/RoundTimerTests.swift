//
//  RoundTimerTests.swift
//  GamoitsaniEngineTests
//

import Testing
import Foundation
@testable import GamoitsaniEngine

@Suite("Round timer")
struct RoundTimerTests {

    private let start = Date(timeIntervalSince1970: 1_000_000)

    @Test("remaining time is derived from the deadline", arguments: [
        (0.0, 45.0), (10.0, 35.0), (44.0, 1.0), (45.0, 0.0), (99.0, 0.0),
    ])
    func remaining(elapsed: TimeInterval, expected: TimeInterval) {
        let timer = RoundTimer(startingAt: start, duration: 45)
        #expect(timer.remaining(at: start.addingTimeInterval(elapsed)) == expected)
    }

    /// The reason this is deadline-based. v1 used Timer.publish, which does not fire while
    /// the app is suspended, so backgrounding silently paused the round and gave the time
    /// back — you could stop the clock by swiping up.
    @Test("time spent backgrounded has genuinely elapsed")
    func backgroundingDoesNotPause() {
        let timer = RoundTimer(startingAt: start, duration: 30)
        let afterSuspension = start.addingTimeInterval(31)
        #expect(timer.hasExpired(at: afterSuspension))
        #expect(timer.remaining(at: afterSuspension) == 0)
    }

    @Test("progress runs 0 to 1 and clamps at both ends")
    func progress() {
        let timer = RoundTimer(startingAt: start, duration: 40)
        #expect(timer.progress(at: start) == 0)
        #expect(timer.progress(at: start.addingTimeInterval(20)) == 0.5)
        #expect(timer.progress(at: start.addingTimeInterval(400)) == 1)
    }

    @Test("urgency covers the final seconds but not the expired state")
    func urgency() {
        let timer = RoundTimer(startingAt: start, duration: 45)
        #expect(timer.isUrgent(at: start) == false)
        #expect(timer.isUrgent(at: start.addingTimeInterval(40)))
        #expect(timer.isUrgent(at: start.addingTimeInterval(44.5)))
        #expect(timer.isUrgent(at: start.addingTimeInterval(45)) == false, "expired is not urgent, it is over")
    }
}
