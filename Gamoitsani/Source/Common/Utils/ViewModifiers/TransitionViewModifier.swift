//
//  TransitionViewModifier.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct TransitionViewModifier: ViewModifier {
    @State private var hasTransitionEnded = false
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        content
            .disabled(GameStory.shared.playingSessionCount == 0 ? false : !hasTransitionEnded)
            .onAppear {
                startTransition()
            }
            .onDisappear {
                resetTransition()
            }
    }
    
    private func startTransition() {
        hasTransitionEnded = false
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            hasTransitionEnded = true
        }
    }
    
    private func resetTransition() {
        hasTransitionEnded = false
    }
}
