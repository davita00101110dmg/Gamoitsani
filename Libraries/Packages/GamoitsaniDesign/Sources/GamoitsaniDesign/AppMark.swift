//
//  AppMark.swift
//  GamoitsaniDesign
//

import SwiftUI

/// The identity mark: three cards fanned at ±19° with flat fills and no gradient.
///
/// Drawn rather than rasterised, from ratios taken off the icon artwork's 1024pt viewBox,
/// so the on-screen mark and the shipped app icon cannot drift apart and it stays crisp at
/// any size. It lives in the design package because it is part of the identity, not part
/// of any one screen.
///
/// Its colours are `Brand`, not semantic tokens: an icon is one artwork with one set of
/// fills, and a mark that recoloured itself between appearances would stop being a mark.
public struct AppMark: View {

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cardW = side * Brand.markCardWidthRatio
            let cardH = side * Brand.markCardHeightRatio
            let radius = cardW * Brand.markCardRadiusRatio

            ZStack {
                RoundedRectangle(cornerRadius: side * Brand.markFieldRadiusRatio, style: .continuous)
                    .fill(Brand.markField.color)

                card(radius: radius, w: cardW, h: cardH, fill: Brand.markCardBack.color)
                    .rotationEffect(.degrees(-Brand.markFanAngle))

                card(radius: radius, w: cardW, h: cardH, fill: Brand.markCardAccent.color)
                    .rotationEffect(.degrees(Brand.markFanAngle))

                card(radius: radius, w: cardW, h: cardH, fill: Brand.markCardFace.color)
                    .overlay {
                        Text(verbatim: "?")
                            .font(.custom(Typography.displayFamily, size: cardH * Brand.markGlyphRatio).weight(.black))
                            .foregroundStyle(Brand.markInk.color)
                    }
                    .offset(y: -side * 0.0098)
            }
        }
    }

    private func card(radius: CGFloat, w: CGFloat, h: CGFloat, fill: Color) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(fill)
            .frame(width: w, height: h)
    }
}

#Preview {
    AppMark().frame(width: 160, height: 160)
}
