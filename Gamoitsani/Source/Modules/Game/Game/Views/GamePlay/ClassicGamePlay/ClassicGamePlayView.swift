//
//  GamePlayView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct ClassicGamePlayView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: ClassicGamePlayViewModel
    
    @State var shaking: Bool = false
    
    init(viewModel: ClassicGamePlayViewModel, onTimerFinished: @escaping (Int) -> Void) {
        self.viewModel = viewModel
        self.viewModel.onTimerFinished = onTimerFinished
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            currentWordLabel
            
            Spacer()
            
            timerLabelWithFeedback
            
            Spacer()
            
            HStack {
                incorrectButton
                
                Spacer()
                
                correctButton
            }
            
        }
        .transitionHandler(duration: AppConstants.viewTransitionTime)
        .onAppear {
            viewModel.startGame()
        }
        .onDisappear {
            viewModel.stopGame()
        }
        .transition(.scale)
    }
    
    private var currentWordLabel: some View {
        GMLabelView(
            text: viewModel.currentWord,
            fontType: .bold,
            fontSizeForPhone: ViewConstants.wordLabelFontSizeForPhone,
            fontSizeForPad: ViewConstants.wordLabelFontSizeForPad
        )
    }
    
    private var timerLabelWithFeedback: some View {
        let isWarning = viewModel.timeRemaining <= 5
        let timerLabelView = GMLabelView(
            text: viewModel.timeRemaining.toString(),
            fontSizeForPhone: ViewConstants.timerLabelFontSizeForPhone,
            fontSizeForPad: ViewConstants.timerLabelFontSizeForPad,
            color: isWarning ? Asset.gmRed.swiftUIColor : .white
        )
            .contentTransition(.numericText())
            .animation(.linear, value: viewModel.timeRemaining)

        if #available(iOS 17.0, *) {
            return timerLabelView
                .onChange(of: viewModel.timeRemaining, { oldValue, newValue in
                    if newValue <= 5 {
                        withAnimation(.easeInOut) {
                            shaking.toggle()
                        }
                    }
                })
                .modifier(ShakeEffect(animatableData: CGFloat(shaking ? 1 : 0)))
                .sensoryFeedback(.warning, trigger: viewModel.timeRemaining) { _, newValue in
                    newValue <= 5
                }
        } else {
            return timerLabelView
        }
    }
    
    private var incorrectButton: some View {
        makeButton(text: ViewConstants.incorrectSymbol, color: Asset.gmRed.swiftUIColor, tag: 0)
    }
    
    private var correctButton: some View {
        makeButton(text: ViewConstants.correctSymbol, color: Asset.gmGreen.swiftUIColor, tag: 1)
    }
    
    private func makeButton(text: String, color: Color, tag: Int) -> some View {
        GMButtonView(
            text: text,
            fontSizeForPhone: ViewConstants.buttonFontSizeForPhone,
            fontSizeForPad: ViewConstants.buttonFontSizeForPad,
            isCircle: true,
            backgroundColor: color,
            height: horizontalSizeClass == .compact ? ViewConstants.buttonHeight : ViewConstants.buttonHeightForIpad,
            shouldLowerOpacityOnPress: false,
            shouldScaleOnPress: true
        ) {
            viewModel.wordButtonAction(tag: tag)
        }
    }
}

// MARK: - View Constants
extension ClassicGamePlayView {
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
    ClassicGamePlayView(viewModel: ClassicGamePlayViewModel(words: GameStory.shared.words, roundLength: 60, audioManager: AudioManager())) { _ in
        
    }
    .padding([.top, .bottom, .leading, .trailing], 24)
    .background(
        Asset.gmSecondary.swiftUIColor
            .opacity(0.3)
    )
    .cornerRadius(10)
    .frame(maxHeight: .infinity)
    .padding(.horizontal, 36)
    .padding(.vertical, 24)
}
