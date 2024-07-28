//
//  AppConstants.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

enum AppConstants {
    
    static let maxWordsToSaveInCoreData = 20000
    
    static let randomWords = [
        "apple", "banana", "orange", "grape", "pineapple",
        "strawberry", "mango", "watermelon", "kiwi", "blueberry",
        "raspberry", "blackberry", "cherry", "apricot", "peach",
        "nectarine", "plum", "lemon", "lime", "grapefruit",
        "tangerine", "avocado", "papaya", "cantaloupe", "honeydew",
        "lychee", "pomegranate", "fig", "passionfruit", "cranberry",
        "coconut", "pear", "apricot", "banana", "cherry",
        "date", "elderberry", "fig", "grape", "honeydew",
        "imbe", "jackfruit", "kiwifruit", "lemon", "mango",
        "nectarine", "olive", "papaya", "quince", "raspberry"
    ]
    
    static let helperColors = [
        Asset.color11.color,
        Asset.color12.color,
        Asset.color13.color,
        Asset.color14.color,
    ]
    
    enum FontType {
        case regular, semiBold, bold
    }
    
    enum Language {
        case english
        case georgian
        
        var identifier: String {
            switch self {
            case .english: "en"
            case .georgian: "ka"
            }
        }
    }
    
    enum Regex {
        static let extraWhitespacesAndNewlines = "[\\s\n]+"
    }
    
    enum AdMob {
        static var bannerAdId: String {
            do {
                return try Configuration.value(for: "BANNER_AD_ID")
            } catch {
                dump("Error retrieving bannerAdId: \(error)")
                return .empty
            }
        }
        
        static var interstitialAdId: String {
            do {
                return try Configuration.value(for: "BANNER_AD_ID")
            } catch {
                dump("Error retrieving interstitialAdId: \(error)")
                return .empty
            }
        }
    }
    
    enum Firebase {
        static var wordsCollectionName: String {
            do {
                return try Configuration.value(for: "WORDS_COLLECTION_NAME")
            } catch {
                dump("Error retrieving words collection name: \(error)")
                return .empty
            }
        }
        
        static var suggestedWordsCollectionName: String {
            do {
                return try Configuration.value(for: "SUGGESTED_WORDS_COLLECTION_NAME")
            } catch {
                dump("Error retrieving suggested words collection name: \(error)")
                return .empty
            }
        }
        
        static let wordKa = "word_ka"
        static let wordEn = "word_en"
        static let categories = "categories"
        static let definitions = "definitions"
    }
}
