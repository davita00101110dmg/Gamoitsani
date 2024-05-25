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
    }
    
    static var appLanguage: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.APP_LANGUAGE)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.APP_LANGUAGE)
            UserDefaults.standard.synchronize()
        }
    }
}
