//
//  L10nTests.swift
//  GamoitsaniL10nTests
//

import Testing
import Foundation
@testable import GamoitsaniL10n

@Suite("Localization")
struct L10nTests {

    /// The whole point of resolving with an explicit locale: without it the catalogue
    /// follows the device and the app cannot offer its own language picker.
    @Test("a key resolves differently per language")
    func perLanguageResolution() {
        #expect(L10n.string("setup.play", language: .english) == "Play")
        #expect(L10n.string("setup.play", language: .georgian) == "თამაში")
        #expect(L10n.string("setup.play", language: .english) != L10n.string("setup.play", language: .georgian))
    }

    /// A missing key renders as itself, which makes an untranslated string visible in the
    /// UI rather than silently blank.
    @Test("an unknown key returns the key")
    func unknownKey() {
        #expect(L10n.string("no.such.key", language: .english) == "no.such.key")
    }

    /// The property that matters while nine languages are part-translated: whatever is
    /// missing, a user never sees a key. Pinning this to one key instead meant the test
    /// broke the moment that key was translated.
    @Test("no language ever shows a raw key")
    func noRawKeys() throws {
        let keys = try Self.englishKeys()
        #expect(keys.count > 50, "catalogue looks empty — did the resource move?")

        for language in AppLanguage.allCases {
            for key in keys {
                #expect(
                    L10n.string(key, language: language) != key,
                    "\(key) resolves to itself in \(language.rawValue)"
                )
            }
        }
    }

    /// A partially translated language serves what it has and falls back for the rest.
    @Test("a part-translated language mixes its own strings with English")
    func partialLanguage() {
        #expect(L10n.string("setup.play", language: .german) == "Start")
        #expect(L10n.string("game.stats", language: .german) == "Stats")
    }

    private static func englishKeys() throws -> [String] {
        let path = try #require(Bundle.module.path(forResource: "en", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        let url = try #require(bundle.url(forResource: "Localizable", withExtension: "strings"))
        let table = try #require(NSDictionary(contentsOf: url) as? [String: String])
        return Array(table.keys)
    }

    @Test("every shipped language has an endonym and a flag")
    func metadataIsComplete() {
        #expect(AppLanguage.allCases.count == 11)
        for language in AppLanguage.allCases {
            #expect(!language.endonym.isEmpty, "\(language.rawValue) has no endonym")
            #expect(!language.flag.isEmpty, "\(language.rawValue) has no flag")
        }
    }

    /// Georgian is the primary audience, so an unrecognised system language lands there
    /// rather than on English.
    @Test("Georgian is the fallback default")
    func defaultIsGeorgian() {
        #expect(AppLanguage(rawValue: "xx") == nil)
        #expect(AppLanguage.allCases.first == .georgian)
    }
}
