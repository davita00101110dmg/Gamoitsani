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
        static let appLanguage = "app_language"
    }
    
    static var appLanguage: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.appLanguage)
        } set {
            UserDefaults.standard.set(newValue, forKey: Keys.appLanguage)
            UserDefaults.standard.synchronize()
        }
    }
}
