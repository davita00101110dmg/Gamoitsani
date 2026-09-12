//
//  AdMobAds.swift
//  Gamoitsani
//
import AppTrackingTransparency
import GoogleMobileAds
import Observation
import SwiftUI
import UserMessagingPlatform
import GamoitsaniAds

/// The real ad service. The only file in the app that talks to an ad SDK.
///
/// `AdPolicy` decides whether a format may show and is tested separately; everything here
/// is the part that cannot be tested without a network — loading, presenting, and the
/// consent flow.
@MainActor
@Observable
final class AdMobAds: AdServing {

    /// Read each time rather than stored, so flipping the debug switch takes effect
    /// without relaunching.
    private var policy: AdPolicy {
        #if DEBUG
        UserDefaults.standard.bool(forKey: AdDebug.instantKey) ? .unrestricted : AdPolicy()
        #else
        AdPolicy()
        #endif
    }

    /// Same treatment as `policy`: read each time, so the debug switch that removes the
    /// ad caps removes the offer's gates too and the card can be seen on demand.
    private var offerPolicy: RemoveAdsOfferPolicy {
        #if DEBUG
        UserDefaults.standard.bool(forKey: AdDebug.instantKey)
            ? .unrestricted
            : RemoveAdsOfferPolicy()
        #else
        RemoveAdsOfferPolicy()
        #endif
    }

    private var state: AdState
    private var offer: RemoveAdsOfferState
    private var didStart = false

    @ObservationIgnored private var interstitial: InterstitialAd?
    @ObservationIgnored private var appOpen: AppOpenAd?
    @ObservationIgnored private var rewarded: RewardedAd?

    private(set) var isReady = false

    var isBannerAllowed: Bool {
        isReady && !AdUnits.banner.isEmpty && policy.allowsBanner(state, at: .now)
    }

    /// Deliberately not persisted across launches. A cold start has no ad loaded and no
    /// way to know one will fill, so reserving the space then would show an empty strip
    /// on the first screen of every session.
    private(set) var lastBannerHeight: Double = 0

    func setLastBannerHeight(_ height: Double) {
        guard height != lastBannerHeight else { return }
        lastBannerHeight = height
    }

    var isRemoveAdsOfferAllowed: Bool {
        var current = offer
        // One source of truth for the purchase. The offer store persists counters only —
        // duplicating `adsRemoved` is how the two copies end up disagreeing.
        current.adsRemoved = state.adsRemoved
        return offerPolicy.allowsOffer(current, at: .now)
    }

    init() {
        state = AdStateStore.load()
        offer = RemoveAdsOfferStore.load()
    }

    // MARK: - Lifecycle

    func start() async {
        guard !didStart else { return }
        didStart = true

        #if DEBUG
        if AdDebug.skipsConsent {
            state.hasConsent = true
            await MobileAds.shared.start()
            isReady = true
            preload()
            return
        }
        #endif

        await requestConsent()
        state.hasConsent = ConsentInformation.shared.canRequestAds
        AdStateStore.save(state)

        guard state.hasConsent else {
            // Consent refused or unavailable. Nothing is requested, and no SDK is started.
            isReady = true
            return
        }

        // Only after consent: ATT governs the identifier, not whether ads may be served.
        await requestTracking()

        if !AdUnits.testDevice.isEmpty {
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [AdUnits.testDevice]
        }
        await MobileAds.shared.start()

        isReady = true
        preload()
    }

    /// Loads the consent form when one is required. Errors are swallowed on purpose: a
    /// consent service that is down must not stop the game from being played.
    private func requestConsent() async {
        let parameters = RequestParameters()
        if !AdUnits.umpTestDevice.isEmpty {
            // Qualified: the app's own DebugSettings — the shake menu — shadows this one,
            // and only in DEBUG builds, so the unqualified spelling compiled in Release.
            let debug = UserMessagingPlatform.DebugSettings()
            debug.testDeviceIdentifiers = [AdUnits.umpTestDevice]
            parameters.debugSettings = debug
        }

        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { _ in
                continuation.resume()
            }
        }

        guard let root = Self.rootViewController else { return }
        await withCheckedContinuation { continuation in
            ConsentForm.loadAndPresentIfRequired(from: root) { _ in
                continuation.resume()
            }
        }
    }

    /// Asks only once iOS says the prompt is available; asking earlier silently fails.
    private func requestTracking() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    func presentPrivacyOptions() async {
        guard let root = Self.rootViewController else { return }
        await withCheckedContinuation { continuation in
            ConsentForm.presentPrivacyOptionsForm(from: root) { _ in
                continuation.resume()
            }
        }
        state.hasConsent = ConsentInformation.shared.canRequestAds
        AdStateStore.save(state)
    }

    // MARK: - Counting

    func setAdsRemoved(_ removed: Bool) {
        guard state.adsRemoved != removed else { return }
        state.adsRemoved = removed
        AdStateStore.save(state)
        // Anything already in hand would otherwise still present once.
        if removed {
            interstitial = nil
            appOpen = nil
            rewarded = nil
        } else {
            preload()
        }
    }

    func gameFinished() {
        state.gamesFinished += 1
        AdStateStore.save(state)
    }

    func setMidGame(_ isMidGame: Bool) {
        state.isMidGame = isMidGame
    }

    /// One more interruption on the record. Only called where an ad actually presented —
    /// counting attempts would earn the offer on a run of no-fills nobody ever saw.
    private func fullScreenAdShown() {
        offer.fullScreenAdsSeen += 1
        RemoveAdsOfferStore.save(offer)
    }

    func removeAdsOfferDismissed() {
        offer = offerPolicy.dismissed(offer, at: .now)
        RemoveAdsOfferStore.save(offer)
    }

    // MARK: - Formats

    func showInterstitialIfAllowed() async -> Bool {
        guard policy.allowsInterstitial(state, at: .now), let ad = interstitial else {
            preload()
            return false
        }
        guard let root = Self.rootViewController else { return false }

        interstitial = nil
        ad.present(from: root)

        state.lastInterstitialAt = .now
        state.gamesAtLastInterstitial = state.gamesFinished
        AdStateStore.save(state)
        fullScreenAdShown()

        loadInterstitial()
        return true
    }

    func showAppOpenIfAllowed() async -> Bool {
        guard policy.allowsAppOpen(state, at: .now), let ad = appOpen else {
            preload()
            return false
        }
        guard let root = Self.rootViewController else { return false }

        appOpen = nil
        ad.present(from: root)

        state.lastAppOpenAt = .now
        AdStateStore.save(state)
        fullScreenAdShown()

        loadAppOpen()
        return true
    }

    func showRewarded() async -> RewardOutcome {
        guard policy.allowsRewarded(state), let ad = rewarded,
              let root = Self.rootViewController
        else { return .none }

        rewarded = nil
        var earned = false
        ad.present(from: root) { earned = true }
        loadRewarded()

        guard earned else { return .none }

        // Extends rather than replaces, so watching two in a row is not a downgrade.
        let from = max(state.adFreeUntil ?? .now, .now)
        state.adFreeUntil = from.addingTimeInterval(policy.rewardDuration)
        AdStateStore.save(state)
        return .earned
    }

    #if DEBUG
    var debugSummary: [(String, String)] {
        [
            ("consent", state.hasConsent ? "granted" : "no"),
            ("sdk", isReady ? "ready" : "starting"),
            ("games", "\(state.gamesFinished)"),
            ("interstitial", interstitial == nil ? "not loaded" : "loaded"),
            ("app open", appOpen == nil ? "not loaded" : "loaded"),
            ("rewarded", rewarded == nil ? "not loaded" : "loaded"),
            ("allowed now", policy.allowsInterstitial(state, at: .now) ? "yes" : "no"),
            ("ads seen", "\(offer.fullScreenAdsSeen)"),
            ("offer refused", "\(offer.dismissals) / \(offerPolicy.maximumDismissals)"),
            ("offer showing", isRemoveAdsOfferAllowed ? "yes" : "no"),
        ]
    }

    /// Back to never having seen an ad or refused the card.
    func debugResetRemoveAdsOffer() {
        offer = RemoveAdsOfferState()
        RemoveAdsOfferStore.save(offer)
    }

    func debugShowInterstitial() async -> Bool {
        guard let ad = interstitial, let root = Self.rootViewController else {
            preload()
            return false
        }
        interstitial = nil
        ad.present(from: root)
        loadInterstitial()
        return true
    }

    func debugShowAppOpen() async -> Bool {
        guard let ad = appOpen, let root = Self.rootViewController else {
            preload()
            return false
        }
        appOpen = nil
        ad.present(from: root)
        loadAppOpen()
        return true
    }

    func debugResetCadence() {
        state.gamesFinished = 0
        state.gamesAtLastInterstitial = nil
        state.lastInterstitialAt = nil
        state.lastAppOpenAt = nil
        state.adFreeUntil = nil
        AdStateStore.save(state)
    }
    #endif

    // MARK: - Loading

    private func preload() {
        guard isReady, state.hasConsent, !state.adsRemoved else { return }
        loadInterstitial()
        loadAppOpen()
        loadRewarded()
    }

    private func loadInterstitial() {
        guard interstitial == nil, !AdUnits.interstitial.isEmpty else { return }
        Task {
            interstitial = try? await InterstitialAd.load(with: AdUnits.interstitial, request: Request())
        }
    }

    private func loadAppOpen() {
        guard appOpen == nil, !AdUnits.appOpen.isEmpty else { return }
        Task {
            appOpen = try? await AppOpenAd.load(with: AdUnits.appOpen, request: Request())
        }
    }

    private func loadRewarded() {
        guard rewarded == nil, !AdUnits.rewarded.isEmpty else { return }
        Task {
            rewarded = try? await RewardedAd.load(with: AdUnits.rewarded, request: Request())
        }
    }

    // MARK: - Presentation

    /// The window's root controller, which every SDK present call needs.
    static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow?
            .rootViewController
    }
}

#if DEBUG
/// Debug-only switch, in UserDefaults so the ad service does not have to know the debug
/// menu exists.
enum AdDebug {
    static let instantKey = "debug.instantAds"
    /// Skips the consent form so a layout can be looked at without tapping through it.
    /// Settable from outside the app, which is how a screenshot gets taken unattended.
    static let skipConsentKey = "debug.skipConsent"

    static var showsAdsInstantly: Bool {
        get { UserDefaults.standard.bool(forKey: instantKey) }
        set { UserDefaults.standard.set(newValue, forKey: instantKey) }
    }

    static var skipsConsent: Bool {
        UserDefaults.standard.bool(forKey: skipConsentKey)
    }
}
#endif

/// Survives launches, so the cadence is not reset by quitting the app.
private enum AdStateStore {
    private static let key = "ads.state"

    static func load() -> AdState {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode(Stored.self, from: data)
        else { return AdState() }

        return AdState(
            gamesFinished: stored.gamesFinished,
            gamesAtLastInterstitial: stored.gamesAtLastInterstitial,
            lastInterstitialAt: stored.lastInterstitialAt,
            lastAppOpenAt: stored.lastAppOpenAt,
            adsRemoved: stored.adsRemoved,
            adFreeUntil: stored.adFreeUntil
        )
    }

    static func save(_ state: AdState) {
        let stored = Stored(
            gamesFinished: state.gamesFinished,
            gamesAtLastInterstitial: state.gamesAtLastInterstitial,
            lastInterstitialAt: state.lastInterstitialAt,
            lastAppOpenAt: state.lastAppOpenAt,
            adsRemoved: state.adsRemoved,
            adFreeUntil: state.adFreeUntil
        )
        guard let data = try? JSONEncoder().encode(stored) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// `hasConsent` is deliberately absent: it is re-read from the SDK on every launch, so
    /// a consent change made outside the app is never overridden by a stale copy.
    private struct Stored: Codable {
        var gamesFinished: Int
        var gamesAtLastInterstitial: Int?
        var lastInterstitialAt: Date?
        var lastAppOpenAt: Date?
        var adsRemoved: Bool
        var adFreeUntil: Date?
    }
}

/// How many ads have been sat through, and how often the offer has been turned down.
///
/// Separate from `AdStateStore` because it outlives the ad cadence: "reset the cadence" in
/// the debug menu should hand back a fresh-feeling ad schedule without also un-refusing a
/// purchase the player has already declined three times.
///
/// `RemoveAdsOfferState` is itself `Codable`, so this stores it whole. There is no
/// second `Stored` mirror to drift out of step with it.
private enum RemoveAdsOfferStore {
    private static let key = "ads.removeAdsOffer"

    static func load() -> RemoveAdsOfferState {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode(RemoveAdsOfferState.self, from: data)
        else { return RemoveAdsOfferState() }
        return stored
    }

    static func save(_ state: RemoveAdsOfferState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
