//
//  StringExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        guard let lang = UserDefaults.appLanguage else {
            UserDefaults.appLanguage = AppConstants.Language.english.identifier
            return self
        }
        
        let path = Bundle.main.path(forResource: lang, ofType: "lproj")
        let bundle = Bundle(path: path!)

        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}
