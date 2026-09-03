//
//  AdPolicy.swift
//  GamoitsaniAds
//
import Foundation

/// Everything that decides whether an ad may show right now.
public struct AdState: Sendable, Equatable {
    /// Games finished this install.
    public var gamesFinished: Int
    /// `gamesFinished` when the last interstitial ran.
    public var gamesAtLastInterstitial: Int?
    public var lastInterstitialAt: Date?
    public var lastAppOpenAt: Date?

    /// Bought the ad-free upgrade.
    public var adsRemoved: Bool
    /// Consent resolved *and* granted. Ads are never requested without it.
    public var hasConsent: Bool
    /// Earned by watching a rewarded ad. Nothing interrupts until it passes.
    public var adFreeUntil: Date?

    /// A game is on screen. Deliberately not persisted — it is true only while playing.
    public var isMidGame: Bool

    public init(
        gamesFinished: Int = 0,
        gamesAtLastInterstitial: Int? = nil,
        lastInterstitialAt: Date? = nil,
        lastAppOpenAt: Date? = nil,
        adsRemoved: Bool = false,
        hasConsent: Bool = false,
        adFreeUntil: Date? = nil,
        isMidGame: Bool = false
    ) {
        self.gamesFinished = gamesFinished
        self.gamesAtLastInterstitial = gamesAtLastInterstitial
        self.lastInterstitialAt = lastInterstitialAt
        self.lastAppOpenAt = lastAppOpenAt
        self.adsRemoved = adsRemoved
        self.hasConsent = hasConsent
        self.adFreeUntil = adFreeUntil
        self.isMidGame = isMidGame
    }
}

/// When each format is allowed to interrupt.
///
/// A party game is played in long sittings and put down and picked up constantly, so the
/// natural cadence of every format is far too often. v1 had no cap of any kind: an
/// interstitial after every game and an app-open ad on every return to the foreground.
public struct AdPolicy: Sendable, Equatable {

    /// Let people play before asking for anything.
    public var gamesBeforeFirstInterstitial: Int
    /// Games that must pass between interstitials.
    public var gamesBetweenInterstitials: Int
    /// And a wall-clock floor, so a run of very short games cannot stack them up.
    public var minimumInterstitialInterval: TimeInterval
    /// Returning to the app repeatedly in one session is normal here, and each return is
    /// not an opportunity.
    public var minimumAppOpenInterval: TimeInterval
    /// How long one rewarded ad buys.
    public var rewardDuration: TimeInterval

    public init(
        gamesBeforeFirstInterstitial: Int = 2,
        gamesBetweenInterstitials: Int = 2,
        minimumInterstitialInterval: TimeInterval = 120,
        minimumAppOpenInterval: TimeInterval = 900,
        rewardDuration: TimeInterval = 3600
    ) {
        self.gamesBeforeFirstInterstitial = gamesBeforeFirstInterstitial
        self.gamesBetweenInterstitials = gamesBetweenInterstitials
        self.minimumInterstitialInterval = minimumInterstitialInterval
        self.minimumAppOpenInterval = minimumAppOpenInterval
        self.rewardDuration = rewardDuration
    }

    /// Every cap removed. Debug builds only — it exists so a format can be seen on demand
    /// instead of after two games and a two-minute wait.
    public static let unrestricted = AdPolicy(
        gamesBeforeFirstInterstitial: 0,
        gamesBetweenInterstitials: 0,
        minimumInterstitialInterval: 0,
        minimumAppOpenInterval: 0
    )

    /// Whether any ad at all may be served. Consent and payment outrank every other rule.
    public func allowsAds(_ state: AdState, at now: Date) -> Bool {
        guard state.hasConsent, !state.adsRemoved else { return false }
        if let until = state.adFreeUntil, until > now { return false }
        return true
    }

    public func allowsBanner(_ state: AdState, at now: Date) -> Bool {
        allowsAds(state, at: now)
    }

    public func allowsInterstitial(_ state: AdState, at now: Date) -> Bool {
        guard allowsAds(state, at: now) else { return false }
        guard state.gamesFinished >= gamesBeforeFirstInterstitial else { return false }

        if let last = state.gamesAtLastInterstitial,
           state.gamesFinished - last < gamesBetweenInterstitials {
            return false
        }
        if let at = state.lastInterstitialAt,
           now.timeIntervalSince(at) < minimumInterstitialInterval {
            return false
        }
        return true
    }

    public func allowsAppOpen(_ state: AdState, at now: Date) -> Bool {
        guard allowsAds(state, at: now) else { return false }
        // A party game gets backgrounded mid-round to answer a message. Returning to a
        // full-screen ad while the clock is running is the worst thing this can do, so
        // the rule lives here rather than at the call site where a second trigger could
        // forget it.
        guard !state.isMidGame else { return false }
        // Never as the very first thing someone sees: the app has to be worth opening
        // before it is worth interrupting.
        guard state.gamesFinished >= gamesBeforeFirstInterstitial else { return false }

        if let at = state.lastAppOpenAt,
           now.timeIntervalSince(at) < minimumAppOpenInterval {
            return false
        }
        return true
    }

    /// A rewarded ad is offered even when ads are otherwise silenced — that is the point
    /// of it — but never to someone who has already paid them away.
    public func allowsRewarded(_ state: AdState) -> Bool {
        state.hasConsent && !state.adsRemoved
    }
}
