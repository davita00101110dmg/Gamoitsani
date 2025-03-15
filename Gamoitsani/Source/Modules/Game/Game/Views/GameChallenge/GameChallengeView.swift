//
//  GameChallengeView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 14/03/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameChallengeView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showChallenge = false
    @State private var showReadyButton = false
    @State private var isPortraitMode = false
    
    var viewModel: GameChallengeViewModel
    var onReady: () -> Void
    
    var body: some View {
        Group {
            DynamicStack(spacing: dynamicStackSpacing, isPortrait: $isPortraitMode) {
                headerSection
                Spacer()
                challengeCard
                if isPortraitMode {
                    Spacer()
                    Spacer()
                }
            }
            .padding()
            
            Spacer()
            
            readyButton
        }
        .transitionHandler(duration: AppConstants.viewTransitionTime)
        .transition(.scale)
        .onAppear {
            animateElements()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: ViewConstants.headerSpacing) {
            GMLabelView(
                text: L10n.Screen.Game.GameChallengeView.header,
                fontType: .semiBold,
                fontSizeForPhone: ViewConstants.titleFontSize
            )
            .opacity(showChallenge ? 1 : 0)
            
            GMLabelView(
                text: viewModel.teamName,
                fontType: .bold,
                fontSizeForPhone: ViewConstants.teamNameFontSize
            )
            .padding(.top, 4)
            .opacity(showChallenge ? 1 : 0)
        }
    }
    
    private var challengeCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ViewConstants.cardCornerRadius)
                .fill(Asset.gmSecondary.swiftUIColor)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            VStack(spacing: ViewConstants.cardContentSpacing) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding(.top, ViewConstants.iconPadding)
                
                GMLabelView(text: viewModel.challengeText)
                    .font(.system(size: ViewConstants.challengeFontSize))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, ViewConstants.challengeHorizontalPadding)
                    .padding(.bottom, ViewConstants.challengeBottomPadding)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: showChallenge ? nil : 0)
        .opacity(showChallenge ? 1 : 0)
        .scaleEffect(showChallenge ? 1 : 0.8)
    }
    
    private var readyButton: some View {
        GMButtonView(
            text: L10n.start,
            fontSizeForPhone: ViewConstants.buttonFontSize,
            backgroundColor: Asset.gmSecondary.swiftUIColor,
            height: readyButtonHeight,
            shouldScaleOnPress: true
        ) {
            withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
                onReady()
            }
        }
        .opacity(showReadyButton ? 1 : 0)
        .disabled(!showReadyButton)
        .scaleEffect(showReadyButton ? 1 : 0.8)
    }
    
    private func animateElements() {
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            showChallenge = true
        }
        
        withAnimation(.easeOut(duration: 0.3).delay(0.6)) {
            showReadyButton = true
        }
    }
    
    private var readyButtonHeight: CGFloat {
        isPortrait ? ViewConstants.readyButtonHeightForPhone : ViewConstants.readyButtonHeightForPad
    }
    
    private var dynamicStackSpacing: CGFloat {
        isPortrait ? ViewConstants.dynamicStackSpacingForPhone : ViewConstants.dynamicStackSpacingForPad
    }
    
    private var isPortrait: Bool {
        horizontalSizeClass == .compact
     }
}

// MARK: - View Constants
extension GameChallengeView {
    enum ViewConstants {
        static let mainSpacing: CGFloat = 24
        static let headerSpacing: CGFloat = 8
        static let cardContentSpacing: CGFloat = 16
        static let dynamicStackSpacingForPhone: CGFloat = 32
        static let dynamicStackSpacingForPad: CGFloat = 0
        
        static let titleFontSize: CGFloat = 16
        static let subtitleFontSize: CGFloat = 16
        static let teamNameFontSize: CGFloat = 24
        static let challengeFontSize: CGFloat = 18
        static let buttonFontSize: CGFloat = 18
        
        static let cardCornerRadius: CGFloat = 16
        static let minCardHeight: CGFloat = 200
        static let iconPadding: CGFloat = 24
        static let challengeHorizontalPadding: CGFloat = 24
        static let challengeBottomPadding: CGFloat = 24
        
        static let readyButtonHeightForPhone: CGFloat = 44
        static let readyButtonHeightForPad: CGFloat = 60
    }
}
