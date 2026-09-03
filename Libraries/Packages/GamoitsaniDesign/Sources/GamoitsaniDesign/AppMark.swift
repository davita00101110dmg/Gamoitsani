//
//  AppMark.swift
//  GamoitsaniDesign
//
import SwiftUI

/// The identity mark: three cards fanned at ±19° with flat fills and no gradient.
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
