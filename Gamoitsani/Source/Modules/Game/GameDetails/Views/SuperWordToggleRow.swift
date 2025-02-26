//
//  SuperWordToggleRow.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//


import SwiftUI

struct SuperWordToggleRow: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            GMLabelView(
                text: L10n.Screen.GameDetails.SuperWord.description,
                textAlignment: .leading
            )
            
            Spacer()
            
            Toggle(String.empty, isOn: $isEnabled)
                .toggleStyle(CheckToggleStyle())
        }
        .animation(.easeInOut, value: isEnabled)
    }
}
