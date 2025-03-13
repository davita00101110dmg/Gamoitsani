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
    private var bannerView: BannerView?
    
    private override init() {
        super.init()
    }
    
    func prepareBannerView() -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = AppConstants.AdMob.bannerAdId
        bannerView.delegate = self
        self.bannerView = bannerView
        loadAd()
        return bannerView
    }
    
    private func loadAd() {
        guard AppConstants.shouldShowAdsToUser else { return }
        bannerView?.load(Request())
    }
    
    func cleanup() {
        DispatchQueue.main.async { [weak self] in
            self?.bannerView?.delegate = nil
            self?.bannerView = nil
            withAnimation(.smooth(duration: 0.3)) {
                self?.isAdLoaded = false
            }
        }
    }
}

// MARK: - GADBannerViewDelegate Methods
extension BannerAdManager: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        log(.info, "Loaded ad")
        withAnimation(.smooth(duration: 0.3)) {
            isAdLoaded = true
        }
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        log(.error, "Failed to load - \(error.localizedDescription)")
        withAnimation(.bouncy(duration: 0.3)) {
            isAdLoaded = false
        }
    }
}
