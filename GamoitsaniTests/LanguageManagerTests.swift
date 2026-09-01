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
    private var originalLanguage: Language!

    override func setUp() {
        super.setUp()
        sut = LanguageManager.shared

        // Snapshot and restore just the language. The previous version called
        // removePersistentDomain(forName:) on the host app's bundle identifier, which
        // wiped every AppSettings value in the simulator — purchase state included —
        // rather than only what these tests touch.
        originalLanguage = sut.currentLanguage
    }

    override func tearDown() {
        sut.setLanguage(originalLanguage)
        originalLanguage = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Language Initialization Tests

    func testAppLanguageDefaultsToGeorgianWhenUnset() {
        // LanguageManager is a `private init` singleton constructed once per process, so
        // its currentLanguage cannot be re-derived here — whichever test ran first would
        // decide the answer. What is actually testable is the stored default the manager
        // reads at construction.
        UserDefaults.standard.removeObject(forKey: AppSettings.APP_LANGUAGE)

        XCTAssertEqual(AppSettings.appLanguage, Language.georgian.rawValue)
        XCTAssertEqual(Language(rawValue: AppSettings.appLanguage), .georgian)
    }

    // MARK: - Language Setting Tests

    func testSetLanguagePersistsEverySupportedLanguage() {
        Language.allCases.forEach { language in
            sut.setLanguage(language)

            XCTAssertEqual(sut.currentLanguage, language)
            XCTAssertEqual(
                UserDefaults.standard.string(forKey: AppSettings.APP_LANGUAGE),
                language.rawValue,
                "\(language.rawValue) was not persisted"
            )
        }
    }

    func testSetLanguageIsIdempotent() {
        sut.setLanguage(.french)
        sut.setLanguage(.french)

        XCTAssertEqual(sut.currentLanguage, .french)
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppSettings.APP_LANGUAGE), "fr")
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

    func testEverySupportedLanguageHasAFlagAndDisplayName() {
        // Guards the next language addition: 11 cases, none blank.
        XCTAssertEqual(Language.allCases.count, 11)
        Language.allCases.forEach { language in
            XCTAssertFalse(language.flagEmoji.isEmpty, "\(language.rawValue) has no flag")
            XCTAssertFalse(language.displayName.isEmpty, "\(language.rawValue) has no display name")
        }
    }

    // MARK: - Language State Tests

    func testIsAppInGeorgian() {
        sut.setLanguage(.georgian)
        XCTAssertTrue(sut.isAppInGeorgian)

        Language.allCases.filter { $0 != .georgian }.forEach { language in
            sut.setLanguage(language)
            XCTAssertFalse(sut.isAppInGeorgian, "\(language.rawValue) should not report as Georgian")
        }
    }

    // MARK: - Notification Tests

    func testLanguageChangeNotification() {
        let expectation = XCTestExpectation(description: "Language change notification received")

        // Hold the token so the observer is torn down; the previous version registered a
        // block observer and never removed it, so it kept firing for later tests.
        let observer = NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        sut.setLanguage(.turkish)

        wait(for: [expectation], timeout: 1.0)
    }
}
