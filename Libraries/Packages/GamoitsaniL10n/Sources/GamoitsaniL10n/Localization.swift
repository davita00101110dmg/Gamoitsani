//
//  Localization.swift
//  GamoitsaniL10n
//
import Foundation
import Observation

/// The languages the app ships.
public enum AppLanguage: String, CaseIterable, Sendable, Hashable, Identifiable {
    case georgian = "ka"
    case english = "en"
    case ukrainian = "uk"
    case turkish = "tr"
    case armenian = "hy"
    case azerbaijani = "az"
    case german = "de"
    case spanish = "es"
    case french = "fr"
    case japanese = "ja"
    case russian = "ru"

    public var id: String { rawValue }

    /// The language's name in itself — the only sensible way to label a language picker,
    /// since someone looking for Georgian is looking for "ქართული".
    public var endonym: String {
        switch self {
        case .georgian: "ქართული"
        case .english: "English"
        case .ukrainian: "Українська"
        case .turkish: "Türkçe"
        case .armenian: "Հայերեն"
        case .azerbaijani: "Azərbaycanca"
        case .german: "Deutsch"
        case .spanish: "Español"
        case .french: "Français"
        case .japanese: "日本語"
        case .russian: "Русский"
        }
    }

    public var flag: String {
        switch self {
        case .georgian: "🇬🇪"
        case .english: "🇺🇸"
        case .ukrainian: "🇺🇦"
        case .turkish: "🇹🇷"
        case .armenian: "🇦🇲"
        case .azerbaijani: "🇦🇿"
        case .german: "🇩🇪"
        case .spanish: "🇪🇸"
        case .french: "🇫🇷"
        case .japanese: "🇯🇵"
        case .russian: "🇷🇺"
        }
    }

    /// Falls back to Georgian, which is the app's primary audience.
    public static var systemDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first.map { Locale(identifier: $0).language.languageCode?.identifier } ?? nil
        return preferred.flatMap(AppLanguage.init(rawValue:)) ?? .georgian
    }
}

/// Resolves strings in the currently selected language.
@MainActor
@Observable
public final class Localization {

    public var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "app.language"

    /// The persisted choice, or the system default. Exposed because types constructed
    public static var storedLanguage: AppLanguage {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let language = AppLanguage(rawValue: raw) {
            return language
        }
        return .systemDefault
    }

    public init(language: AppLanguage? = nil) {
        if let language {
            self.language = language
        } else {
            self.language = Self.storedLanguage
        }
    }

    /// `l10n("home.title")` at the call site.
    public func callAsFunction(_ key: String) -> String {
        L10n.string(key, language: language)
    }
}

/// Static resolution, for the rare place with no environment — previews, tests.
public enum L10n {

    /// One `Bundle` per language, resolved once.
    ///
    /// `String(localized:bundle:locale:)` cannot do this — its `locale:` governs number
    /// and date formatting, not which `.lproj` is read.
    private static let bundles: [AppLanguage: Bundle] = {
        var result: [AppLanguage: Bundle] = [:]
        for language in AppLanguage.allCases {
            if let path = Bundle.module.path(forResource: language.rawValue, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                result[language] = bundle
            }
        }
        return result
    }()

    /// Resolves a key in a specific language.
    public static func string(_ key: String, language: AppLanguage) -> String {
        let bundle = bundles[language] ?? .module
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// Resolves against the system locale.
    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module)
    }
}
