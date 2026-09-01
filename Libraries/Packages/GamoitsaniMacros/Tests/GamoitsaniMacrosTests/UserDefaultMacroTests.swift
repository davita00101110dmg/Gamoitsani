//
//  File.swift
//  GamoitsaniMacros
//
//  Created by Daviti Khvedelidze on 15/03/2025.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import GamoitsaniMacrosImpl

final class UserDefaultMacroTests: XCTestCase {
    func testUserDefaultMacroWithString() {
        assertMacroExpansion(
            """
            @UserDefault("APP_LANGUAGE", defaultValue: "en")
            var appLanguage: String
            """,
            expandedSource: """
            var appLanguage: String {
                get {
                    let defaults = UserDefaults.standard
                    let key = "APP_LANGUAGE"
                    if let value = defaults.object(forKey: key) as? String {
                        return value
                    }
                    return "en" as! String
                }
                set {
                    let defaults = UserDefaults.standard
                    let key = "APP_LANGUAGE"
                    defaults.set(newValue, forKey: key)
                    defaults.synchronize()
                }
            }
            """,
            macros: ["UserDefault": UserDefaultMacroImpl.self]
        )
    }
    
    func testUserDefaultMacroWithBool() {
        assertMacroExpansion(
            """
            @UserDefault("HAS_REMOVED_ADS", defaultValue: false)
            var hasRemovedAds: Bool
            """,
            expandedSource: """
            var hasRemovedAds: Bool {
                get {
                    let defaults = UserDefaults.standard
                    let key = "HAS_REMOVED_ADS"
                    if let value = defaults.object(forKey: key) as? Bool {
                        return value
                    }
                    return false as! Bool
                }
                set {
                    let defaults = UserDefaults.standard
                    let key = "HAS_REMOVED_ADS"
                    defaults.set(newValue, forKey: key)
                    defaults.synchronize()
                }
            }
            """,
            macros: ["UserDefault": UserDefaultMacroImpl.self]
        )
    }
}
