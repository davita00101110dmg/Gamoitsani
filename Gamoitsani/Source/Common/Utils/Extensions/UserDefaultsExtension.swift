//
//  UserDefaultsExtension.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

extension UserDefaults {
    struct Keys {
        static let APP_LANGUAGE = "APP_LANGUAGE"
        static let APP_OPENED_COUNT = "APP_OPENED_COUNT"
        static let HAS_REMOVED_ADS = "HAS_REMOVED_ADS"
        static let IS_APP_FIRST_LAUNCH = "IS_APP_FIRST_LAUNCH"
        static let HAS_AD_CONSENT = "HAS_AD_CONSENT"
        static let LAST_WORD_SYNC_DATE = "LAST_WORD_SYNC_DATE"
        static let DEBUG_QUICK_GAME = "DEBUG_QUICK_GAME"
    }
    
    static var appLanguage: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.APP_LANGUAGE)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.APP_LANGUAGE)
            UserDefaults.standard.synchronize()
        }
    }
    
    static var hasRemovedAds: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.HAS_REMOVED_ADS)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.HAS_REMOVED_ADS)
            UserDefaults.standard.synchronize()
        }
    }
    
    static var isFirstLaunch: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.IS_APP_FIRST_LAUNCH)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.IS_APP_FIRST_LAUNCH)
            UserDefaults.standard.synchronize()
        }
    }
    
    
    static var hasAdConsent: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.HAS_AD_CONSENT)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.HAS_AD_CONSENT)
            UserDefaults.standard.synchronize()
        }
    }
    
    static var lastWordSyncDate: Double {
        get {
            return UserDefaults.standard.double(forKey: Keys.LAST_WORD_SYNC_DATE)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.LAST_WORD_SYNC_DATE)
            UserDefaults.standard.synchronize()
        }
    }
    
    static var isQuickGameEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.DEBUG_QUICK_GAME)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.DEBUG_QUICK_GAME)
            UserDefaults.standard.synchronize()
        }
    }
}
