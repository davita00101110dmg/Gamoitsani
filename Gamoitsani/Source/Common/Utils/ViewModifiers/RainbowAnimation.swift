//
//  RainbowAnimation.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct RainbowAnimation: ViewModifier {
    @State private var isOn: Bool = false
    let hueColors = [
        Asset.color11.swiftUIColor,
        Asset.color12.swiftUIColor,
        Asset.color13.swiftUIColor,
        Asset.color14.swiftUIColor,
        Asset.color11.swiftUIColor
    ]
    
    var duration: Double = 2
    
    func body(content: Content) -> some View {
        let gradient = LinearGradient(
            gradient: Gradient(colors: hueColors + hueColors),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        return content
            .overlay(GeometryReader { proxy in
                ZStack {
                    gradient
                        .frame(width: 2 * proxy.size.width)
                        .offset(x: self.isOn ? -proxy.size.width : 0)
                }
            })
            .onAppear {
                withAnimation(.linear(duration: self.duration).repeatForever(autoreverses: true)) {
                    self.isOn = true
                }
            }
            .mask(content)
    }
}
