//
//  AdManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 21/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import GoogleMobileAds
import UserMessagingPlatform

final class AppConsentAdManager {
    static let shared = AppConsentAdManager()
    
    private var isMobileAdsStartCalled = false
    
    var shouldShowPrivacySettingsButton: Bool {
        UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
    }

    private init() {}

    func requestAdConsent(from viewController: UIViewController?) {
        guard let viewController else { return }
        
        let requestParameters = UMPRequestParameters()
        let debugSettings = UMPDebugSettings()
        debugSettings.geography = .EEA
        debugSettings.testDeviceIdentifiers = [AppConstants.AdMob.testDeviceId]
        requestParameters.debugSettings = debugSettings
        
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: requestParameters) { [weak self]
            requestConsentError in
            guard let self else { return }
            
            if let consentError = requestConsentError {
                print("Error requesting consent info: \(consentError.localizedDescription)")
                return
            }
            
            UMPConsentForm.loadAndPresentIfRequired(from: viewController) { loadAndPresentError in
                if let consentError = loadAndPresentError {
                    print("Error loading or presenting consent form: \(consentError.localizedDescription)")
                    return
                }
                
                if UMPConsentInformation.sharedInstance.canRequestAds {
                    self.startMobileAdsSDK()
                }
            }
        }
        
        
        if UMPConsentInformation.sharedInstance.canRequestAds {
            startMobileAdsSDK()
        }
    }
    
    private func startMobileAdsSDK() {
        guard !isMobileAdsStartCalled else { return }
        
        isMobileAdsStartCalled = true
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [AppConstants.AdMob.testDeviceId]
        UserDefaults.hasAdConsent = true
    }
    
    func presentPrivacySettings(from viewController: UIViewController?) {
        guard let viewController else { return }
        UMPConsentForm.presentPrivacyOptionsForm(from: viewController)
    }
}
