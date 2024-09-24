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
    
    func localized(_ arguments: CVarArg...) -> String {
        guard let lang = UserDefaults.appLanguage else {
            UserDefaults.appLanguage = Language.english.rawValue
            return self
        }
        
        let path = Bundle.main.path(forResource: lang, ofType: "lproj")
        let bundle = Bundle(path: path!)

        let localizedString = NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
        
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
