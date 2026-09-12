//
//  AppMark.swift
//  GamoitsaniDesign
//
import SwiftUI

/// The identity mark: three cards fanned at ±19° with flat fills and no gradient.
public struct AppMark: View {

    /// Whether to draw the dark rounded tile the cards sit on.
    ///
    /// The field is a fixed dark colour, because an app icon cannot be transparent and
    /// cannot vary by theme. On a dark screen it disappears into the surface and you see
    /// only the cards, which is the intent — but in light mode the same tile is a dark
    /// slab behind them. Anywhere inside the app the cards can simply sit on whatever is
    /// already there, so the field is off by default and the icon asks for it.
    private let drawsField: Bool

    public init(drawsField: Bool = false) {
        self.drawsField = drawsField
    }

    public var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cardW = side * Brand.markCardWidthRatio
            let cardH = side * Brand.markCardHeightRatio
            let radius = cardW * Brand.markCardRadiusRatio

            ZStack {
                if drawsField {
                    RoundedRectangle(cornerRadius: side * Brand.markFieldRadiusRatio, style: .continuous)
                        .fill(Brand.markField.color)
                }

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
