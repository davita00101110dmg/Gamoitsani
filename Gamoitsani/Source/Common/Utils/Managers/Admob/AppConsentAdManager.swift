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
import IronSource
import MTGSDK
import AppTrackingTransparency

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
       
       if #available(iOS 14.5, *) {
           DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
               ATTrackingManager.requestTrackingAuthorization { status in
                   self?.handleTrackingAuthorization(status, viewController: viewController)
               }
           }
       } else {
           handleTrackingAuthorization(.authorized, viewController: viewController)
       }
    }
    
    private func handleTrackingAuthorization(_ status: ATTrackingManager.AuthorizationStatus, viewController: UIViewController) {
        let isTrackingAllowed = status == .authorized
        initializeAdSDKs(isTrackingAllowed: isTrackingAllowed)
        requestUMPConsent(from: viewController)
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    private func initializeAdSDKs(isTrackingAllowed: Bool) {
        // Vungle
        VungleAds.initWithAppId(AppConstants.Vungle.appId) { error in
            if let error = error {
                log(.error, "Vungle SDK initialization failed: \(error)")
            } else {
                log(.info, "Vungle SDK initialization complete")
            }
        }
        
        VunglePrivacySettings.setGDPRStatus(isInEEARegion && isTrackingAllowed)
        VunglePrivacySettings.setGDPRMessageVersion("v1.0.0")
        VunglePrivacySettings.setCCPAStatus(isTrackingAllowed)
        
        // InMobi
        IMSdk.setLogLevel(IMSDKLogLevel.debug)
        IMUnifiedIdService.enableDebugMode(true)
        IMSdk.setIsAgeRestricted(!isTrackingAllowed)
        
        // Meta
        FBAdSettings.setAdvertiserTrackingEnabled(isTrackingAllowed)
        
        // Chartboost
        let gdprConsent = CHBDataUseConsent.GDPR(isTrackingAllowed ? .behavioral : .nonBehavioral)
        let ccpaConsent = CHBDataUseConsent.CCPA(isTrackingAllowed ? .optInSale : .optOutSale)
        
        Chartboost.addDataUseConsent(gdprConsent)
        Chartboost.addDataUseConsent(ccpaConsent)
        
        Chartboost.start(withAppID: AppConstants.Chartboost.appId,
                         appSignature: AppConstants.Chartboost.appSignature) { _ in }
        
        // UnityAds
        let gdprMetaData = UADSMetaData()
        let ccpaMetaData = UADSMetaData()
        gdprMetaData.set("gdpr.consent", value: isTrackingAllowed)
        ccpaMetaData.set("privacy.consent", value: isTrackingAllowed)
        gdprMetaData.commit()
        
        // IronSource
        IronSource.setConsent(isTrackingAllowed)
        IronSource.setMetaDataWithKey("do_not_sell", value: isTrackingAllowed ? "NO" : "YES")
        
        // Mintegral
        MTGSDK.sharedInstance().consentStatus = isTrackingAllowed
        MTGSDK.sharedInstance().doNotTrackStatus = !isTrackingAllowed
    }
    
    private func requestUMPConsent(from viewController: UIViewController) {
        let requestParameters = UMPRequestParameters()
        let debugSettings = UMPDebugSettings()
        debugSettings.geography = .EEA
        debugSettings.testDeviceIdentifiers = [AppConstants.AdMob.umpTestDeviceId]
        requestParameters.debugSettings = debugSettings
        
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: requestParameters) { [weak self] requestConsentError in
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
        
        updateInMobiConsent()
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
        
        MobileAds.shared.start(completionHandler: nil)
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [AppConstants.AdMob.testDeviceId]
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
