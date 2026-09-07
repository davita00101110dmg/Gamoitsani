//
//  RemoveAdsOfferTests.swift
//  GamoitsaniAdsTests
//

import Foundation
import Testing
@testable import GamoitsaniAds

@Suite("Remove-ads offer")
struct RemoveAdsOfferTests {

    private let now = Date(timeIntervalSince1970: 1_000_000)
    private let policy = RemoveAdsOfferPolicy()

    private var earned: RemoveAdsOfferState {
        RemoveAdsOfferState(fullScreenAdsSeen: policy.adsBeforeFirstOffer)
    }

    @Test("a new player is not sold an upgrade before seeing an ad")
    func earnsIn() {
        for seen in 0..<policy.adsBeforeFirstOffer {
            let state = RemoveAdsOfferState(fullScreenAdsSeen: seen)
            #expect(!policy.allowsOffer(state, at: now), "offered after \(seen) ads")
        }
        #expect(policy.allowsOffer(earned, at: now))
    }

    @Test("nothing is offered once ads are bought away")
    func purchaseEndsIt() {
        var state = earned
        state.adsRemoved = true
        #expect(!policy.allowsOffer(state, at: now))
    }

    /// The rule the whole thing exists for. Three refusals and it is over.
    @Test("it gives up on someone who keeps saying no")
    func givesUp() {
        var state = earned
        var clock = now

        for refusal in 1...policy.maximumDismissals {
            #expect(policy.allowsOffer(state, at: clock), "gone after \(refusal - 1) refusals")
            state = policy.dismissed(state, at: clock)
            clock += policy.quietPeriodAfterDismissal + 1
        }

        #expect(!policy.allowsOffer(state, at: clock))
        // And not merely for another quiet period.
        #expect(!policy.allowsOffer(state, at: clock.addingTimeInterval(10 * 365 * 24 * 3600)))
    }

    @Test("a dismissal buys a week of silence")
    func quietPeriod() {
        let state = policy.dismissed(earned, at: now)

        #expect(!policy.allowsOffer(state, at: now))
        #expect(!policy.allowsOffer(state, at: now + policy.quietPeriodAfterDismissal - 1))
        #expect(policy.allowsOffer(state, at: now + policy.quietPeriodAfterDismissal))
    }

    /// Somebody who refuses consent sees no full-screen ads, so the counter never climbs
    /// and the card never appears. There is no rule for this — it falls out of the first
    /// one, and this test is here so a future change cannot quietly break that.
    @Test("without consent there are no ads to be tired of")
    func noConsentMeansNoOffer() {
        #expect(!policy.allowsOffer(RemoveAdsOfferState(), at: now))
    }

    @Test("a refusal count cannot wrap back into showing the card")
    func dismissalsAreClamped() {
        var state = RemoveAdsOfferState(
            fullScreenAdsSeen: 99,
            dismissals: policy.maximumDismissals + 500
        )
        state = policy.dismissed(state, at: now)

        #expect(state.dismissals == policy.maximumDismissals)
        #expect(!policy.allowsOffer(state, at: now + 10 * 365 * 24 * 3600))
    }

    @Test("the debug policy shows it immediately")
    func unrestricted() {
        let policy = RemoveAdsOfferPolicy.unrestricted
        var state = RemoveAdsOfferState()
        #expect(policy.allowsOffer(state, at: now))

        state = policy.dismissed(state, at: now)
        #expect(policy.allowsOffer(state, at: now), "a dismissal should not silence it")
    }

    /// It is persisted, so it survives an upgrade only if it round-trips.
    @Test("state survives a save and load")
    func codableRoundTrip() throws {
        let state = RemoveAdsOfferState(
            fullScreenAdsSeen: 7,
            dismissals: 2,
            lastDismissedAt: now,
            adsRemoved: false
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(RemoveAdsOfferState.self, from: data)
        #expect(decoded == state)
    }
}
