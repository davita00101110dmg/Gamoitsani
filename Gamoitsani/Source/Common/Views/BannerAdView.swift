//
//  BannerAdView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 01/11/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//


import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = AppConstants.AdMob.bannerAdId
        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}