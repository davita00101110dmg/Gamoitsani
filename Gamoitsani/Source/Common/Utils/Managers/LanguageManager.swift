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
    case german = "de"
    case spanish = "es"
    case french = "fr"
    case japanese = "ja"
    case russian = "ru"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .georgian: return "ქართული"
        case .ukrainian: return "Українська"
        case .turkish: return "Türkçe"
        case .armenian: return "Հայերեն"
        case .azerbaijani: return "Azərbaycanca"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .french: return "Français"
        case .japanese: return "日本語"
        case .russian: return "Русский"
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
        case .german: return "🇩🇪"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .japanese: return "🇯🇵"
        case .russian: return "🇷🇺"
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
        let languageCode = AppSettings.appLanguage
        if let language = Language(rawValue: languageCode) {
            currentLanguage = language
        } else {
            currentLanguage = .georgian
        }
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        AppSettings.appLanguage = language.rawValue
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
}
