//
//  SocialIconView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 28/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct SocialIconView: View {
    let image: Image
    let title: String
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                action?()
            }, label: {
                image
                    .resizable()
                    .frame(width: ViewConstants.size, height: ViewConstants.size)
            })

            GMLabelView(text: title, fontSizeForPhone: 12)
        }
    }
}

struct ViewConstants {
    static let size: CGFloat = 40.0
}

#Preview {
    ZStack {
        GradientBackground()
            .ignoresSafeArea()
        
        SocialIconView(image: Asset.instagram.swiftUIImage, title: "Save to camera roll", action: nil)
    }
}
