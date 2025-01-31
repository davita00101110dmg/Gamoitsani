//
//  PulsingArrow.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 31/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct PulsingArrow: View {
    @State private var scale = 1.0
    
    var body: some View {
        Image(systemName: "arrow.down")
            .resizable()
            .frame(width: 30, height: 50)
            .foregroundStyle(.white)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever()) {
                    scale = 0.8
                }
            }
    }
}
