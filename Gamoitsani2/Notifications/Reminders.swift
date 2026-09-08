//
//  Reminders.swift
//  Gamoitsani2
//
import SwiftUI
import Observation
import UserNotifications
import GamoitsaniCore
import GamoitsaniL10n

/// The weekly "come back and play" reminder.
///
/// Off until switched on, and the system prompt is asked at that moment rather than at
/// launch — v1 asked on first run, before anyone knew what the app was, which is the
/// surest way to be refused permanently.
@MainActor
@Observable
final class Reminders {

    /// Whether the player asked for reminders. The switch in Settings.
    private(set) var isOn: Bool

    /// True once the system has refused. The toggle explains itself instead of silently
    /// doing nothing.
    private(set) var isDenied = false

    @ObservationIgnored private let nudge = WeeklyNudge()
    @ObservationIgnored private let center = UNUserNotificationCenter.current()

    /// How many lines the catalogue holds. Rotation is over these.
    @ObservationIgnored private let copyCount = 4

    init() {
        isOn = UserDefaults.standard.bool(forKey: Self.key)
    }

    /// Refreshes what the system thinks, then tops up the schedule.
    ///
    /// Called at launch. Permission can be revoked in Settings while the app is closed, and
    /// the schedule needs extending long before eight weeks of reminders run out.
    func refresh(language: AppLanguage) async {
        let settings = await center.notificationSettings()
        isDenied = settings.authorizationStatus == .denied

        guard isOn, settings.authorizationStatus == .authorized else {
            if isDenied { isOn = false }
            return
        }
        await reschedule(language: language)
    }

    /// Turns reminders on or off, asking the system the first time.
    func setOn(_ wanted: Bool, language: AppLanguage) async {
        guard wanted else {
            isOn = false
            UserDefaults.standard.set(false, forKey: Self.key)
            cancel()
            return
        }

        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        isDenied = !granted
        isOn = granted
        UserDefaults.standard.set(granted, forKey: Self.key)
        if granted { await reschedule(language: language) }
    }

    // MARK: - Scheduling

    /// Rebuilt whenever the language changes, so a reminder never arrives in the language
    /// the player switched away from. The copy is baked into each request when it is
    /// scheduled — iOS does not re-resolve it at delivery.
    private func reschedule(language: AppLanguage) async {
        cancel()

        for occurrence in nudge.occurrences(after: .now, copyCount: copyCount) {
            let content = UNMutableNotificationContent()
            // The app's language, not the system's. `L10n.string(_:)` without a language
            // reads the system locale, which is the whole reason this app has its own
            // switch.
            content.title = L10n.string("reminder.title.\(occurrence.copyIndex)", language: language)
            content.body = L10n.string("reminder.body.\(occurrence.copyIndex)", language: language)
            content.sound = .default

            // One request per occurrence, each with its own line. v1 used a single
            // repeating trigger whose content was chosen once, so the same sentence
            // arrived every week for years while appearing to vary.
            let parts = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: occurrence.date
            )
            let request = UNNotificationRequest(
                identifier: "\(Self.prefix)\(occurrence.date.timeIntervalSince1970)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            )
            try? await center.add(request)
        }
    }

    /// Removes only this app's reminders. v1 called
    /// `removeAllPendingNotificationRequests`, which would take anything else with it.
    private func cancel() {
        center.getPendingNotificationRequests { [center] requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(Self.prefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static let key = "reminders.enabled"
    private static let prefix = "weekly-nudge-"

    #if DEBUG
    var debugSummary: [(String, String)] {
        [("on", isOn ? "yes" : "no"), ("denied", isDenied ? "yes" : "no")]
    }

    /// Delivers one in a few seconds, so the copy and sound can be seen without waiting
    /// for Saturday.
    func debugFireSoon(language: AppLanguage) async {
        let content = UNMutableNotificationContent()
        content.title = L10n.string("reminder.title.0", language: language)
        content.body = L10n.string("reminder.body.0", language: language)
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "\(Self.prefix)debug",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        try? await center.add(request)
    }
    #endif
}
