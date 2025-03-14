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
    case turkish = "tr"
    case armenian = "hy"
    case azerbaijani = "az"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .georgian: return "ქართული"
        case .ukrainian: return "Ukrainian"
        case .turkish: return "Turkish"
        case .armenian: return "Armenian"
        case .azerbaijani: return "Azerbaijani"
        }
    }
    
    var flagEmoji: String {
        switch self {
        case .english: return "🇺🇸"
        case .georgian: return "🇬🇪"
        case .ukrainian: return "🇺🇦"
        case .turkish: return "🇹🇷"
        case .armenian: return "🇦🇲"
        case .azerbaijani: return "🇦🇿"
        }
    }
}

final class LanguageManager {
    static let shared = LanguageManager()
    
    var isAppInGeorgian: Bool {
        return currentLanguage == .georgian
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
