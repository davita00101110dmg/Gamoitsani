//
//  WeeklyNudge.swift
//  GamoitsaniCore
//
import Foundation

/// One scheduled reminder: when it fires, and which line it carries.
public struct NudgeOccurrence: Sendable, Hashable {
    public let date: Date
    /// Index into the app's list of localised lines.
    public let copyIndex: Int

    public init(date: Date, copyIndex: Int) {
        self.date = date
        self.copyIndex = copyIndex
    }
}

/// Plans the weekly "come back and play" reminder.
///
/// v1 scheduled a single repeating trigger whose content was chosen once, so the same
/// sentence arrived every week for years while looking as though it varied. It also fired
/// on a random weekday at a random minute, picked once and then fixed forever.
///
/// This plans a run of individual occurrences instead — each with its own line, rotating —
/// which the app tops up as they are consumed. A party game is played at the weekend, so
/// the default slot is Saturday evening rather than whatever minute the dice produced.
public struct WeeklyNudge: Sendable, Hashable {

    /// 1 is Sunday, matching `DateComponents.weekday`. 7 is Saturday.
    public var weekday: Int
    public var hour: Int
    public var minute: Int

    /// How many weeks are scheduled at once.
    ///
    /// iOS caps an app at 64 pending local notifications, so this stays well clear while
    /// still surviving a few months without the app being opened.
    public var weeksAhead: Int

    public init(weekday: Int = 7, hour: Int = 18, minute: Int = 0, weeksAhead: Int = 8) {
        self.weekday = weekday
        self.hour = hour
        self.minute = minute
        self.weeksAhead = weeksAhead
    }

    /// The next `weeksAhead` occurrences after `now`, each carrying the next line in
    /// rotation so no two consecutive reminders read the same.
    ///
    /// `copyCount` is how many lines the app has. Zero produces nothing rather than
    /// dividing by it.
    public func occurrences(
        after now: Date,
        copyCount: Int,
        calendar: Calendar = .current
    ) -> [NudgeOccurrence] {
        guard copyCount > 0, weeksAhead > 0 else { return [] }

        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute

        // Strictly after `now`: scheduling something for a moment that has already passed
        // delivers it immediately, which is how a reminder becomes a surprise.
        guard let first = calendar.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTime
        ) else { return [] }

        var result: [NudgeOccurrence] = []
        var date = first
        for week in 0..<weeksAhead {
            result.append(NudgeOccurrence(date: date, copyIndex: week % copyCount))
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: date) else { break }
            date = next
        }
        return result
    }
}
