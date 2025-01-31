//
//  GameLoadingView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 31/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var textOpacity = 1.0
    let text: String
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(AngularGradient(
                        gradient: Gradient(colors: [
                            .gray.opacity(0.1),
                            .gray.opacity(0.25),
                            .gray.opacity(0.5),
                            .gray
                        ]),
                        center: .center,
                        angle: .degrees(isAnimating ? 360 : 0)
                    ))
                    .mask {
                        Image(systemName: "circle.dotted")
                            .resizable()
                            .frame(width: 100, height: 100)
                    }
                
                PulsingArrow()
            }
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    isAnimating.toggle()
                }
            }
            
            GMLabelView(text: text)
                .opacity(textOpacity)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1)
                        .repeatForever(autoreverses: true)
                    ) {
                        textOpacity = 0.5
                    }
                }
        }
    }
}
