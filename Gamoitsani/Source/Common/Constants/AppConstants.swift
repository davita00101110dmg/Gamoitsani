//
//  AppConstants.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

enum AppConstants {
    
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
    }
}
