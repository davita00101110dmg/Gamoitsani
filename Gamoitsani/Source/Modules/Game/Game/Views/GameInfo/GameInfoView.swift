//
//  GameInfoView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameInfoView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var viewModel: GameInfoViewModel
    var onStart: () -> Void
    var onShowScoreboard: () -> Void

    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: ViewConstants.labelsSpacing) {
                roundCountLabel
                teamNameLabel
            }
            
            Spacer()
            
            startButton
            
            Spacer()
            Spacer()
            
            showScoreboardButton
        }
        .transitionHandler(duration: AppConstants.viewTransitionTime)
        .transition(.scale)
    }
    
    private var roundCountLabel: some View {
        GMLabelView(
            text: roundCountLabelText,
            fontSizeForPad: ViewConstants.labelFontSizeForPad
        )
    }
    
    private var teamNameLabel: some View {
        GMLabelView(
            text: viewModel.teamName,
            fontSizeForPad: ViewConstants.labelFontSizeForPad
        )
    }

    private var startButton: some View {
        GMButtonView(
            text: L10n.start,
            fontSizeForPad: ViewConstants.buttonFontSizeForPad,
            isCircle: true,
            height: circleButtonHeight
        ) {
            GameStory.shared.playingSessionCount += 1
            withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
                onStart()
            }
        }
    }
    
    private var showScoreboardButton: some View {
        GMButtonView(text: L10n.scoreboard, height: showScoreboardButtonHeight) {
            onShowScoreboard()
        }
    }
    
    private var roundCountLabelText: String {
        var text = L10n.Screen.Game.CurrentRound.message(viewModel.currentRound.toString)
        if let currentExtraRound = viewModel.currentExtraRound, currentExtraRound > 0 {
            text.append(String.whitespace)
            text.append(L10n.Screen.Game.CurrentExtraRound.message(currentExtraRound.toString))
        }
        return text
    }
    
    private var circleButtonHeight: CGFloat {
        horizontalSizeClass == .compact ? ViewConstants.circleButtonHeightForPhone : ViewConstants.circleButtonHeightForPad
    }
    
    private var showScoreboardButtonHeight: CGFloat {
        horizontalSizeClass == .compact ? ViewConstants.showScoreboardButtonHeightForPhone : ViewConstants.showScoreboardButtonHeightForPad
    }
}

// MARK: - View Constants
extension GameInfoView {
    enum ViewConstants {
        static let labelFontSizeForPad: CGFloat = 32
        static let buttonFontSizeForPad: CGFloat = 32
        static let circleButtonHeightForPhone: CGFloat = 100
        static let circleButtonHeightForPad: CGFloat = 200
        static let showScoreboardButtonHeightForPhone: CGFloat = 44
        static let showScoreboardButtonHeightForPad: CGFloat = 60
        static let labelsSpacing: CGFloat = 12
    }
}

#Preview {
    GameInfoView(viewModel: GameInfoViewModel(teamName: "გუნდი 1", currentRound: 1, currentExtraRound: nil)) {
        
    } onShowScoreboard: {
        
    }
    .padding([.top, .bottom, .leading, .trailing], 24)
    .frame(maxHeight: 400)
    .background(Asset.gmSecondary.swiftUIColor.opacity(0.3))
    .cornerRadius(10)
    .padding(.horizontal, 36)
    .padding(.vertical, 24)
}
