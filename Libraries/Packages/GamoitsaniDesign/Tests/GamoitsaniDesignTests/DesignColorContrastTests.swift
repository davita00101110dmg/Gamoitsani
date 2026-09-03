//
//  DesignColorContrastTests.swift
//  GamoitsaniDesignTests
//

import XCTest
import SwiftUI
@testable import GamoitsaniDesign

/// Contrast is enforced here rather than left to review.
///
/// The plan lists accessibility as a build rule, not a phase. These assertions are what
/// makes that true for colour: a token pair that drops below its WCAG threshold fails the
/// build, in whichever appearance broke it. This matters most for the light palette, whose
/// values are new — the dark ones inherit v1's and were at least visually vetted by
/// shipping.
final class DesignColorContrastTests: XCTestCase {

    /// WCAG 2.1 AA for normal-sized text.
    private let normalText = 4.5

    /// WCAG 2.1 AA for large text (>= 18pt bold / 24pt regular) and UI components.
    private let largeTextOrUI = 3.0

    private func assertContrast(
        _ foreground: DesignColor,
        on background: DesignColor,
        atLeast threshold: Double,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for scheme in [ColorScheme.light, .dark] {
            let ratio = foreground.value(for: scheme).contrastRatio(against: background.value(for: scheme))
            XCTAssertGreaterThanOrEqual(
                ratio,
                threshold,
                String(
                    format: "%@ in %@ is %.2f:1, below the %.1f:1 requirement",
                    label,
                    scheme == .dark ? "dark" : "light",
                    ratio,
                    threshold
                ),
                file: file,
                line: line
            )
        }
    }

    // MARK: - Text

    func testPrimaryTextMeetsAAOnBothSurfaces() {
        assertContrast(Tokens.onSurface, on: Tokens.surface, atLeast: normalText, "onSurface on surface")
        assertContrast(Tokens.onSurface, on: Tokens.surfaceRaised, atLeast: normalText, "onSurface on surfaceRaised")
    }

    func testMutedTextMeetsAAOnBothSurfaces() {
        assertContrast(Tokens.onSurfaceMuted, on: Tokens.surface, atLeast: normalText, "onSurfaceMuted on surface")
        assertContrast(Tokens.onSurfaceMuted, on: Tokens.surfaceRaised, atLeast: normalText, "onSurfaceMuted on surfaceRaised")
    }

    func testTextOnCardFaceMeetsAA() {
        assertContrast(Tokens.onSurface, on: Tokens.cardFace, atLeast: normalText, "onSurface on cardFace")
    }

    func testContentOnAccentMeetsAA() {
        assertContrast(Tokens.onAccent, on: Tokens.accent, atLeast: normalText, "onAccent on accent")
    }

    // MARK: - Status colours

    /// Status colours carry meaning, so they must be distinguishable as UI components even
    /// when not used at text size.
    func testStatusColoursAreDistinguishableOnSurface() {
        assertContrast(Tokens.success, on: Tokens.surface, atLeast: largeTextOrUI, "success on surface")
        assertContrast(Tokens.danger, on: Tokens.surface, atLeast: largeTextOrUI, "danger on surface")
        assertContrast(Tokens.accent, on: Tokens.surface, atLeast: largeTextOrUI, "accent on surface")
    }

    // MARK: - Structure

    /// A card must be visible against the background it sits on, or the central metaphor
    /// disappears.
    func testCardIsDistinguishableFromSurface() {
        for scheme in [ColorScheme.light, .dark] {
            let card = Tokens.cardFace.value(for: scheme)
            let surface = Tokens.surface.value(for: scheme)
            let edge = Tokens.cardEdge.value(for: scheme)

            XCTAssertNotEqual(card, surface, "cardFace must not equal surface in \(scheme)")
            XCTAssertGreaterThan(
                edge.contrastRatio(against: card),
                1.1,
                "cardEdge must be visible against cardFace in \(scheme)"
            )
        }
    }

    // MARK: - The v1 defect these tokens exist to fix

    /// v1's 23 colorsets defined dark values that were byte-identical to their light ones,
    /// so "supporting dark mode" was cosmetic. Every token here must genuinely differ.
    func testEveryTokenActuallyDiffersBetweenAppearances() {
        for (name, token) in Tokens.all {
            XCTAssertNotEqual(
                token.light,
                token.dark,
                "\(name) has identical light and dark values — the v1 mistake"
            )
        }
    }

    func testAllTokensAreRegisteredInAll() {
        // Guards against adding a token and forgetting to list it, which would silently
        // exempt it from every check above.
        XCTAssertEqual(Tokens.all.count, 10)
        XCTAssertEqual(Set(Tokens.all.map(\.name)).count, Tokens.all.count, "duplicate token name")
    }
}
