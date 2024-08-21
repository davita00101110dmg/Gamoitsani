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
    
}
