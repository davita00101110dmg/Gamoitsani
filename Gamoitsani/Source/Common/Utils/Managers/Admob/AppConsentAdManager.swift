//
//  AdManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 21/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMobileAds
import UserMessagingPlatform
import VungleAdsSDK
import InMobiSDK
import FBAudienceNetwork
import ChartboostSDK
import UnityAds

final class AppConsentAdManager: NSObject, CLLocationManagerDelegate {
    static let shared = AppConsentAdManager()

    var shouldShowPrivacySettingsButton: Bool {
        UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
    }
    
    var isInEEARegion: Bool {
        let locale = Locale.current
        let countryCode = locale.region?.identifier.uppercased() ?? ""
        return EEACountries.contains(countryCode)
    }
    
    private var isMobileAdsStartCalled = false
    private var locationManager: CLLocationManager?
    
    private let EEACountries = [
        "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
        "DE", "GR", "HU", "IS", "IE", "IT", "LV", "LI", "LT", "LU",
        "MT", "NL", "NO", "PL", "PT", "RO", "SK", "SI", "ES", "SE",
        "GB"
    ]


    private override init() {
        super.init()
        setupLocationManager()
    }

    func requestAdConsent(from viewController: UIViewController?) {
        guard let viewController else { return }
        
        // Initialize ad SDKs first
        initializeAdSDKs()

        // Configure Google UMP
        let requestParameters = UMPRequestParameters()
        let debugSettings = UMPDebugSettings()
        debugSettings.geography = .EEA
        debugSettings.testDeviceIdentifiers = [AppConstants.AdMob.umpTestDeviceId]
        requestParameters.debugSettings = debugSettings
        
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: requestParameters) { [weak self]
            requestConsentError in
            guard let self else { return }
            
            if let consentError = requestConsentError {
                log(.info, "Error requesting consent info: \(consentError.localizedDescription)")
                return
            }
            
            UMPConsentForm.loadAndPresentIfRequired(from: viewController) { loadAndPresentError in
                if let consentError = loadAndPresentError {
                    log(.info, "Error loading or presenting consent form: \(consentError.localizedDescription)")
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
        
        self.updateInMobiConsent()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }

    
    private func initializeAdSDKs() {
        // Initialize Vungle
        VungleAds.initWithAppId(AppConstants.Vungle.appId) { error in
            if let error = error {
                log(.error, "Vungle SDK initialization failed: \(error)")
            } else {
                log(.info, "Vungle SDK initialization complete")
            }
        }
        
        VunglePrivacySettings.setGDPRStatus(isInEEARegion)
        VunglePrivacySettings.setGDPRMessageVersion("v1.0.0")
        VunglePrivacySettings.setCCPAStatus(true)

        // Initialize InMobi with debug settings
        IMSdk.setLogLevel(IMSDKLogLevel.debug)
        IMUnifiedIdService.enableDebugMode(true)
        
        // Meta
        FBAdSettings.setAdvertiserTrackingEnabled(true)
        
        // Chartboost
        let gdprConsent = CHBDataUseConsent.GDPR(CHBDataUseConsent.GDPR.Consent.nonBehavioral)
        let ccpaConsent = CHBDataUseConsent.CCPA(CHBDataUseConsent.CCPA.Consent.optInSale)
        
        Chartboost.addDataUseConsent(gdprConsent)
        Chartboost.addDataUseConsent(ccpaConsent)
        
        Chartboost.start(withAppID: AppConstants.Chartboost.appId,
                         appSignature: AppConstants.Chartboost.appSignature) { _ in

        }
        
        // UnityAds
        let gdprMetaData = UADSMetaData()
        let ccpaMetaData = UADSMetaData()
        gdprMetaData.set("gdpr.consent", value: true)
        ccpaMetaData.set("privacy.consent", value: true)
        gdprMetaData.commit()
    }
    
    func presentPrivacySettings(from viewController: UIViewController?) {
        guard let viewController else { return }
        UMPConsentForm.presentPrivacyOptionsForm(from: viewController) { [weak self] error in
            if let error = error {
                log(.error, "Privacy form error: \(error.localizedDescription)")
                return
            }
            self?.updateInMobiConsent()
        }
    }
    
    private func configureInMobiConsent() {
        let consentDictionary: [String: String] = [
            IMCommonConstants.IM_GDPR_CONSENT_AVAILABLE: "true",
            IMCommonConstants.IM_GDPR_CONSENT_IAB: "BOEFEAyOEFEAyAHABDENAI4AAAB9vABAASA",
            IMCommonConstants.IM_PARTNER_GDPR_APPLIES: isInEEARegion ? "1" : "0",
            IMCommonConstants.IM_SUBJECT_TO_GDPR: isInEEARegion ? "1" : "0"
        ]
        
        IMSdk.initWithAccountID(AppConstants.InMobi.appId,
                              consentDictionary: consentDictionary) { error in
            if let error = error {
                log(.error, "InMobi initialization error: \(error.localizedDescription)")
            } else {
                log(.info, "InMobi SDK initialized successfully")
            }
        }
    }

    private func updateInMobiConsent() {
        let hasConsent = UMPConsentInformation.sharedInstance.canRequestAds
        
        let updatedConsent: [String: String] = [
            IMCommonConstants.IM_GDPR_CONSENT_AVAILABLE: "true",
            IMCommonConstants.IM_GDPR_CONSENT_IAB: hasConsent ? "BOEFEAyOEFEAyAHABDENAI4AAAB9vABAASA" : "",
            IMCommonConstants.IM_PARTNER_GDPR_APPLIES: isInEEARegion ? "1" : "0",
            IMCommonConstants.IM_SUBJECT_TO_GDPR: isInEEARegion ? "1" : "0"
        ]
        
        IMSdk.updateGDPRConsent(updatedConsent)
    }
    
    private func startMobileAdsSDK() {
        guard !isMobileAdsStartCalled else { return }
        
        isMobileAdsStartCalled = true
        
        configureInMobiConsent()
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["d09f1879f31c3d3f0f5bc65a61232a68"]
        UserDefaults.hasAdConsent = true
    }
}

// MARK: - CLLocationManagerDelegate
extension AppConsentAdManager {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let clLocation = locations.last {
            IMSdk.setLocation(clLocation)
            log(.info, "Location updated for InMobi")
        }
        locationManager?.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log(.error, "Location manager error: \(error.localizedDescription)")
    }

}
