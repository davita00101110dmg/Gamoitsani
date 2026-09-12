//
//  ContentColumn.swift
//  GamoitsaniDesign
//
import SwiftUI

public extension View {
    /// Caps a scrolling column at a readable width and centres what is left.
    ///
    /// Every screen in the app is a single column of panels. Left alone that column runs
    /// the full width of an iPad, which does not break anything but reads as sparse — the
    /// rows grow, the text does not, and the gap between a label and its control becomes
    /// the widest thing on screen.
    func contentColumn(_ width: CGFloat = Sizing.contentColumn) -> some View {
        frame(maxWidth: width)
            .frame(maxWidth: .infinity)
    }
}
