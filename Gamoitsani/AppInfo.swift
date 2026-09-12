//
//  AppInfo.swift
//  Gamoitsani
//
import Foundation

/// Facts about the shipped app that the UI needs to link to.
///
/// The App Store id is the live 1.x listing — 2.0 replaces that app rather than shipping
/// beside it, so ratings and links point at the same record.
enum AppInfo {
    static let appStore = URL(string: "https://apps.apple.com/ge/app/gamoitsani/id6502697351")!

    /// Opens the review sheet directly. `SKStoreReviewController` is for prompts the app
    /// raises on its own — Apple rate-limits it and may show nothing at all, which is the
    /// wrong behaviour for a button someone deliberately pressed.
    static let writeReview = URL(string:
        "itms-apps://itunes.apple.com/app/id6502697351?action=write-review&mt=8")!

    static let feedbackAddress = "davitikhvedelidze26@gmail.com"

    static var feedback: URL? {
        var components = URLComponents(string: "mailto:\(feedbackAddress)")
        components?.queryItems = [URLQueryItem(name: "subject", value: "Gamoitsani \(version) feedback")]
        return components?.url
    }

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}
