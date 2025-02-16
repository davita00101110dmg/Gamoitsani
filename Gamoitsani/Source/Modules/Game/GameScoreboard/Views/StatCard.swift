//
//  StatCard.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 16/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            GMLabelView(text: value)
                .font(F.Mersad.bold.swiftUIFont(size: 32))
                .foregroundColor(.white)
            
            GMLabelView(text: title)
                .font(F.Mersad.regular.swiftUIFont(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20) 
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Asset.gmSecondary.swiftUIColor)
        )
    }
}
