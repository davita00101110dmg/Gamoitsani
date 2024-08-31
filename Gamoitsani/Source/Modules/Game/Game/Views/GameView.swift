//
//  GameView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import GoogleMobileAds

struct GameView: View {
    @EnvironmentObject private var coordinator: GameCoordinator
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel = GameViewModel()
    
    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            VStack {
                switch viewModel.gameState {
                case .info:
                    gameInfoView
                case .play:
                    gamePlayView
                case .gameOver:
                    gameOverView
                }
            }
            .toolbar {
                if viewModel.gameState == .gameOver {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            coordinator.presentGameShareView(with: viewModel.generateShareImage())
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .padding([.top, .bottom, .leading, .trailing], ViewConstants.padding)
            .frame(maxHeight: viewMaxHeight)
            .background(Asset.secondary.swiftUIColor.opacity(ViewConstants.backgroundOpacity))
            .cornerRadius(ViewConstants.cornerRadius)
            .padding(.horizontal, ViewConstants.paddingFromSuperview)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadAd()
        }
        .onDisappear {
            viewModel.startNewGame()
            coordinator.childDidFinish(coordinator)
        }
    }
    
    private var gameInfoView: some View {
        GameInfoView(viewModel: viewModel.gameInfoViewModel) {
            viewModel.gameState = .play
        } onShowScoreboard: {
            coordinator.presentGameScoreboard()
        }
    }
    
    private var gamePlayView: some View {
        GamePlayView(
            viewModel: viewModel.gamePlayViewModel
        ) { score in
            viewModel.handleGamePlayResult(score: score)
        }
    }
    
    private var gameOverView: some View {
        GameOverView(
            viewModel: viewModel.gameOverViewModel
        ) {
            // TODO: Remove if i won't need it
        } onStartOver: {
            viewModel.showAd()
            withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
                viewModel.startNewGame()
            }
        } onGoBack: {
            viewModel.showAd()
            coordinator.pop()
            viewModel.startNewGame()
        } onShowFullScoreboard: {
            coordinator.presentGameScoreboard(with: [.large()])
        }
    }
    
    private var viewMaxHeight: CGFloat {
        horizontalSizeClass == .compact ? viewModel.gameState == .gameOver ? ViewConstants.gameOverViewHeight : ViewConstants.viewHeight : .infinity
    }
}

// MARK: - ViewConstants
extension GameView {
    private enum ViewConstants {
        static let padding: CGFloat = 24
        static let paddingFromSuperview: CGFloat = 36
        static let backgroundOpacity: CGFloat = 0.3
        static let cornerRadius: CGFloat = 10
        static let viewHeight: CGFloat = 400
        static let gameOverViewHeight: CGFloat = 600
    }
    
    // TODO: Leave what i will need
    enum ViewControllerConstants {
        static let cellScale: CGFloat = 0.5
        static let cellScaleRange: CGFloat = 0.1
        static let cellLifetime: Float = 30
        static let cellBirthRate: Float = 5
        static let cellVelocity: CGFloat = 250
        static let cellVelocityRange: CGFloat = 150
        static let cellSpin: CGFloat = 5
        static let cellSpinRange: CGFloat = 2.5
        static let birthRateStartFromValue: Float = 1
        static let birthRateStartToValue: Float = 200
        static let birthRateStartDuration: CFTimeInterval = 5
        static let birthRateAnimation: String = "birthRate"
        static let birthRateAnimationKey: String = "birthRateAnimation"
        static let confettiColors: [UIColor] = [
            Asset.color1.color,
            Asset.color2.color,
            Asset.color3.color,
            Asset.color4.color,
            Asset.color5.color,
            Asset.color6.color,
            Asset.color7.color,
            Asset.color8.color,
            Asset.color9.color,
            Asset.color10.color
        ]
    }
}
