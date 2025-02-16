//
//  PerformanceStatRow.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 16/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct PerformanceStatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Asset.gmPrimary.swiftUIColor)
            
            GMLabelView(text: title)
                .font(F.Mersad.regular.swiftUIFont(size: 16))
            
            Spacer()
            
            GMLabelView(text: value)
                .font(F.Mersad.semiBold.swiftUIFont(size: 16))
        }
        .foregroundColor(.white)
    }
}
