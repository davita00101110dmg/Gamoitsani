//
//  RemoveAdsOffer.swift
//  GamoitsaniAds
//
import Foundation

/// Everything that decides whether the remove-ads card may appear on the setup screen.
///
/// Persisted, unlike most of `AdState`: the whole point is that it remembers being turned
/// down. `Codable` so the app can store it whole rather than as loose keys that drift.
public struct RemoveAdsOfferState: Sendable, Equatable, Codable {
    /// Full-screen ads this install has actually shown.
    ///
    /// Interstitials and app-opens, not banners. The card is earned by interruption, and a
    /// banner is not one — it sits there whether or not anybody minds it.
    public var fullScreenAdsSeen: Int

    /// How many times the card has been dismissed.
    public var dismissals: Int

    /// When it was last dismissed, which starts the quiet period.
    public var lastDismissedAt: Date?

    /// Bought. Nothing is ever offered again.
    public var adsRemoved: Bool

    public init(
        fullScreenAdsSeen: Int = 0,
        dismissals: Int = 0,
        lastDismissedAt: Date? = nil,
        adsRemoved: Bool = false
    ) {
        self.fullScreenAdsSeen = fullScreenAdsSeen
        self.dismissals = dismissals
        self.lastDismissedAt = lastDismissedAt
        self.adsRemoved = adsRemoved
    }
}

/// When the remove-ads card is allowed on the setup screen.
///
/// The Settings row is not governed by any of this — it is always there, because Restore
/// Purchases has to be findable and somebody who goes looking for the offer should find
/// it. This is only about the card that appears without being asked for.
///
/// Three rules, in the order they matter:
///
/// 1. **Earn in.** Nothing is offered until the player has actually been interrupted. A
///    new player being sold an ad-free upgrade before seeing a single ad is being sold a
///    solution to a problem they do not have yet.
/// 2. **Go quiet.** A dismissal buys a week of silence. Asking again the next launch is
///    what makes an offer feel like a nag.
/// 3. **Give up.** After enough refusals, stop for good. Somebody who has said no three
///    times is not going to say yes the fourth, and they are usually the long-term player
///    who has been around longest.
public struct RemoveAdsOfferPolicy: Sendable, Equatable {

    /// Full-screen ads that must have been seen before the card first appears.
    public var adsBeforeFirstOffer: Int

    /// How long a dismissal buys.
    public var quietPeriodAfterDismissal: TimeInterval

    /// Refusals after which the card never returns.
    public var maximumDismissals: Int

    public init(
        adsBeforeFirstOffer: Int = 3,
        quietPeriodAfterDismissal: TimeInterval = 7 * 24 * 60 * 60,
        maximumDismissals: Int = 3
    ) {
        self.adsBeforeFirstOffer = adsBeforeFirstOffer
        self.quietPeriodAfterDismissal = quietPeriodAfterDismissal
        self.maximumDismissals = maximumDismissals
    }

    /// Every gate removed, for the debug menu.
    public static let unrestricted = RemoveAdsOfferPolicy(
        adsBeforeFirstOffer: 0,
        quietPeriodAfterDismissal: 0,
        maximumDismissals: .max
    )

    /// Whether the card may be shown right now.
    ///
    /// Consent is not checked here and does not need to be. Somebody who refused consent
    /// sees no full-screen ads, so `fullScreenAdsSeen` never climbs and the first rule
    /// never opens — the card stays away without a rule saying so.
    public func allowsOffer(_ state: RemoveAdsOfferState, at now: Date) -> Bool {
        guard !state.adsRemoved else { return false }
        guard state.dismissals < maximumDismissals else { return false }
        guard state.fullScreenAdsSeen >= adsBeforeFirstOffer else { return false }

        if let dismissed = state.lastDismissedAt,
           now.timeIntervalSince(dismissed) < quietPeriodAfterDismissal {
            return false
        }
        return true
    }

    /// Records a refusal. Clamped, so a corrupted or replayed count cannot overflow past
    /// the give-up rule and wrap back into showing the card.
    public func dismissed(_ state: RemoveAdsOfferState, at now: Date) -> RemoveAdsOfferState {
        var result = state
        result.dismissals = min(state.dismissals + 1, maximumDismissals)
        result.lastDismissedAt = now
        return result
    }
}
