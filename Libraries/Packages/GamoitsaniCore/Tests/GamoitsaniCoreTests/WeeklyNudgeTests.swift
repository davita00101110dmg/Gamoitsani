//
//  WeeklyNudgeTests.swift
//  GamoitsaniCoreTests
//

import Foundation
import Testing
@testable import GamoitsaniCore

@Suite("Weekly nudge")
struct WeeklyNudgeTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// A Wednesday.
    private var now: Date {
        DateComponents(
            calendar: calendar,
            year: 2026, month: 9, day: 9, hour: 12
        ).date!
    }

    private let nudge = WeeklyNudge()

    @Test("it schedules the requested number of weeks")
    func count() {
        let plan = nudge.occurrences(after: now, copyCount: 4, calendar: calendar)
        #expect(plan.count == nudge.weeksAhead)
    }

    @Test("every occurrence lands on the chosen evening")
    func slot() {
        for occurrence in nudge.occurrences(after: now, copyCount: 4, calendar: calendar) {
            let parts = calendar.dateComponents([.weekday, .hour, .minute], from: occurrence.date)
            #expect(parts.weekday == nudge.weekday)
            #expect(parts.hour == nudge.hour)
            #expect(parts.minute == nudge.minute)
        }
    }

    @Test("occurrences are a week apart, in order")
    func weekly() {
        let plan = nudge.occurrences(after: now, copyCount: 4, calendar: calendar)
        for (earlier, later) in zip(plan, plan.dropFirst()) {
            let days = calendar.dateComponents([.day], from: earlier.date, to: later.date).day
            #expect(days == 7)
        }
    }

    /// Scheduling for a moment that has already passed delivers it immediately, which is
    /// how a reminder becomes a surprise.
    @Test("nothing is scheduled in the past")
    func future() {
        let plan = nudge.occurrences(after: now, copyCount: 4, calendar: calendar)
        #expect(plan.allSatisfy { $0.date > now })
    }

    /// The bug this exists to avoid: v1 picked one line and repeated it forever behind a
    /// repeating trigger, so it looked varied and never was.
    @Test("consecutive reminders never repeat a line")
    func rotates() {
        let plan = nudge.occurrences(after: now, copyCount: 3, calendar: calendar)
        for (earlier, later) in zip(plan, plan.dropFirst()) {
            #expect(earlier.copyIndex != later.copyIndex)
        }
    }

    @Test("a single line is used rather than refusing to schedule")
    func oneLine() {
        let plan = nudge.occurrences(after: now, copyCount: 1, calendar: calendar)
        #expect(plan.count == nudge.weeksAhead)
        #expect(plan.allSatisfy { $0.copyIndex == 0 })
    }

    @Test("no copy means nothing to say")
    func noCopy() {
        #expect(nudge.occurrences(after: now, copyCount: 0, calendar: calendar).isEmpty)
    }

    /// iOS keeps only 64 pending local notifications per app.
    @Test("the plan stays well inside the system limit")
    func withinSystemLimit() {
        #expect(nudge.weeksAhead <= 64)
    }

    @Test("a firing day that is today but already past goes to next week")
    func todayButPassed() {
        // Saturday 20:00, after the 18:00 slot.
        let saturdayEvening = DateComponents(
            calendar: calendar, year: 2026, month: 9, day: 12, hour: 20
        ).date!
        let plan = nudge.occurrences(after: saturdayEvening, copyCount: 4, calendar: calendar)

        let first = try! #require(plan.first)
        #expect(first.date > saturdayEvening)
        let days = calendar.dateComponents([.day], from: saturdayEvening, to: first.date).day
        #expect(days == 6, "next Saturday, not today")
    }
}
