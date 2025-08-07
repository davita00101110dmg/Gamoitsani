//
//  AppConstants.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

enum AppConstants {
    
    static let viewTransitionTime: Double = 1
    static let viewAnimationTime: Double = 0.5
    
    static let launchScreen = "LaunchScreen"
    
    static var maxWordsToSaveInCoreData = 20000
    static let appStoreLink = "https://apps.apple.com/ge/app/gamoitsani/id6502697351"
    static let reviewUrlLink = "itms-apps://itunes.apple.com/en/app/id6502697351?action=write-review&mt=8"
    
    static var removeAdsInAppPurchaseProductID: String {
        do {
            return try Configuration.value(for: "REMOVE_ADS_IN_APP_PURCHASE_PRODUCT_ID")
        } catch {
            log(.error, "Error retrieving words collection name: \(error)")
            return .empty
        }
    }

    static var hasRemovedAds: Bool {
        AppSettings.hasRemovedAds
    }
    
    static var shouldShowAdsToUser: Bool {
        AppSettings.hasAdConsent && !hasRemovedAds
    }
    
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
    
    enum SFSymbol {
        static let gear = "gear"
        static let squareAndPencil = "square.and.pencil"
        static let squareAndArrowUp = "square.and.arrow.up"
        static let trash = "trash"
        static let photoStack = "photo.stack"
        static let flagCheckeredTwoCrossed = "flag.checkered.2.crossed"
    }
    
    enum FontType {
        case regular, semiBold, bold
    }
    
    enum Regex {
        static let extraWhitespacesAndNewlines = "[\\s\n]+"
    }
    
    enum AdMob {
        static var bannerAdId: String {
            do {
                return try Configuration.value(for: "BANNER_AD_ID")
            } catch {
                log(.error, "Error retrieving bannerAdId: \(error)")
                return .empty
            }
        }
        
        static var interstitialAdId: String {
            do {
                return try Configuration.value(for: "INTERSTITIAL_AD_ID")
            } catch {
                log(.error, "Error retrieving interstitialAdId: \(error)")
                return .empty
            }
        }
                
        static var appOpenAdId: String {
            do {
                return try Configuration.value(for: "APP_OPEN_AD_ID")
            } catch {
                log(.error, "Error retrieving appOpenAdId: \(error)")
                return .empty
            }
        }
        
        static var testDeviceId: String {
            do {
                return try Configuration.value(for: "ADMOB_TEST_DEVICE_ID")
            } catch {
                log(.error, "Error retrieving testDeviceId: \(error)")
                return .empty
            }
        }
        
        static var umpTestDeviceId: String {
            do {
                return try Configuration.value(for: "UMP_TEST_DEVICE_ID")
            } catch {
                log(.error, "Error retrieving testDeviceId: \(error)")
                return .empty
            }
        }
    }
    
    enum Vungle {
        static var appId: String {
            do {
                return try Configuration.value(for: "VUNGLE_APP_ID")
            } catch {
                log(.error, "Error retrieving appId: \(error)")
                return .empty
            }
        }
    }
    
    enum InMobi {
        static var appId: String {
            do {
                return try Configuration.value(for: "INMOBI_APP_ID")
            } catch {
                log(.error, "Error retrieving appId: \(error)")
                return .empty
            }
        }
    }
    
    enum Chartboost {
        static var appId: String {
            do {
                return try Configuration.value(for: "CHARTBOOST_APP_ID")
            } catch {
                log(.error, "Error retrieving appId: \(error)")
                return .empty
            }
        }
        
        static var appSignature: String {
            do {
                return try Configuration.value(for: "CHARTBOOST_APP_SIGNATURE")
            } catch {
                log(.error, "Error retrieving appId: \(error)")
                return .empty
            }
        }
    }
    
    enum Firebase {
        
        enum Fields {
            static let baseWord = "base_word"
            static let language = "language"
            static let lastUpdated = "last_updated"
            static let categories = "categories"
            static let translations = "translations"
            static let reviewStats = "review_stats"
            static let positiveCount = "positive_count"
            static let negativeCount = "negative_count"
            static let totalReviews = "total_reviews"
            static let qualityScore = "quality_score"
            static let lastReviewed = "last_reviewed"
            static let reviewedBy = "reviewed_by"
        }
        
        static var wordsCollectionName: String {
            do {
                return try Configuration.value(for: "WORDS_COLLECTION_NAME")
            } catch {
                log(.error, "Error retrieving words collection name: \(error)")
                return .empty
            }
        }
        
        static var suggestedWordsCollectionName: String {
            do {
                return try Configuration.value(for: "SUGGESTED_WORDS_COLLECTION_NAME")
            } catch {
                log(.error, "Error retrieving suggested words collection name: \(error)")
                return .empty
            }
        }
    }
    
    enum Meta {
        static var appId: String {
            do {
                return try Configuration.value(for: "META_APP_ID")
            } catch {
                log(.error, "Error retrieving metaAppId: \(error)")
                return .empty
            }
        }
        
        static var clientToken: String {
            do {
                return try Configuration.value(for: "META_CLIENT_TOKEN")
            } catch {
                log(.error, "Error retrieving metaClientToken: \(error)")
                return .empty
            }
        }
    }
    
    enum Notifications {
        static let weeklyNotificationIdentifier = "WeeklyNotification"
        
        static let notificationTitles: [String] = [
            "Guess a Word!",
            "Play Gamoitsani!",
            "New Words!",
        ]
            
        static let notificationMessages: [String] = [
            "Join the fun now.",
            "Challenge awaits.",
            "Try them out.",
        ]
    }
}
