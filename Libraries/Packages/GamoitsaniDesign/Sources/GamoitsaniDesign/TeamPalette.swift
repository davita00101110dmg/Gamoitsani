//
//  TeamPalette.swift
//  GamoitsaniDesign
//
import SwiftUI

/// Colours that identify a team.
public enum TeamPalette {

    public static let colors: [DesignColor] = [
        DesignColor(light: RGB(0xD40E6E), dark: RGB(0xFF3D93)),   // magenta — the accent
        DesignColor(light: RGB(0x2F44B0), dark: RGB(0x6D80DE)),   // blue
        DesignColor(light: RGB(0x0E7129), dark: RGB(0x3ED47F)),   // green
        DesignColor(light: RGB(0x9A5A00), dark: RGB(0xFFB454)),   // amber
        DesignColor(light: RGB(0x6D28A8), dark: RGB(0xC08CF5)),   // violet
    ]

    /// The colour for a team at a given position. Wraps, so it cannot trap even if the
    /// team limit is ever raised without updating this file.
    public static func color(at index: Int) -> DesignColor {
        colors[((index % colors.count) + colors.count) % colors.count]
    }
}
