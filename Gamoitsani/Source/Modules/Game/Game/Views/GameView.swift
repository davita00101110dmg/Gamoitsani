//
//  GameView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject private var coordinator: GameCoordinator
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel = GameViewModel()
    
    @State private var showConfetti = false
    
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
                            Image(systemName: AppConstants.SFSymbol.squareAndArrowUp)
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
        .displayConfetti(isActive: $showConfetti)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadAd()
        }
        .onDisappear {
            viewModel.startNewGame()
            coordinator.childDidFinish(coordinator)
            stopConfetti()
        }
    }
    
    private func startConfetti() {
        showConfetti = true
    }
    
    private func stopConfetti() {
        showConfetti = false
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
            viewModel.showAd()
            withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
                viewModel.startNewGame()
            }
            stopConfetti()
        } onGoBack: {
            viewModel.showAd()
            coordinator.pop()
            viewModel.startNewGame()
            stopConfetti()
        } onShowFullScoreboard: {
            coordinator.presentGameScoreboard(with: [.large()])
        }
        .onAppear {
            startConfetti()
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
}

#Preview {
    let mockViewModel = GameViewModel()
    let mockCoordinator = GameCoordinator(navigationController: UINavigationController())
    
    let teams = ["Team A", "Team B"]
    
    GameStory.shared.teams = .init(uniqueKeysWithValues: teams.map { ($0, 0) })
    
    return GameView(viewModel: mockViewModel)
        .environmentObject(mockCoordinator)
        .onAppear {
            mockViewModel.gameState = .gameOver
        }
        .previewDisplayName("Game Over State")
}
