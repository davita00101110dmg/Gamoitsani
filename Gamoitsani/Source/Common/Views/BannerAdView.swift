//
//  BannerAdView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 01/11/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//


import SwiftUI
import GoogleMobileAds

private struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        BannerAdManager.shared.prepareBannerView()
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        uiView.frame.size = BannerContainerView.adSize
    }
    
    static func dismantleUIView(_ uiView: GADBannerView, coordinator: ()) {
        BannerAdManager.shared.cleanup()
    }
}

struct BannerContainerView: View {
    static let adSize = CGSize(width: 320, height: 50)
    @ObservedObject private var adManager = BannerAdManager.shared
    
    var body: some View {
        BannerAdView()
            .frame(
                width: Self.adSize.width,
                height: adManager.isAdLoaded && AppConstants.shouldShowAdsToUser ? Self.adSize.height : 0
            )
            .clipped()
    }
}
