//
//  DesignSystemTests.swift
//  GamoitsaniDesignTests
//

import XCTest
import SwiftUI
@testable import GamoitsaniDesign

/// Pins the identity handoff's values and guards the font from failing silently.
final class DesignSystemTests: XCTestCase {

    /// The bundled display face must actually resolve.
    ///
    /// This is the test that matters most in this file. A font shipped in an SPM package
    /// is not in the app bundle, so `.custom("Noto Sans Georgian", ...)` returns the
    /// *system* font if registration did not happen. Nothing crashes, nothing logs — the
    /// app just quietly renders in SF Pro and looks almost right. v1 shipped that exact
    /// failure for every non-Latin language because Mersad has no Georgian glyphs.
    func testBundledDisplayFontResolves() {
        XCTAssertTrue(
            DesignSystem.isDisplayFontAvailable(),
            "Noto Sans Georgian did not register — every Typography.display call is silently falling back to the system font"
        )
    }

    private func displayFontCovers(_ text: String) throws -> Bool {
        DesignSystem.registerFonts()
        let font = try XCTUnwrap(UIFont(name: Typography.displayFamily, size: 24)) as CTFont
        let chars = Array(text.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        return CTFontGetGlyphsForCharacters(font, chars, &glyphs, chars.count)
    }

    /// The scripts the display face genuinely carries.
    func testDisplayFontCoversGeorgianAndLatinScripts() throws {
        for (language, sample) in [
            ("ka", "გამოიცანი"), ("en", "GAMOITSANI"), ("tr", "Paylaş"),
            ("az", "Qaydalar"), ("de", "Über"), ("es", "Añadir"), ("fr", "Règles")
        ] {
            XCTAssertTrue(try displayFontCovers(sample), "display face lost coverage for \(language)")
        }
    }

    /// The scripts it does NOT carry — asserted so the gap stays visible.
    ///
    /// The identity handoff states that Noto Sans Georgian "covers Georgian, Latin,
    /// Cyrillic and Greek in one file". Measured against the actual font binary, that is
    /// not true: it carries Georgian and Latin only. Russian, Ukrainian, Armenian and
    /// Japanese display text therefore falls back to the system face — a milder version of
    /// the v1 Mersad problem the new face was chosen to fix, affecting 4 of 11 languages
    /// rather than 10 of 11.
    ///
    /// The fallback is automatic and legible, so nothing is broken; the display *voice*
    /// is just inconsistent in those four. Closing it means bundling Noto Sans for
    /// Cyrillic/Greek and Noto Sans Armenian, and accepting that Japanese cannot be
    /// bundled at a sane size.
    ///
    /// This test fails the day someone swaps in a font that does cover them — at which
    /// point delete it and move the language into the test above.
    func testKnownDisplayFontCoverageGaps() throws {
        for (language, sample) in [
            ("ru", "Поделиться"), ("uk", "Поділитися"),
            ("hy", "Կանոններ"), ("ja", "シェア")
        ] {
            XCTAssertFalse(
                try displayFontCovers(sample),
                "\(language) is now covered by the display face — update Typography's documented coverage and move this case"
            )
        }
    }

    /// The exact values from the identity handoff. If someone edits a token, this fails
    /// and they have to mean it.
    func testTokenValuesMatchTheIdentityHandoff() {
        let expected: [String: (UInt32, UInt32)] = [
            "surface": (0xF6F4FF, 0x10032E),
            "surfaceRaised": (0xFFFFFF, 0x1D0F4A),
            "onSurface": (0x170640, 0xF4F0FF),
            "onSurfaceMuted": (0x574A82, 0xAFA2D6),
            "accent": (0xD40E6E, 0xFF3D93),
            "onAccent": (0xFFFFFF, 0x2A0014),
            "success": (0x0E7129, 0x3ED47F),
            "danger": (0xB8112A, 0xFF6B7A),
            "cardFace": (0xFFFCF5, 0x241356),
            "cardEdge": (0xC7BEEA, 0x5A6BC4)
        ]

        XCTAssertEqual(Tokens.all.count, expected.count)
        for (name, token) in Tokens.all {
            let pair = try? XCTUnwrap(expected[name], "unexpected token \(name)")
            guard let pair else { continue }
            XCTAssertEqual(token.light, RGB(pair.0), "\(name) light drifted from the handoff")
            XCTAssertEqual(token.dark, RGB(pair.1), "\(name) dark drifted from the handoff")
        }
    }

    /// Card radius scales with width. Fixing it makes small cards look over-rounded.
    func testCardRadiusIsProportionalToWidth() {
        XCTAssertEqual(Radius.card(forWidth: 190), 18, accuracy: 0.001)
        XCTAssertEqual(Radius.card(forWidth: 380), 36, accuracy: 0.001)
        XCTAssertGreaterThan(Radius.card(forWidth: 300), Radius.card(forWidth: 100))
    }

    /// Reduce Motion must substitute, not merely shorten.
    func testReduceMotionSubstitutesTheCrossfade() {
        XCTAssertEqual(Motion.card(reduceMotion: true), Motion.reduced)
        XCTAssertEqual(Motion.control(reduceMotion: true), Motion.reduced)
        XCTAssertEqual(Motion.celebrate(reduceMotion: true), Motion.reduced)
        XCTAssertEqual(Motion.card(reduceMotion: false), Motion.card)
    }
}
