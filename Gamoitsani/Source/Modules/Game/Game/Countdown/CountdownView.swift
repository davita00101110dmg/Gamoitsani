//
//  CountdownView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 3/13/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct CountdownView: View {
    @Binding var currentCount: Int
    var totalCount: Int = 3
    var onComplete: () -> Void
    
    @State private var animationScale: CGFloat = 3.0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            if currentCount > 0 {
                Text("\(currentCount)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(Asset.gmPrimary.swiftUIColor)
                    .scaleEffect(animationScale)
                    .opacity(opacity)
                    .onAppear {
                        // Start animation
                        withAnimation(.easeOut(duration: 0.5)) {
                            animationScale = 1.0
                            opacity = 1.0
                        }
                        
                        // Fade out animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            withAnimation(.easeIn(duration: 0.3)) {
                                opacity = 0
                                animationScale = 0.8
                            }
                        }
                    }
            } else {
                Text(L10n.go)
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(Asset.gmGreen.swiftUIColor)
                    .scaleEffect(animationScale)
                    .opacity(opacity)
                    .onAppear {
                        // Start animation
                        withAnimation(.easeOut(duration: 0.5)) {
                            animationScale = 1.0
                            opacity = 1.0
                        }
                        
                        // Fade out animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            withAnimation(.easeIn(duration: 0.3)) {
                                opacity = 0
                                animationScale = 0.8
                            }
                            
                            // Signal completion after the animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onComplete()
                            }
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var count = 3
        
        var body: some View {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                CountdownView(currentCount: $count) {
                    count = 3 // Reset for preview
                }
            }
            .onAppear {
                // For preview, cycle through the countdown
                Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
                    if count > 0 {
                        count -= 1
                    } else {
                        timer.invalidate()
                        // Reset after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            count = 3
                        }
                    }
                }
            }
        }
    }
    
    return PreviewWrapper()
}