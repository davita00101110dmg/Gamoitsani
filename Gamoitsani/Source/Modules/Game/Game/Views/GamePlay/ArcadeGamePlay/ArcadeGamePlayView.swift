//
//  ArcadeGamePlayView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct ArcadeGamePlayView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: ArcadeGamePlayViewModel
    
    @State var shaking: Bool = false
    
    init(viewModel: ArcadeGamePlayViewModel, onTimerFinished: @escaping (Int) -> Void) {
        self.viewModel = viewModel
        self.viewModel.onTimerFinished = onTimerFinished
    }
    
    var body: some View {
        VStack(spacing: ViewConstants.mainSpacing) {
            timerLabelWithFeedback
                .padding(.top, ViewConstants.timerTopPadding)
            
            Spacer()
            
            GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height
                
                wordsList(isLandscape: isLandscape)
            }
            
            skipButton
                .padding(.bottom)
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
    
    private func wordsList(isLandscape: Bool) -> some View {
        let columns = isLandscape ? [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ] : [
            GridItem(.flexible())
        ]
        
        return ScrollView {
            LazyVGrid(columns: columns, spacing: ViewConstants.wordsSpacing) {
                ForEach(viewModel.currentWords) { wordItem in
                    WordCardView(
                        word: wordItem.translation,
                        isGuessed: wordItem.isGuessed
                    ) {
                        if !wordItem.isGuessed {
                            viewModel.wordGuessed(id: wordItem.id)
                        }
                    }
                }
            }
            .padding(.vertical, ViewConstants.gridVerticalPadding)
        }
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
    
    private var skipButton: some View {
        GMButtonView(
            text: L10n.Screen.Game.Arcade.skipButton,
            fontSizeForPhone: ViewConstants.skipButtonFontSize,
            backgroundColor: Asset.gmRed.swiftUIColor.opacity(0.8),
            height: ViewConstants.skipButtonHeight
        ) {
            viewModel.skipCurrentSet()
        }
    }
    
    private enum ViewConstants {
        static let mainSpacing: CGFloat = 12 
        static let timerLabelFontSizeForPhone: CGFloat = 84
        static let timerLabelFontSizeForPad: CGFloat = 140
        static let skipButtonFontSize: CGFloat = 16
        static let skipButtonHeight: CGFloat = 44
        static let wordsSpacing: CGFloat = 16
        static let gridVerticalPadding: CGFloat = 8
        static let timerTopPadding: CGFloat = 16
    }
}
