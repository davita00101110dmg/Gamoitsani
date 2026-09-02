//
//  Tokens.swift
//  GamoitsaniDesign
//

import SwiftUI

/// The semantic colour layer.
///
/// Values come from the 2.0 visual identity handoff. Call sites name intent (`surface`,
/// `onSurface`) rather than appearance, so a palette revision is a change to this file and
/// nothing else.
///
/// Both appearances are real designs. v1 shipped 23 colorsets whose dark entries were
/// byte-identical copies of their light ones while `UIUserInterfaceStyle` was left unset,
/// so the app rendered the same either way while system chrome followed the device and
/// disagreed with it. The light palette here is cool white paper with a warm card face —
/// not an inverted dark screen.
///
/// Every ratio below was recomputed from these hex values before they landed; see
/// `DesignColorContrastTests`, which asserts all nine pairings in both appearances.
public enum Tokens {

    // MARK: - Surfaces

    /// The app background.
    public static let surface = DesignColor(light: RGB(0xF6F4FF), dark: RGB(0x10032E))

    /// Raised above `surface`: sheets, grouped rows, settings cards.
    ///
    /// v1 used `gmSecondary` at 30% opacity for page panels, cards *and* list rows
    /// simultaneously, so nothing read as elevated. That role is split between this and
    /// `cardFace`.
    public static let surfaceRaised = DesignColor(light: RGB(0xFFFFFF), dark: RGB(0x1D0F4A))

    // MARK: - Content

    /// Primary text and icons.
    public static let onSurface = DesignColor(light: RGB(0x170640), dark: RGB(0xF4F0FF))

    /// Secondary text: captions, subtitles, inactive states.
    public static let onSurfaceMuted = DesignColor(light: RGB(0x574A82), dark: RGB(0xAFA2D6))

    // MARK: - Brand and status

    /// Primary action and brand emphasis.
    ///
    /// The two appearances take opposite routes on purpose. Light is a magenta-red deep
    /// enough that white sits on it at 5.14:1. Dark is a brighter pink that would fail
    /// under white, so its ink goes dark instead — see `onAccent`.
    public static let accent = DesignColor(light: RGB(0xD40E6E), dark: RGB(0xFF3D93))

    /// Content drawn on top of `accent`. Not white in dark mode: `#FF3D93` is too bright
    /// to carry white text, and dulling it to accommodate white would drain the brand
    /// colour. Dark ink measures 5.72:1 against it.
    public static let onAccent = DesignColor(light: RGB(0xFFFFFF), dark: RGB(0x2A0014))

    /// Correct guesses, positive scores.
    public static let success = DesignColor(light: RGB(0x0E7129), dark: RGB(0x3ED47F))

    /// Skips, penalties, destructive actions.
    public static let danger = DesignColor(light: RGB(0xB8112A), dark: RGB(0xFF6B7A))

    // MARK: - Cards

    /// The face of a word card. Warm cream in light, so a card reads as paper against the
    /// cool surface rather than as another white panel.
    public static let cardFace = DesignColor(light: RGB(0xFFFCF5), dark: RGB(0x241356))

    /// Card stroke and the edges of a fanned stack.
    public static let cardEdge = DesignColor(light: RGB(0xC7BEEA), dark: RGB(0x5A6BC4))

    /// Every token, for tests and previews. Keep in sync when adding one.
    public static let all: [(name: String, color: DesignColor)] = [
        ("surface", surface),
        ("surfaceRaised", surfaceRaised),
        ("onSurface", onSurface),
        ("onSurfaceMuted", onSurfaceMuted),
        ("accent", accent),
        ("onAccent", onAccent),
        ("success", success),
        ("danger", danger),
        ("cardFace", cardFace),
        ("cardEdge", cardEdge)
    ]
}

/// Fixed brand colours for the identity mark.
///
/// Deliberately *not* semantic tokens. The app icon is one artwork with one set of
/// colours; a mark that recoloured itself between light and dark would stop being a mark.
/// These are the exact fills from the identity's icon artwork, so the drawn version and
/// the shipped icon cannot drift apart.
public enum Brand {
    /// The icon's field.
    public static let markField = RGB(0x10032E)

    /// The card behind, on the left.
    public static let markCardBack = RGB(0x4756A6)

    /// The card behind, on the right.
    public static let markCardAccent = RGB(0xFF3D93)

    /// The front card's face.
    public static let markCardFace = RGB(0xFFFCF5)

    /// The question mark on the front card.
    public static let markInk = RGB(0x170640)

    // Proportions taken from the icon artwork's 1024pt viewBox, so the drawn mark and the
    // shipped icon stay identical. A word card's radius ratio is different and must not be
    // reused here — doing so made the fan read as one blob instead of three planes.
    public static let markCardWidthRatio: CGFloat = 372.0 / 1024.0
    public static let markCardHeightRatio: CGFloat = 504.0 / 1024.0
    public static let markCardRadiusRatio: CGFloat = 44.0 / 372.0
    public static let markFieldRadiusRatio: CGFloat = 0.22
    public static let markGlyphRatio: CGFloat = 330.0 / 504.0
    public static let markFanAngle: Double = 19
}

/// Spacing scale. A 4pt base with a named step per use, so call sites never invent a
/// number — v1 used bare literals from 2 to 40 with no system behind them.
public enum Spacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

/// Corner radii, sized to the card metaphor.
public enum Radius {
    public static let sm: CGFloat = 8
    public static let control: CGFloat = 14
    public static let panel: CGFloat = 18
    public static let card: CGFloat = 20
    public static let pill: CGFloat = 999

    /// A card's radius is proportional to its width, never fixed: 18pt at 190pt wide.
    /// Fixing it makes a small card look over-rounded and a large one look square.
    public static func card(forWidth width: CGFloat) -> CGFloat {
        width * (18.0 / 190.0)
    }
}

/// Motion. One spring family, three durations — anything outside this set is a bug.
///
/// `.linear` is reserved for the timer digits, which must not ease.
public enum Motion {
    /// Anything a card does: enter, flip, leave.
    public static let card = Animation.spring(response: 0.34, dampingFraction: 0.78)

    /// Taps, toggles, score bumps. Nearly no overshoot.
    public static let control = Animation.spring(response: 0.22, dampingFraction: 0.9)

    /// The podium, the one place a bounce is welcome.
    public static let celebrate = Animation.spring(response: 0.5, dampingFraction: 0.7)

    /// Reduce Motion replacement: springs collapse to a crossfade, nothing moves or
    /// scales. Read `\.accessibilityReduceMotion` and substitute this.
    public static let reduced = Animation.easeInOut(duration: 0.15)

    /// Picks the right animation for the current accessibility setting.
    public static func card(reduceMotion: Bool) -> Animation { reduceMotion ? reduced : card }
    public static func control(reduceMotion: Bool) -> Animation { reduceMotion ? reduced : control }
    public static func celebrate(reduceMotion: Bool) -> Animation { reduceMotion ? reduced : celebrate }
}
