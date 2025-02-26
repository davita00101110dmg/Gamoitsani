//
//  ViewExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

extension View {
    func transitionHandler(duration: TimeInterval) -> some View {
        modifier(TransitionViewModifier(duration: duration))
    }
    
    func displayConfetti(isActive: Binding<Bool>) -> some View {
        modifier(DisplayConfettiModifier(isActive: isActive))
    }
    
    func gameDetailsAlert(alertType: Binding<AlertType?>, viewModel: GameDetailsViewModel) -> some View {
        modifier(AlertWithTextFieldModifier(alertType: alertType, viewModel: viewModel))
    }
    
    func customSegmentedPickerStyle() -> some View {
        modifier(CustomSegmentedPickerStyle())
    }

    func rainbowAnimation() -> some View {
        self.modifier(RainbowAnimation())
    }
    
    @ViewBuilder
    func applySensoryFeedbackIfAvailable(isActive: Bool) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.success, trigger: isActive) { _, _ in
                return isActive == true
            }
        } else {
            self
        }
    }
}
