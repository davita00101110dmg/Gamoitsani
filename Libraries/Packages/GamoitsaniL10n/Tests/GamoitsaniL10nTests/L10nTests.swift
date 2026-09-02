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

    /// The catalogue currently carries en and ka. Everything else falls back to the source
    /// language rather than showing raw keys — acceptable while the other nine are being
    /// translated, and worth knowing rather than discovering.
    @Test("untranslated languages fall back to English, not to raw keys", arguments: [
        AppLanguage.german, .french, .japanese, .russian,
    ])
    func fallback(language: AppLanguage) {
        let value = L10n.string("setup.play", language: language)
        #expect(value == "Play")
        #expect(value != "setup.play", "a raw key would mean the fallback chain is broken")
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
