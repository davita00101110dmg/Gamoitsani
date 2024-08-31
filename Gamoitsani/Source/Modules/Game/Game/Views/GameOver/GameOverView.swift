//
//  GameOverView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameOverView: View {
    @State var isDisable: Bool = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var viewModel: GameOverViewModel
    var onStartOver: () -> Void
    var onGoBack: () -> Void
    var onShowFullScoreboard: () -> Void

    var body: some View {
        DynamicStack(spacing: dynamicStackSpacing) {
            VStack {
                Spacer()
                
                titleLabel
                
                Spacer()
                
                trophyImage
            
                Spacer()
                
                VStack(spacing: ViewConstants.labelsSpacing) {
                    teamNameLabel
                    messageLabel
                }
                
                Spacer()
            }
            
            VStack(spacing: ViewConstants.buttonsSpacing) {
                repeatButton
                goBackButton
                showScoreboardButton
            }
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
    
    private var trophyImage: some View {
        Image(.trophy)
            .resizable()
            .scaledToFit()
            .frame(width: trophyIconSize)
    }
    
    private var teamNameLabel: some View {
        GMLabelView(
            text: viewModel.teamName,
            fontSizeForPhone: ViewConstants.teamLabelFontSizeForPhone,
            fontSizeForPad: ViewConstants.teamLabelFontSizeForPad
        )
    }
    
    private var messageLabel: some View {
        GMLabelView(
            text: L10n.Screen.Game.WinningView.description(viewModel.score.toString),
            fontSizeForPhone: ViewConstants.descriptionLabelFontSizeForPhone,
            fontSizeForPad: ViewConstants.descriptionLabelFontSizeForPad
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
    
    private var trophyIconSize: CGFloat {
        horizontalSizeClass == .compact ? ViewConstants.trophyIconSizeForPhone : ViewConstants.trophyIconSizeForPad
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
        static let teamLabelFontSizeForPhone: CGFloat = 22
        static let teamLabelFontSizeForPad: CGFloat = 40
        static let descriptionLabelFontSizeForPhone: CGFloat = 18
        static let descriptionLabelFontSizeForPad: CGFloat = 32
        static let trophyIconSize: CGFloat = 175
        static let trophyIconSizeForPhone: CGFloat = 175
        static let trophyIconSizeForPad: CGFloat = 325
        static let buttonHeightForPhone: CGFloat = 44
        static let buttonHeightForPad: CGFloat = 60
        static let dynamicStackSpacingForPhone: CGFloat = 32
        static let dynamicStackSpacingForPad: CGFloat = 0
        static let labelsSpacing: CGFloat = 12
        static let buttonsSpacing: CGFloat = 16
    }
}

#Preview {
    GameOverView(viewModel: GameOverViewModel(teamName: "გუნდი 1", score: 1)) {
 
    } onGoBack: {
        
    } onShowFullScoreboard: {
        
    }
    .background(Asset.secondary.swiftUIColor.opacity(0.3))
    .cornerRadius(10)
    .frame(maxHeight: .infinity)
    .padding(.horizontal, 36)
    .padding(.vertical, 24)
}
