//
//  RainbowBorderCardView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct RainbowBorderCardView: View {
    let word: String
    let isGuessed: Bool
    let action: () -> Void

    @State private var rotationAngle: Double = 0

    private let rainbowColors = [
        Asset.color11.swiftUIColor,
        Asset.color12.swiftUIColor,
        Asset.color13.swiftUIColor,
        Asset.color14.swiftUIColor,
        Asset.color11.swiftUIColor
    ]

    var body: some View {
        Button(action: action) {
            GMLabelView(text: word, fontType: .bold)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Asset.gmSecondary.swiftUIColor)
                .cornerRadius(10)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: rainbowColors),
                                center: .center,
                                angle: .degrees(rotationAngle)
                            ),
                            lineWidth: 2
                        )
                )
        }
        .opacity(isGuessed ? 0.4 : 1)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 3)
                    .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
        }
    }
}
