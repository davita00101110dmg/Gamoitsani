//
//  AppOpenAdManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 21/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import GoogleMobileAds

final class AppOpenAdManager: BaseAdManager {
    static let shared = AppOpenAdManager()
    
    private var appOpenAd: GADAppOpenAd?
    private var loadTime: Date?
    private let fourHoursInSeconds = TimeInterval(3600 * 4)
    
    private override init() {
        super.init()
    }
    
    override func loadAd() async {
        if isLoadingAd || isAdAvailable() {
            return
        }
        
        isLoadingAd = true
        
        do {
            appOpenAd = try await GADAppOpenAd.load(
                withAdUnitID: AppConstants.AdMob.appOpenAdId, request: GADRequest())
            appOpenAd?.fullScreenContentDelegate = self
            loadTime = Date()
        } catch {
            print("App open ad failed to load with error: \(error.localizedDescription)")
        }
        isLoadingAd = false
    }
    
    override func showAdIfAvailable() {
        guard !isShowingAd else { return }

        if !isAdAvailable() {
            Task {
                await loadAd()
            }
            return
        }
        
        if let ad = appOpenAd {
            isShowingAd = true
            ad.present(fromRootViewController: nil)
        }
    }
    
    private func wasLoadTimeLessThanFourHoursAgo() -> Bool {
        guard let loadTime = loadTime else { return false }
        return Date().timeIntervalSince(loadTime) < fourHoursInSeconds
    }
    
    private func isAdAvailable() -> Bool {
        return appOpenAd != nil && wasLoadTimeLessThanFourHoursAgo()
    }
}

extension AppOpenAdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        appOpenAd = nil
        isShowingAd = false

        Task {
            await loadAd()
        }
    }
    
    func ad(
        _ ad: GADFullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        appOpenAd = nil
        isShowingAd = false
        
        Task {
            await loadAd()
        }
    }
}
