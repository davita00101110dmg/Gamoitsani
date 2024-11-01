//
//  PlayerChip.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct PlayerRowView: View {
    let name: String
    let index: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: ViewConstants.contentSpacing) {
            HStack(spacing: ViewConstants.iconTextSpacing) {
                Image(systemName: ViewConstants.playerIconImage)
                    .foregroundColor(Asset.gmPrimary.swiftUIColor)
                    .font(.system(size: ViewConstants.iconSize))
                
                GMLabelView(text: name, fontSizeForPhone: ViewConstants.fontSize, textAlignment: .leading)
            }
            
            Spacer(minLength: ViewConstants.minSpacing)
            
            Button(action: onDelete) {
                Image(systemName: ViewConstants.deleteButtonImage)
                    .foregroundColor(.white.opacity(0.75))
                    .font(.system(size: ViewConstants.buttonSize))
            }
        }
        .padding(.horizontal, ViewConstants.horizontalPadding)
        .padding(.vertical, ViewConstants.verticalPadding)
        .background(
            Capsule()
                .fill(Asset.gmSecondary.swiftUIColor)
                .overlay(
                    Capsule()
                        .strokeBorder(Asset.gmPrimary.swiftUIColor.opacity(0.3), lineWidth: ViewConstants.borderWidth)
                )
        )
        .contentShape(Capsule())
    }
    
    private enum ViewConstants {
        static let contentSpacing: CGFloat = 8
        static let iconTextSpacing: CGFloat = 6
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 10
        static let minSpacing: CGFloat = 8
        static let iconSize: CGFloat = 18
        static let fontSize: CGFloat = 14
        static let buttonSize: CGFloat = 16
        static let borderWidth: CGFloat = 1
        static let playerIconImage: String = "person.fill"
        static let deleteButtonImage: String = "xmark.circle.fill"
    }
}

#Preview {
    VStack(spacing: 20) {
        PlayerRowView(
            name: "გიორგი მამალაძე",
            index: 0,
            onDelete: {}
        )
        
        PlayerRowView(
            name: "გიო",
            index: 1,
            onDelete: {}
        )
        
        PlayerRowView(
            name: "ალექსანდრე მამალაძე გიორგაძე",
            index: 2,
            onDelete: {}
        )
    }
    .padding()
    .background(Color.black)
}
