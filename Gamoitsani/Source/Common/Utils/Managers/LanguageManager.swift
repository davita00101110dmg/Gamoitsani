//
//  LanguageManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/09/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

enum Language: String, CaseIterable {
    case english = "en"
    case georgian = "ka"
    case ukrainian = "uk"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .georgian: return "ქართული"
        case .ukrainian: return "Ukrainian"
        }
    }
    
    var flagEmoji: String {
        switch self {
        case .english: return "🇺🇸"
        case .georgian: return "🇬🇪"
        case .ukrainian: return "🇺🇦"
        }
    }
}

final class LanguageManager {
    static let shared = LanguageManager()
    
    var isAppInGeorgian: Bool {
        return currentLanguage == .georgian
    }
    
    var isAppInUkrainian: Bool {
        return currentLanguage == .ukrainian
    }
    
    @Published private(set) var currentLanguage: Language
    
    private init() {
        if let languageCode = UserDefaults.standard.string(forKey: UserDefaults.Keys.APP_LANGUAGE),
           let language = Language(rawValue: languageCode) {
            currentLanguage = language
        } else {
            currentLanguage = .english
        }
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: UserDefaults.Keys.APP_LANGUAGE)
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
}
