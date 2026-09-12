//
//  LanguageMigrationTests.swift
//  GamoitsaniL10nTests
//

import Testing
import Foundation
@testable import GamoitsaniL10n

/// Cutover inherits v1's `UserDefaults`, and the two keys for "which language" differ.
/// These pin the one-way copy, because the failure mode is silent: everyone who chose a
/// language gets reset to the system default and nothing logs it.
@MainActor
@Suite("Legacy language migration")
struct LanguageMigrationTests {

    /// A fresh suite per test — `UserDefaults.standard` is shared across the whole run.
    private func defaults(_ name: String = UUID().uuidString) -> UserDefaults {
        UserDefaults(suiteName: name)!
    }

    @Test("a language chosen in v1 carries over")
    func carriesChoiceOver() {
        let d = defaults()
        d.set("tr", forKey: "APP_LANGUAGE")

        #expect(Localization.migrateLegacyLanguage(in: d) == .turkish)
        #expect(d.string(forKey: "app.language") == "tr")
    }

    /// The old key goes, so this can happen at most once and leaves no v1 residue.
    @Test("the v1 key is removed afterwards")
    func removesLegacyKey() {
        let d = defaults()
        d.set("hy", forKey: "APP_LANGUAGE")

        Localization.migrateLegacyLanguage(in: d)

        #expect(d.string(forKey: "APP_LANGUAGE") == nil)
    }

    /// The guard that makes it one-way: a choice made *in 2.0* must never be overwritten
    /// by a stale v1 value.
    @Test("an existing 2.0 choice wins")
    func doesNotOverwriteCurrentChoice() {
        let d = defaults()
        d.set("APP_LANGUAGE-should-be-ignored", forKey: "APP_LANGUAGE")
        d.set("de", forKey: "app.language")

        #expect(Localization.migrateLegacyLanguage(in: d) == nil)
        #expect(d.string(forKey: "app.language") == "de")
    }

    /// Deliberate: v1 defaulted these people to Georgian whatever their phone said, and
    /// falling through to `systemDefault` is the improvement.
    @Test("someone who never picked is left alone")
    func leavesUnchosenAlone() {
        let d = defaults()

        #expect(Localization.migrateLegacyLanguage(in: d) == nil)
        #expect(d.string(forKey: "app.language") == nil)
    }

    /// Junk is dropped rather than carried across — the system default beats a value
    /// nothing can resolve — but the key still goes, or it would be retried every launch.
    @Test("an unreadable code is discarded, not written")
    func discardsUnreadableCode() {
        let d = defaults()
        d.set("klingon", forKey: "APP_LANGUAGE")

        #expect(Localization.migrateLegacyLanguage(in: d) == nil)
        #expect(d.string(forKey: "app.language") == nil)
        #expect(d.string(forKey: "APP_LANGUAGE") == nil)
    }

    /// Running twice must be indistinguishable from running once.
    @Test("a second run is a no-op")
    func isIdempotent() {
        let d = defaults()
        d.set("ja", forKey: "APP_LANGUAGE")

        #expect(Localization.migrateLegacyLanguage(in: d) == .japanese)
        #expect(Localization.migrateLegacyLanguage(in: d) == nil)
        #expect(d.string(forKey: "app.language") == "ja")
    }

    /// Every code v1 could have written is one 2.0 understands. If a case is ever renamed
    /// on one side this is what catches it.
    @Test("every v1 language code still resolves", arguments: [
        "en", "ka", "uk", "tr", "hy", "az", "de", "es", "fr", "ja", "ru",
    ])
    func everyLegacyCodeResolves(code: String) {
        let d = defaults()
        d.set(code, forKey: "APP_LANGUAGE")

        #expect(Localization.migrateLegacyLanguage(in: d)?.rawValue == code)
    }
}
