//
//  GameModePickerView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameModePickerView: View {
    @Binding var selectedMode: GameMode
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                GameModeOptionView(
                    mode: mode,
                    isSelected: selectedMode == mode
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMode = mode
                    }
                }
            }
        }
    }
}
