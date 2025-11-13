//
//  GradientBackgroundModifier.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/11/2025.
//

import SwiftUI

struct GradientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()

            content
        }
    }
}

extension View {
    func gradientBackground() -> some View {
        self.modifier(GradientBackgroundModifier())
    }
}
