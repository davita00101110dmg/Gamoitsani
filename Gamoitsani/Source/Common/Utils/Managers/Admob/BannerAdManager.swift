//
//  BannerAdManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import GoogleMobileAds

final class BannerAdManager: NSObject, ObservableObject {
    static let shared = BannerAdManager()
    
    @Published private(set) var isAdLoaded = false
    private var bannerView: GADBannerView?
    
    private override init() {
        super.init()
    }
    
    func prepareBannerView() -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = AppConstants.AdMob.bannerAdId
        bannerView.delegate = self
        self.bannerView = bannerView
        loadAd()
        return bannerView
    }
    
    private func loadAd() {
        guard AppConstants.shouldShowAdsToUser else { return }
        bannerView?.load(GADRequest())
    }
    
    func cleanup() {
        DispatchQueue.main.async { [weak self] in
            self?.bannerView?.delegate = nil
            self?.bannerView = nil
            self?.isAdLoaded = false
        }
    }
}

// MARK: - GADBannerViewDelegate Methods
extension BannerAdManager: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        dump("Loaded ad")
        withAnimation(.smooth(duration: 0.3)) {
            isAdLoaded = true
        }
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        dump("Failed to load - \(error.localizedDescription)")
        withAnimation(.bouncy(duration: 0.3)) {
            isAdLoaded = false
        }
    }
}
