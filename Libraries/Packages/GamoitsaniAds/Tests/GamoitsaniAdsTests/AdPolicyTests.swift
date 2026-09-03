//
//  AdPolicyTests.swift
//  GamoitsaniAdsTests
//

import Foundation
import Testing
@testable import GamoitsaniAds

@Suite("Ad policy")
struct AdPolicyTests {

    private let now = Date(timeIntervalSince1970: 1_000_000)
    private let policy = AdPolicy()

    /// Consent is not a preference to weigh against revenue.
    @Test("nothing shows without consent")
    func consentGatesEverything() {
        let state = AdState(gamesFinished: 99, hasConsent: false)
        #expect(!policy.allowsAds(state, at: now))
        #expect(!policy.allowsBanner(state, at: now))
        #expect(!policy.allowsInterstitial(state, at: now))
        #expect(!policy.allowsAppOpen(state, at: now))
        #expect(!policy.allowsRewarded(state))
    }

    /// The bug this mirrors is v1's, where a comma instead of `||` meant interstitials
    /// loaded for people who had paid to remove them.
    @Test("nothing shows once ads are bought away")
    func purchaseGatesEverything() {
        let state = AdState(gamesFinished: 99, adsRemoved: true, hasConsent: true)
        #expect(!policy.allowsAds(state, at: now))
        #expect(!policy.allowsInterstitial(state, at: now))
        #expect(!policy.allowsAppOpen(state, at: now))
        #expect(!policy.allowsBanner(state, at: now))
        #expect(!policy.allowsRewarded(state), "there is nothing left to reward")
    }

    @Test("the first games are never interrupted")
    func warmUp() {
        for played in 0..<policy.gamesBeforeFirstInterstitial {
            let state = AdState(gamesFinished: played, hasConsent: true)
            #expect(!policy.allowsInterstitial(state, at: now), "interrupted after \(played) games")
        }
        let ready = AdState(gamesFinished: policy.gamesBeforeFirstInterstitial, hasConsent: true)
        #expect(policy.allowsInterstitial(ready, at: now))
    }

    @Test("interstitials wait for enough games to pass")
    func gameSpacing() {
        var state = AdState(gamesFinished: 5, gamesAtLastInterstitial: 5, hasConsent: true)
        #expect(!policy.allowsInterstitial(state, at: now))

        state.gamesFinished = 5 + policy.gamesBetweenInterstitials - 1
        #expect(!policy.allowsInterstitial(state, at: now))

        state.gamesFinished = 5 + policy.gamesBetweenInterstitials
        #expect(policy.allowsInterstitial(state, at: now))
    }

    /// Games can be as short as fifteen seconds, so counting games alone is not a cap.
    @Test("a run of short games cannot stack interstitials up")
    func timeFloor() {
        let state = AdState(
            gamesFinished: 20,
            gamesAtLastInterstitial: 10,
            lastInterstitialAt: now.addingTimeInterval(-30),
            hasConsent: true
        )
        #expect(!policy.allowsInterstitial(state, at: now), "game spacing passed but only 30s elapsed")

        let later = now.addingTimeInterval(policy.minimumInterstitialInterval)
        #expect(policy.allowsInterstitial(state, at: later))
    }

    /// A party game is backgrounded and reopened constantly in one sitting.
    @Test("reopening the app repeatedly does not mean repeated ads")
    func appOpenSpacing() {
        var state = AdState(gamesFinished: 10, hasConsent: true)
        #expect(policy.allowsAppOpen(state, at: now))

        state.lastAppOpenAt = now
        #expect(!policy.allowsAppOpen(state, at: now.addingTimeInterval(60)))
        #expect(policy.allowsAppOpen(state, at: now.addingTimeInterval(policy.minimumAppOpenInterval)))
    }

    @Test("a brand new install is never greeted with an app-open ad")
    func appOpenNeedsAHistory() {
        let fresh = AdState(gamesFinished: 0, hasConsent: true)
        #expect(!policy.allowsAppOpen(fresh, at: now))
    }

    @Test("a rewarded ad silences everything for its window")
    func rewardWindow() {
        let state = AdState(
            gamesFinished: 50,
            hasConsent: true,
            adFreeUntil: now.addingTimeInterval(policy.rewardDuration)
        )
        #expect(!policy.allowsInterstitial(state, at: now))
        #expect(!policy.allowsAppOpen(state, at: now))
        #expect(!policy.allowsBanner(state, at: now))

        let after = now.addingTimeInterval(policy.rewardDuration + 1)
        #expect(policy.allowsInterstitial(state, at: after), "the window never reopened")
        #expect(policy.allowsBanner(state, at: after))
    }

    /// Otherwise the one format someone opted into would be unavailable exactly when they
    /// want it — during the quiet window they just earned.
    @Test("a rewarded ad can still be offered inside its own window")
    func rewardedStaysOffered() {
        let state = AdState(hasConsent: true, adFreeUntil: now.addingTimeInterval(600))
        #expect(policy.allowsRewarded(state))
    }
}
