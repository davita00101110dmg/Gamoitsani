//
//  Reminders.swift
//  Gamoitsani
//
import SwiftUI
import Observation
import UserNotifications
import GamoitsaniCore
import GamoitsaniL10n

/// The weekly "come back and play" reminder.
///
/// **English only, deliberately.** The copy lives in the catalogue with an `en` value and
/// is always resolved as English, so a reminder reads the same whatever the in-app
/// language is. Adding the other ten is a translation job, not a code change.
///
/// There is no in-app switch: iOS Settings already owns per-app notification permission,
/// and a second toggle would only be able to disagree with it. Permission is asked once,
/// after a first finished game — v1 asked at first launch, before anyone knew what the app
/// was, which is the surest way to be refused permanently.
@MainActor
@Observable
final class Reminders {

    /// Whether the system has granted permission.
    private(set) var isOn = false

    /// Whether permission has ever been requested. Asking twice is not possible — iOS
    /// shows the sheet once — so this stops the app trying and silently failing.
    private var hasAsked: Bool {
        get { UserDefaults.standard.bool(forKey: Self.askedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.askedKey) }
    }

    @ObservationIgnored private let nudge = WeeklyNudge()
    @ObservationIgnored private let center = UNUserNotificationCenter.current()

    /// How many lines the catalogue holds. Rotation is over these.
    @ObservationIgnored private let copyCount = 4

    init() {}

    /// Refreshes what the system thinks, then tops up the schedule.
    ///
    /// Called at launch. Permission can be revoked in Settings while the app is closed, and
    /// the schedule needs extending long before eight weeks of reminders run out.
    func refresh() async {
        let settings = await center.notificationSettings()
        isOn = settings.authorizationStatus == .authorized
        // Permission can be revoked from iOS Settings while the app is closed. Anything
        // still queued would then never arrive, and would fire the day it is restored.
        guard isOn else {
            cancel()
            return
        }
        await reschedule()
    }

    /// Asks for permission, once, and schedules if it is granted.
    ///
    /// Called after a first finished game: the player has seen what the app is, and the
    /// podium is a pause rather than an interruption.
    func askIfNeeded() async {
        guard !hasAsked else { return }
        hasAsked = true

        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        isOn = granted
        if granted { await reschedule() }
    }

    // MARK: - Scheduling

    private func reschedule() async {
        cancel()

        for occurrence in nudge.occurrences(after: .now, copyCount: copyCount) {
            let content = UNMutableNotificationContent()
            // Always English. Asked for explicitly rather than left to
            // `L10n.string(_:)`, which resolves against the *system* locale and would
            // hand back whatever that happens to be.
            content.title = L10n.string("reminder.title.\(occurrence.copyIndex)", language: .english)
            content.body = L10n.string("reminder.body.\(occurrence.copyIndex)", language: .english)
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

    private static let askedKey = "reminders.asked"
    private static let prefix = "weekly-nudge-"

    #if DEBUG
    var debugSummary: [(String, String)] {
        [("granted", isOn ? "yes" : "no"), ("asked", hasAsked ? "yes" : "no")]
    }

    /// Forgets that permission was ever requested. iOS still only shows its sheet once
    /// per install, so this mostly exercises the scheduling path.
    func debugForgetAsked() {
        UserDefaults.standard.set(false, forKey: Self.askedKey)
    }

    /// Delivers one in a few seconds, so the copy and sound can be seen without waiting
    /// for Saturday.
    func debugFireSoon() async {
        let content = UNMutableNotificationContent()
        content.title = L10n.string("reminder.title.0", language: .english)
        content.body = L10n.string("reminder.body.0", language: .english)
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
