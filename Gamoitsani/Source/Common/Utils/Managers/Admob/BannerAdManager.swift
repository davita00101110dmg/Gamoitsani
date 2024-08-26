//
//  BannerAdManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import GoogleMobileAds

final class BannerAdManager: NSObject, GADBannerViewDelegate {
    static let shared = BannerAdManager()
    
    private var bannerView: GADBannerView?
    private weak var rootViewController: UIViewController?
    
    private override init() {
        super.init()
    }
    
    func setupBannerView(in viewController: UIViewController, with bannerView: GADBannerView) {
        guard AppConstants.shouldShowAdsToUser else {
            bannerView.removeFromSuperview()
            return
        }
        
        self.rootViewController = viewController
        self.bannerView = bannerView
        self.bannerView?.adUnitID = AppConstants.AdMob.bannerAdId
        self.bannerView?.rootViewController = viewController
        self.bannerView?.delegate = self
        
        loadBannerAd()
    }
    
    private func loadBannerAd() {
        bannerView?.load(GADRequest())
    }
    
    // MARK: - GADBannerViewDelegate Methods
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        guard let rootViewController = rootViewController else { return }
        bannerView.frame.origin.y = rootViewController.view.frame.maxY

        UIView.animate(
            withDuration: 1.0,
            delay: 0.0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                bannerView.frame.origin.y = rootViewController.view.frame.maxY - bannerView.frame.size.height - rootViewController.view.safeAreaInsets.bottom
            },
            completion: nil
        )
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        dump("\(#function) \(error.localizedDescription)")
    }
}
