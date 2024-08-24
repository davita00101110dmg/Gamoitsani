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
        self.modifier(TransitionViewModifier(duration: duration))
    }
}
