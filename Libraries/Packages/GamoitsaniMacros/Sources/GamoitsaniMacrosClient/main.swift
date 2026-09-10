//
//  main.swift
//  GamoitsaniMacros
//

import Foundation
import GamoitsaniMacros

// Example usage
@UserDefault("APP_LANGUAGE", defaultValue: "en")
var appLanguage: String

@UserDefault("HAS_REMOVED_ADS", defaultValue: false)
var hasRemovedAds: Bool

print("Current app language: \(appLanguage)")
appLanguage = "ka"
print("Updated app language: \(appLanguage)")

print("Has removed ads: \(hasRemovedAds)")
hasRemovedAds = true
print("Updated has removed ads: \(hasRemovedAds)")
