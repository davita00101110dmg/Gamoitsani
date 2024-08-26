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
        if isLoadingAd {
            return
        }
        
        isLoadingAd = true
        
        do {
            interstitialAd = try await GADInterstitialAd.load(withAdUnitID: AppConstants.AdMob.interstitialAdId, request: GADRequest())
            interstitialAd?.fullScreenContentDelegate = self
        } catch {
            print("Failed to load interstitial ad with error: \(error.localizedDescription)")
        }
        isLoadingAd = false
    }
    
    override func showAdIfAvailable() {
        guard let interstitialAd = interstitialAd, !isShowingAd else {
            print("Ad wasn't ready or is already showing.")
            return
        }
        
        isShowingAd = true
        interstitialAd.present(fromRootViewController: nil)
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
