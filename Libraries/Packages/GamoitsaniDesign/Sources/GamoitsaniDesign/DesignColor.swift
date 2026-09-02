//
//  DesignColor.swift
//  GamoitsaniDesign
//

import SwiftUI

/// A colour with an explicit value for each appearance.
///
/// Tokens are declared in Swift rather than as asset-catalog colorsets so that both
/// values are visible at the definition site, greppable, and testable — the contrast
/// checks in `DesignColorContrastTests` read these values directly. An asset catalog
/// hides one of the two behind Xcode's UI and cannot be asserted on in a unit test.
public struct DesignColor: Sendable, Equatable {
    public let light: RGB
    public let dark: RGB

    public init(light: RGB, dark: RGB) {
        self.light = light
        self.dark = dark
    }

    /// Resolves against the current appearance.
    public var color: Color {
        Color(UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    public func value(for scheme: ColorScheme) -> RGB {
        scheme == .dark ? dark : light
    }
}

/// A plain sRGB triple, so tokens can be reasoned about and tested without a UIKit trait
/// environment.
public struct RGB: Sendable, Equatable {
    public let r: Double
    public let g: Double
    public let b: Double

    /// `RGB(0xF72585)` — the same notation the palette is documented in.
    public init(_ hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }

    /// A fixed colour, for brand marks that must not adapt to appearance.
    public var color: Color {
        Color(red: r, green: g, blue: b)
    }

    /// Relative luminance per WCAG 2.1, used by the contrast tests.
    public var relativeLuminance: Double {
        func channel(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    /// WCAG contrast ratio against another colour, from 1 (identical) to 21 (black/white).
    public func contrastRatio(against other: RGB) -> Double {
        let a = relativeLuminance
        let b = other.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}

extension UIColor {
    fileprivate convenience init(_ rgb: RGB) {
        self.init(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
    }
}
