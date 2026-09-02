//
//  TeamPaletteTests.swift
//  GamoitsaniDesignTests
//

import XCTest
import SwiftUI
@testable import GamoitsaniDesign

final class TeamPaletteTests: XCTestCase {

    /// Team colours are used as dots, bars and strokes rather than text, so the bar is
    /// WCAG's 3:1 for non-text UI — but it is a bar, not a suggestion. A team colour that
    /// fails it is invisible on the surface it identifies.
    func testEveryTeamColourIsVisibleOnBothSurfaces() {
        for (index, color) in TeamPalette.colors.enumerated() {
            for (scheme, surface, raised) in [
                (ColorScheme.light, Tokens.surface, Tokens.surfaceRaised),
                (ColorScheme.dark, Tokens.surface, Tokens.surfaceRaised)
            ] {
                let team = color.value(for: scheme)
                XCTAssertGreaterThanOrEqual(
                    team.contrastRatio(against: surface.value(for: scheme)), 3.0,
                    "team \(index) on surface in \(scheme)"
                )
                XCTAssertGreaterThanOrEqual(
                    team.contrastRatio(against: raised.value(for: scheme)), 3.0,
                    "team \(index) on surfaceRaised in \(scheme)"
                )
            }
        }
    }

    /// Two teams whose colours are hard to tell apart defeat the purpose.
    func testTeamColoursAreDistinguishableFromEachOther() {
        for i in TeamPalette.colors.indices {
            for j in TeamPalette.colors.indices where j > i {
                for scheme in [ColorScheme.light, .dark] {
                    let a = TeamPalette.colors[i].value(for: scheme)
                    let b = TeamPalette.colors[j].value(for: scheme)
                    XCTAssertNotEqual(a, b, "teams \(i) and \(j) share a colour in \(scheme)")
                }
            }
        }
    }

    func testThereIsAColourForEveryAllowedTeam() {
        // The game allows 2...5 teams.
        XCTAssertGreaterThanOrEqual(TeamPalette.colors.count, 5)
    }

    func testColourLookupWrapsInsteadOfTrapping() {
        XCTAssertEqual(TeamPalette.color(at: 0), TeamPalette.colors[0])
        XCTAssertEqual(TeamPalette.color(at: 5), TeamPalette.colors[0])
        XCTAssertEqual(TeamPalette.color(at: -1), TeamPalette.colors[4])
    }

    /// The first team leads with the brand colour.
    func testFirstTeamUsesTheAccent() {
        XCTAssertEqual(TeamPalette.colors[0], Tokens.accent)
    }
}
