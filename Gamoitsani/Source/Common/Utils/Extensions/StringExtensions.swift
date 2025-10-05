//
//  StringExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

extension String {
    static var empty: String { String() }
    static var whitespace: String { " " }
    
    static func localized(_ key: String, tableName: String? = nil, comment: StaticString = "") -> String {
        let languageCode = LanguageManager.shared.currentLanguage.rawValue
        
        guard let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            return String(localized: String.LocalizationValue(key),
                         table: tableName,
                         bundle: .main,
                         comment: comment)
        }
        
        return String(localized: String.LocalizationValue(key),
                     table: tableName,
                     bundle: bundle,
                     comment: comment)
    }
    
    func localized(_ arguments: CVarArg...) -> String {
        let lang = AppSettings.appLanguage 
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: .empty, comment: .empty)
        }

        let localizedString = NSLocalizedString(self, tableName: nil, bundle: bundle, value: .empty, comment: .empty)

        if arguments.isEmpty {
            return localizedString
        } else {
            return String(format: localizedString, arguments: arguments)
        }
    }
    
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
    func removeExtraSpaces() -> String {
        replacingOccurrences(of: AppConstants.Regex.extraWhitespacesAndNewlines, with: String.whitespace, options: .regularExpression, range: nil)
    }
    
}
