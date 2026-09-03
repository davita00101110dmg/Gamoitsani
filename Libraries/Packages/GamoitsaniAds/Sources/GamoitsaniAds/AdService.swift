//
//  AdService.swift
//  GamoitsaniAds
//
import Foundation

/// What a rewarded ad bought.
///
/// Not `AdReward`: GoogleMobileAds exports a type by that name, and the collision is only
/// visible from files that import both.
public enum RewardOutcome: Sendable, Equatable {
    /// Watched to the end.
    case earned
    /// Dismissed early, or nothing was available.
    case none
}

/// The app's whole view of advertising.
///
/// Feature code talks to this and never imports an ad SDK, so screens stay previewable
/// and the adapter can be replaced without touching them.
@MainActor
public protocol AdServing: AnyObject {
    /// True once consent has been resolved and the SDKs have started.
    var isReady: Bool { get }
    /// Whether a banner should currently be given space.
    var isBannerAllowed: Bool { get }

    /// Requests consent if needed, then starts the SDKs. Safe to call more than once.
    func start() async

    /// Records a finished game. Interstitial cadence is counted in games, not minutes.
    func gameFinished()

    /// Whether a game is on screen. Nothing full-screen interrupts while it is true.
    func setMidGame(_ isMidGame: Bool)

    /// Shows an interstitial if the policy allows one. Returns whether it did.
    @discardableResult
    func showInterstitialIfAllowed() async -> Bool

    /// Shows an app-open ad if the policy allows one.
    @discardableResult
    func showAppOpenIfAllowed() async -> Bool

    /// Offers a rewarded ad. The reward is an ad-free window.
    func showRewarded() async -> RewardOutcome

    /// Re-opens the consent form so someone can change their mind.
    func presentPrivacyOptions() async

    #if DEBUG
    /// Why an ad is or is not showing, for the debug menu. Testing this from the outside
    /// is guesswork otherwise: nothing appearing looks identical whether consent was
    /// refused, no ad loaded, or the cadence simply said no.
    var debugSummary: [(String, String)] { get }

    /// Ignore the policy entirely and present whatever is loaded.
    func debugShowInterstitial() async -> Bool
    func debugShowAppOpen() async -> Bool

    /// Forgets the cadence, so the next game behaves like a fresh install.
    func debugResetCadence()
    #endif
}

/// Ads, switched off.
///
/// Used by previews and tests, and by any build that should never talk to an ad network.
/// Having a real implementation of "no ads" means call sites never branch on whether ads
/// exist.
@MainActor
public final class NoAds: AdServing {
    /// Nonisolated so it can be an `@Entry` default, which is evaluated off the main actor.
    public nonisolated init() {}

    public var isReady: Bool { true }
    public var isBannerAllowed: Bool { false }

    public func start() async {}
    public func gameFinished() {}
    public func setMidGame(_ isMidGame: Bool) {}
    public func showInterstitialIfAllowed() async -> Bool { false }
    public func showAppOpenIfAllowed() async -> Bool { false }
    public func showRewarded() async -> RewardOutcome { .none }
    public func presentPrivacyOptions() async {}

    #if DEBUG
    public var debugSummary: [(String, String)] { [("ads", "off")] }
    public func debugShowInterstitial() async -> Bool { false }
    public func debugShowAppOpen() async -> Bool { false }
    public func debugResetCadence() {}
    #endif
}
