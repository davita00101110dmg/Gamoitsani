//
//  PlaceholderView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct PlaceholderView: View {
    let imageName: String
    let title: String
    let addButtonAction: () -> Void
    
    var body: some View {
        VStack(spacing: Layout.spacing) {
            imageView
                .modifier(PulseAnimation())
            titleView
            addButton
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private var imageView: some View {
        Image(systemName: imageName)
            .font(.system(size: Layout.imageSize))
            .foregroundColor(.white)
    }
    
    private var titleView: some View {
        GMLabelView(text: title)
            .padding(.bottom, Layout.titleBottomPadding)
    }
    
    private var addButton: some View {
        GMButtonView(
            text: L10n.add,
            fontSizeForPhone: Layout.buttonTitleFontSize,
            backgroundColor: Asset.gmPrimary.swiftUIColor,
            height: Layout.addButtonHeight,
            action: addButtonAction
        )
    }
}

private extension PlaceholderView {
    enum Layout {
        static let spacing: CGFloat = 12
        static let imageSize: CGFloat = 40
        static let titleBottomPadding: CGFloat = 8
        static let buttonTitleFontSize: CGFloat = 16
        static let addButtonHeight: CGFloat = 44
        static let cornerRadius: CGFloat = 12
    }
}

#Preview {
    VStack(spacing: 20) {
        PlaceholderView(
            imageName: "person.2",
            title: "დაამატეთ გუნდები თამაშის დასაწყებად"
        ) {
            
        }
        
        PlaceholderView(
            imageName: "person.fill.questionmark",
            title: "დაამატეთ მოთამაშეები გუნდების შესაქმნელად"
        ) {
            
        }
    }
    .padding()
    .background(Asset.gmSecondary.swiftUIColor)
}
