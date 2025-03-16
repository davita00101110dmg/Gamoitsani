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
    
    private var interstitialAd: InterstitialAd?
    
    private override init() {
        super.init()
    }
    
    override func loadAd() async {
        if isLoadingAd, !AppConstants.shouldShowAdsToUser {
            return
        }
        
        isLoadingAd = true
        
        do {
            interstitialAd = try await InterstitialAd.load(with: AppConstants.AdMob.interstitialAdId, request: Request())
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
        
        interstitialAd.present(from: nil)
#endif
    }
}

extension InterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialAd = nil
        isShowingAd = false

        Task {
            await loadAd()
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitialAd = nil
        isShowingAd = false
        
        Task {
            await loadAd()
        }
    }
}
