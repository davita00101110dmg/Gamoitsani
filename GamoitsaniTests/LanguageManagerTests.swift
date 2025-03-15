//
//  LanguageManagerTests.swift
//  GamoitsaniTests
//
//  Created by Daviti Khvedelidze on 17/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import XCTest
@testable import Gamoitsani

final class LanguageManagerTests: XCTestCase {
    var sut: LanguageManager!
    
    override func setUp() {
        super.setUp()
        // Reset UserDefaults to a clean state before each test
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        sut = LanguageManager.shared
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Language Initialization Tests
    
    func testDefaultLanguageIsGeorgian() {
        // Given UserDefaults has no language set
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.APP_LANGUAGE)
        
        // When creating a new LanguageManager
        let manager = LanguageManager.shared
        
        // Then default language should be English
        XCTAssertEqual(manager.currentLanguage, .georgian)
    }
    
    // MARK: - Language Setting Tests
    
    func testSetLanguage() {
        // Test setting each supported language
        Language.allCases.forEach { language in
            // When
            sut.setLanguage(language)
            
            // Then
            XCTAssertEqual(sut.currentLanguage, language)
            XCTAssertEqual(UserDefaults.standard.string(forKey: UserDefaults.Keys.APP_LANGUAGE), language.rawValue)
        }
    }
    
    // MARK: - Flag Emoji Tests
    
    func testLanguageFlagEmojis() {
        XCTAssertEqual(Language.english.flagEmoji, "🇺🇸")
        XCTAssertEqual(Language.georgian.flagEmoji, "🇬🇪")
        XCTAssertEqual(Language.ukrainian.flagEmoji, "🇺🇦")
        XCTAssertEqual(Language.turkish.flagEmoji, "🇹🇷")
        XCTAssertEqual(Language.armenian.flagEmoji, "🇦🇲")
        XCTAssertEqual(Language.azerbaijani.flagEmoji, "🇦🇿")
        XCTAssertEqual(Language.german.flagEmoji, "🇩🇪")
        XCTAssertEqual(Language.spanish.flagEmoji, "🇪🇸")
        XCTAssertEqual(Language.french.flagEmoji, "🇫🇷")
        XCTAssertEqual(Language.japanese.flagEmoji, "🇯🇵")
        XCTAssertEqual(Language.russian.flagEmoji, "🇷🇺")
    }
    
    // MARK: - Language State Tests
    
    func testIsAppInGeorgian() {
        // When setting language to Georgian
        sut.setLanguage(.georgian)
        
        // Then isAppInGeorgian should be true
        XCTAssertTrue(sut.isAppInGeorgian)
        
        // When setting to any other language
        let nonGeorgianLanguages = Language.allCases.filter { $0 != .georgian }
        nonGeorgianLanguages.forEach { language in
            sut.setLanguage(language)
            XCTAssertFalse(sut.isAppInGeorgian)
        }
    }
    
    // MARK: - Notification Tests
    
    func testLanguageChangeNotification() {
        // Given
        let expectation = XCTestExpectation(description: "Language change notification received")
        
        // When
        NotificationCenter.default.addObserver(forName: .languageDidChange, object: nil, queue: .main) { _ in
            expectation.fulfill()
        }
        
        sut.setLanguage(.turkish) // Test with one of the new languages
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}
