//
//  DisplayConfettiModifier.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 31/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct DisplayConfettiModifier: ViewModifier {
    @Binding var isActive: Bool {
        didSet {
            if !isActive {
                opacity = 1
            }
        }
    }
    
    @State private var opacity = 1.0
    
    private let animationTime = 5.0
    private let fadeTime = 1.0
    
    func body(content: Content) -> some View {
        content
            .overlay(isActive ? ConfettiContainerView().opacity(opacity) : nil)
            .applySensoryFeedbackIfAvailable(isActive: isActive)
            .onChange(of: isActive) { newValue in
                if newValue {
                    startConfettiAnimation()
                } else {
                    stopConfettiAnimation()
                }
            }
    }
    
    private func startConfettiAnimation() {
        opacity = 1.0
        Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(animationTime * 1_000_000_000))
                if isActive {
                    withAnimation(.easeOut(duration: fadeTime)) {
                        opacity = 0
                    }
                }
            }
        }
    }
    
    private func stopConfettiAnimation() {
        withAnimation {
            opacity = 0
        }
    }
}
