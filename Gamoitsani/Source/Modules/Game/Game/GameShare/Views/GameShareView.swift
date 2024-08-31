//
//  GameShareView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 27/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameShareView: View {
    @EnvironmentObject private var coordinator: GameShareCoordinator
    var viewModel: GameShareViewModel
    
    let image: UIImage
    
    var body: some View {
        
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                GMLabelView(text: L10n.Screen.GameShare.title, fontSizeForPhone: 18)
                    .padding(.bottom, 16)
                
                Spacer()
                
                Image(uiImage: image)
                
                Spacer()
                Spacer()
                
                shareOptionsOverlay
            }
        }
    }
    
    private var shareOptionsOverlay: some View {
        RoundedRectangle(cornerRadius: ViewConstants.overlayCornerRadius)
            .fill(.black.opacity(ViewConstants.overlayOpacity))
            .frame(maxHeight: ViewConstants.overlayHeight)
            .padding([.leading, .trailing], ViewConstants.overlayPadding)
            .overlay(
                VStack {
                    
                    GMLabelView(text: L10n.Screen.GameShare.shareTo)
                        .padding([.bottom], 8)
                    
                    HStack(spacing: 16) {
                        SocialIconView(image: Image(systemName: "photo.stack"), title: "Save image") {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }.foregroundStyle(.white)
                        
                        SocialIconView(image: Asset.instagram.swiftUIImage, title: "Instagram") {
                            viewModel.shareStickerImage(on: .instagram, with: image)
                        }
                        
                        SocialIconView(image: Asset.facebook.swiftUIImage, title: "Facebook") {
                            viewModel.shareStickerImage(on: .facebook, with: image)
                        }
                    }
                }
            )
    }
}

extension GameShareView {
    enum ViewConstants {
        static let overlayHeight: CGFloat = 150
        static let overlayCornerRadius: CGFloat = 12
        static let overlayOpacity: CGFloat = 0.3
        static let overlayPadding: CGFloat = 24
    }
}

#Preview {
    var gameShareView = GameShareUIView.loadFromNib()
    gameShareView?.configure(with: "123")
    
    return GameShareView(
        viewModel: GameShareViewModel(),
        image: gameShareView?.asImage() ?? UIImage())
}
