//
//  GamePlayView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GamePlayView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: GamePlayViewModel
    
    init(viewModel: GamePlayViewModel, onTimerFinished: @escaping (Int) -> Void) {
        self.viewModel = viewModel
        self.viewModel.onTimerFinished = onTimerFinished
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            currentWordLabel
            
            Spacer()
            
            timerLabel

            Spacer()
            
            HStack {
                incorrectButton
                
                Spacer()
                
                correctButton
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .onDisappear {
            viewModel.stopGame()
        }
    }
    
    private var currentWordLabel: some View {
        GMLabelView(
            text: viewModel.currentWord,
            fontType: .bold,
            fontSizeForPhone: ViewConstants.wordLabelFontSizeForPhone,
            fontSizeForPad: ViewConstants.wordLabelFontSizeForPad
        )
    }
    
    private var timerLabel: some View {
        GMLabelView(
            text: viewModel.timeRemaining.toString(),
            fontSizeForPhone: ViewConstants.timerLabelFontSizeForPhone,
            fontSizeForPad: ViewConstants.timerLabelFontSizeForPad
        )
    }
    
    private var incorrectButton: some View {
        GMButtonView(
            text: ViewConstants.incorrectSymbol,
            fontSizeForPhone: ViewConstants.buttonFontSizeForPhone,
            fontSizeForPad: ViewConstants.buttonFontSizeForPad,
            isCircle: true,
            backgroundColor: Asset.red.swiftUIColor,
            height: horizontalSizeClass == .compact ? ViewConstants.buttonHeight : ViewConstants.buttonHeightForIpad
        ) {
            viewModel.wordButtonAction(tag: 0) // Incorrect tag
        }
        
    }
    
    private var correctButton: some View {
        GMButtonView(
            text: ViewConstants.correctSymbol,
            fontSizeForPhone: ViewConstants.buttonFontSizeForPhone,
            fontSizeForPad: ViewConstants.buttonFontSizeForPad,
            isCircle: true,
            backgroundColor: Asset.green.swiftUIColor,
            height: horizontalSizeClass == .compact ? ViewConstants.buttonHeight : ViewConstants.buttonHeightForIpad
        ) {
            viewModel.wordButtonAction(tag: 1) // Correct tag
        }
    }
}

// MARK: - View Constants
extension GamePlayView {
    enum ViewConstants {
        static let correctSymbol: String = "✓"
        static let incorrectSymbol: String = "✘"
        static let wordLabelFontSizeForPhone: CGFloat = 32
        static let wordLabelFontSizeForPad: CGFloat = 52
        static let timerLabelFontSizeForPhone: CGFloat = 96
        static let timerLabelFontSizeForPad: CGFloat = 150
        static let buttonFontSizeForPhone: CGFloat = 30
        static let buttonFontSizeForPad: CGFloat = 60
        static let buttonHeight: CGFloat = 60
        static let buttonHeightForIpad: CGFloat = 120
    }
}

#Preview {
    GamePlayView(viewModel: GamePlayViewModel(words: GameStory.shared.words, roundLength: 60, audioManager: AudioManager())) { _ in
        
    }
    .padding([.top, .bottom, .leading, .trailing], 24)
    .background(
        Asset.secondary.swiftUIColor
            .opacity(0.3)
    )
    .cornerRadius(10)
    .frame(maxHeight: .infinity)
    .padding(.horizontal, 36)
    .padding(.vertical, 24)
}
