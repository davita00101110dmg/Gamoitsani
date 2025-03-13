//
//  CountdownView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 3/13/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import AVFoundation

struct CountdownView: View {
    @Binding var currentCount: Int
    var totalCount: Int = 3
    var onComplete: () -> Void
    var audioManager: AudioManager
    
    @State private var animationScale: CGFloat = 3.0
    @State private var opacity: Double = 0
    @State private var currentCountValue: Int = 3
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                if currentCountValue > 0 {
                    GMLabelView(text: "\(currentCountValue)", 
                               fontSizeForPhone: 120,
                               fontSizeForPad: 160)
                        .scaleEffect(animationScale)
                        .opacity(opacity)
                } else {
                    GMLabelView(text: "🏁",
                               fontSizeForPhone: 120,
                               fontSizeForPad: 160)
                        .scaleEffect(animationScale)
                        .opacity(opacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .onChange(of: currentCount) { newValue in
            currentCountValue = newValue
            resetAndStartAnimation()
        }
        .onAppear {
            currentCountValue = currentCount
            resetAndStartAnimation()
        }
    }
    
    private func resetAndStartAnimation() {
        animationScale = 3.0
        opacity = 0
        
        if currentCountValue > 0 {
            audioManager.playCountdownTick()
        } else {
            audioManager.playCountdownGo()
        }
        
        withAnimation(.easeOut(duration: 0.5)) {
            animationScale = 1.0
            opacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 0
                animationScale = 0.8
            }
            
            if currentCountValue == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
}
