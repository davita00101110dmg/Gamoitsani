//
//  GameOverView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameOverView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showPodium = false

    var viewModel: GameOverViewModel
    var onStartOver: () -> Void
    var onGoBack: () -> Void
    var onShowFullScoreboard: () -> Void
    
    private var winner: Team? { viewModel.teams.first }
    private var secondPlace: Team? { viewModel.teams.count > 1 ? viewModel.teams[1] : nil }
    private var thirdPlace: Team? { viewModel.teams.count > 2 ? viewModel.teams[2] : nil }
    
    var body: some View {
        DynamicStack(spacing: dynamicStackSpacing) {
            VStack {
                Spacer()
                
                titleLabel
                
                Spacer()
                
                HStack(alignment: .bottom, spacing: 0) {
                    if let secondPlace {
                        VStack(spacing: 8) {
                            Image(systemName: "2.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                            
                            GMLabelView(text: secondPlace.name)
                                .font(F.Mersad.semiBold.swiftUIFont(size: 14))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            GMLabelView(text: secondPlace.score.toString)
                                .font(F.Mersad.bold.swiftUIFont(size: 18))
                                .foregroundColor(Asset.gmPrimary.swiftUIColor)
                            
                            Rectangle()
                                .fill(Asset.gmSecondary.swiftUIColor)
                                .frame(height: 100)
                        }
                        .frame(maxWidth: .infinity)
                        .offset(y: showPodium ? 0 : 100)
                        .opacity(showPodium ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(0.6),
                            value: showPodium
                        )
                    }
                    
                    if let winner {
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Asset.gmPrimary.swiftUIColor)
                            
                            GMLabelView(text: winner.name)
                                .font(F.Mersad.bold.swiftUIFont(size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            GMLabelView(text: winner.score.toString)
                                .font(F.Mersad.bold.swiftUIFont(size: 24))
                                .foregroundColor(Asset.gmPrimary.swiftUIColor)
                            
                            Rectangle()
                                .fill(Asset.gmPrimary.swiftUIColor)
                                .frame(height: 140)
                        }
                        .frame(maxWidth: .infinity)
                        .zIndex(1)
                        .offset(y: showPodium ? 0 : 100)
                        .opacity(showPodium ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(0.3),
                            value: showPodium
                        )
                    }
                    
                    if let thirdPlace {
                        VStack(spacing: 8) {
                            Image(systemName: "3.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.6))
                            
                            GMLabelView(text: thirdPlace.name)
                                .font(F.Mersad.semiBold.swiftUIFont(size: 14))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            GMLabelView(text: thirdPlace.score.toString)
                                .font(F.Mersad.bold.swiftUIFont(size: 18))
                                .foregroundColor(Asset.gmPrimary.swiftUIColor)
                            
                            Rectangle()
                                .fill(Asset.gmSecondary.swiftUIColor)
                                .frame(height: 70)
                        }
                        .frame(maxWidth: .infinity)
                        .offset(y: showPodium ? 0 : 100)
                        .opacity(showPodium ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(0.9),
                            value: showPodium
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            
            VStack(spacing: ViewConstants.buttonsSpacing) {
                repeatButton
                goBackButton
                showScoreboardButton
            }
        }
        .onAppear {
            showPodium = true
        }
        .transitionHandler(duration: AppConstants.viewTransitionTime)
    }
    
    private var titleLabel: some View {
        GMLabelView(
            text: L10n.Screen.Game.WinningView.title,
            fontSizeForPhone: ViewConstants.winLabelFontSizeForPhone,
            fontSizeForPad: ViewConstants.winLabelFontSizeForPad
        )
    }
    
    private var repeatButton: some View {
        GMButtonView(
            text: L10n.Screen.Game.WinningView.repeat,
            height: buttonHeight
        ) {
            withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
                onStartOver()
            }
        }
    }
    
    private var goBackButton: some View {
        GMButtonView(
            text: L10n.Screen.Game.WinningView.GameDetails.title,
            height: buttonHeight
        ) {
            onGoBack()
        }
    }
    
    private var showScoreboardButton: some View {
        GMButtonView(
            text: L10n.scoreboard,
            height: buttonHeight
        ) {
            onShowFullScoreboard()
        }
    }
    
    private var buttonHeight: CGFloat {
        horizontalSizeClass == .compact ? ViewConstants.buttonHeightForPhone : ViewConstants.buttonHeightForPad
    }
    
    private var dynamicStackSpacing: CGFloat {
        horizontalSizeClass == .compact ? ViewConstants.dynamicStackSpacingForPhone : ViewConstants.dynamicStackSpacingForPad
    }
}

// MARK: - View Constants
extension GameOverView {
    enum ViewConstants {
        static let winLabelFontSizeForPhone: CGFloat = 40
        static let winLabelFontSizeForPad: CGFloat = 74
        static let buttonHeightForPhone: CGFloat = 44
        static let buttonHeightForPad: CGFloat = 60
        static let dynamicStackSpacingForPhone: CGFloat = 32
        static let dynamicStackSpacingForPad: CGFloat = 0
        static let buttonsSpacing: CGFloat = 16
    }
}

#Preview {
    GameOverView(
        viewModel: GameOverViewModel(
            teams: [
                .init(name: "Team 1", score: 10),
                .init(name: "Team 2", score: 8),
                .init(name: "Team 3", score: 6)
            ]
        ),
        onStartOver: {},
        onGoBack: {},
        onShowFullScoreboard: {}
    )
    .background(Asset.gmSecondary.swiftUIColor.opacity(0.3))
    .cornerRadius(10)
    .frame(maxHeight: .infinity)
    .padding(.horizontal, 36)
    .padding(.vertical, 24)
}
