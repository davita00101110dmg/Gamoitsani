//
//  InterstitialAdManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import GoogleMobileAds

final class InterstitialAdManager: BaseAdManager {
    
    static let shared = InterstitialAdManager()
    
    private var interstitialAd: GADInterstitialAd?
    
    private override init() {
        super.init()
    }
    
    override func loadAd() async {
        if isLoadingAd, !AppConstants.shouldShowAdsToUser {
            return
        }
        
        isLoadingAd = true
        
        do {
            interstitialAd = try await GADInterstitialAd.load(withAdUnitID: AppConstants.AdMob.interstitialAdId, request: GADRequest())
            interstitialAd?.fullScreenContentDelegate = self
        } catch {
            log(.error, "Failed to load interstitial ad with error: \(error.localizedDescription)")
        }
        isLoadingAd = false
    }
    
    override func showAdIfAvailable() {
#if DEBUG
        return
#else
        guard let interstitialAd = interstitialAd, !isShowingAd, AppConstants.shouldShowAdsToUser else {
            log(.debug, "Ad wasn't ready or is already showing.")
            return
        }
        
        isShowingAd = true
        
        // Log ad impression
        AnalyticsManager.shared.logAdEngagement(
            adType: "interstitial",
            placement: "game_over",
            action: "shown"
        )
        
        interstitialAd.present(fromRootViewController: nil)
#endif
    }
}

extension InterstitialAdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        interstitialAd = nil
        isShowingAd = false

        Task {
            await loadAd()
        }
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitialAd = nil
        isShowingAd = false
        
        Task {
            await loadAd()
        }
    }
}
