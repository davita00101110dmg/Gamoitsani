//
//  Tokens.swift
//  GamoitsaniDesign
//

import SwiftUI

/// The semantic colour layer.
///
/// Call sites name intent (`surface`, `onSurface`) rather than appearance. The v1 palette
/// survives as the *values* behind these tokens, which is why the dark column is
/// recognisably the old app: `#0F0039` was GMPrimary, `#198A24` GMGreen, `#DC3444` GMRed.
/// Names like `Color 11` do not appear outside this file.
///
/// v1 shipped 23 colorsets whose light and dark entries were byte-identical copies, while
/// `UIUserInterfaceStyle` was left unset — so the app rendered the same in both
/// appearances while system chrome followed the device and disagreed with it. Here each
/// token carries two genuinely different values.
///
/// Light values are not tints of the dark ones. Saturated brand colours that read well on
/// deep indigo are too light on white, so `accent`, `success` and `danger` are darkened
/// for the light appearance to hold their contrast against text-sized geometry. The
/// contrast tests enforce this rather than leaving it to taste.
public enum Tokens {

    // MARK: - Surfaces

    /// The app background.
    public static let surface = DesignColor(light: RGB(0xF6F4FF), dark: RGB(0x0F0039))

    /// Raised above `surface`: sheets, bars, grouped rows.
    public static let surfaceRaised = DesignColor(light: RGB(0xFFFFFF), dark: RGB(0x1B1052))

    // MARK: - Content

    /// Primary text and icons on `surface` or `surfaceRaised`.
    public static let onSurface = DesignColor(light: RGB(0x14093B), dark: RGB(0xF5F3FF))

    /// Secondary text: captions, subtitles, disabled states.
    public static let onSurfaceMuted = DesignColor(light: RGB(0x554C7A), dark: RGB(0xB3ABDC))

    // MARK: - Brand and status

    /// Primary action and brand emphasis.
    public static let accent = DesignColor(light: RGB(0xA8005C), dark: RGB(0xF72585))

    /// Content drawn on top of `accent`.
    ///
    /// Ink, not white, in dark mode. `#F72585` is the palette's signature pink and worth
    /// keeping, but it is a bright colour: white on it measures 3.78:1, under the 4.5:1
    /// AA floor for normal text. The contrast tests caught that. Rather than dulling the
    /// brand colour to accommodate white — the obvious move, and the wrong one — the ink
    /// flips to the deep indigo, which measures 5.15:1 against the same pink.
    ///
    /// In the light appearance `accent` is already dark enough that white reads at 7.45:1.
    public static let onAccent = DesignColor(light: RGB(0xFFFFFF), dark: RGB(0x0F0039))

    /// Correct guesses, positive scores.
    public static let success = DesignColor(light: RGB(0x11661A), dark: RGB(0x3FD04E))

    /// Skips, penalties, destructive actions.
    public static let danger = DesignColor(light: RGB(0xB01F2D), dark: RGB(0xFF6B79))

    // MARK: - Cards

    /// The face of a word card — the central metaphor of the redesign.
    public static let cardFace = DesignColor(light: RGB(0xFFFFFF), dark: RGB(0x241668))

    /// Card border and the edges of a fanned stack.
    public static let cardEdge = DesignColor(light: RGB(0xD9D2F2), dark: RGB(0x3E2E96))

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
    public static let md: CGFloat = 14
    public static let card: CGFloat = 22
    public static let pill: CGFloat = 999
}

/// Type scale.
///
/// Every entry is a Dynamic Type text style rather than a fixed point size, so the app
/// scales with the user's setting. Gameplay text caps its upper bound — an accessibility
/// size that pushes the current word off-screen makes the game unplayable — while
/// everything else scales without limit.
public enum Typography {
    public static let display = Font.system(.largeTitle, design: .rounded, weight: .bold)
    public static let title = Font.system(.title, design: .rounded, weight: .bold)
    public static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    public static let body = Font.system(.body, design: .rounded)
    public static let caption = Font.system(.caption, design: .rounded)

    /// The word under guess. Capped via `.dynamicTypeSize(...DynamicTypeSize.accessibility1)`
    /// at the call site.
    public static let word = Font.system(.largeTitle, design: .rounded, weight: .heavy)
}
