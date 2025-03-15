//
//  AppSettings.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/03/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import GamoitsaniMacros

struct AppSettings {
    static let APP_LANGUAGE = "APP_LANGUAGE"
    static let APP_OPENED_COUNT = "APP_OPENED_COUNT"
    static let HAS_REMOVED_ADS = "HAS_REMOVED_ADS"
    static let IS_APP_FIRST_LAUNCH = "IS_APP_FIRST_LAUNCH"
    static let HAS_AD_CONSENT = "HAS_AD_CONSENT"
    static let LAST_WORD_SYNC_DATE = "LAST_WORD_SYNC_DATE"
    static let LAST_CHALLENGE_SYNC_DATE = "LAST_CHALLENGE_SYNC_DATE"
    static let CACHED_CHALLENGES = "CACHED_CHALLENGES"
    static let DEBUG_QUICK_GAME = "DEBUG_QUICK_GAME"
    
    @UserDefault("APP_LANGUAGE", defaultValue: "ka")
    static var appLanguage: String
    
    @UserDefault("APP_OPENED_COUNT", defaultValue: 0)
    static var appOpenCount: Int
    
    @UserDefault("HAS_REMOVED_ADS", defaultValue: false)
    static var hasRemovedAds: Bool
    
    @UserDefault("IS_APP_FIRST_LAUNCH", defaultValue: true)
    static var isFirstLaunch: Bool
    
    @UserDefault("HAS_AD_CONSENT", defaultValue: false)
    static var hasAdConsent: Bool
    
    @UserDefault("LAST_WORD_SYNC_DATE", defaultValue: 0.0)
    static var lastWordSyncDate: Double
    
    @UserDefault("LAST_CHALLENGE_SYNC_DATE", defaultValue: 0.0)
    static var lastChallengeSyncDate: Double
    
    @UserDefault("CACHED_CHALLENGES", defaultValue: Data())
    static var cachedChallenges: Data
    
    @UserDefault("DEBUG_QUICK_GAME", defaultValue: false)
    static var isQuickGameEnabled: Bool
}
