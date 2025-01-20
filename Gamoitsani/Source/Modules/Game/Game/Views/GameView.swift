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
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @ObservedObject var viewModel = GameViewModel()
    
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack {
                    switch viewModel.gameState {
                    case .info:
                        gameInfoView
                    case .play:
                        gamePlayContent
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
                .background(Asset.gmSecondary.swiftUIColor.opacity(ViewConstants.backgroundOpacity))
                .cornerRadius(ViewConstants.cornerRadius)
                .padding(.horizontal, ViewConstants.paddingFromSuperview)
                
                Spacer()
                
                if verticalSizeClass == .regular && AppConstants.shouldShowAdsToUser {
                    BannerContainerView()
                        .padding()
                }
            }
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
    
    private var gamePlayContent: some View {
        Group {
            switch viewModel.gameMode {
            case .classic:
                classicGamePlayView
            case .arcade:
                arcadeGamePlayView
            }
        }
    }
    
    private var gameInfoView: some View {
        GameInfoView(viewModel: viewModel.createGameInfoViewModel()) {
            viewModel.gameState = .play
        } onShowScoreboard: {
            coordinator.presentGameScoreboard()
        }
    }
    
    private var classicGamePlayView: some View {
        ClassicGamePlayView(
            viewModel: viewModel.createClassicViewModel()
        ) { score in
            viewModel.handleGamePlayResult(score: score)
        }
    }
    
    private var arcadeGamePlayView: some View {
        ArcadeGamePlayView(
            viewModel: viewModel.createArcadeViewModel()
        ) { score in
            viewModel.handleGamePlayResult(score: score)
        }
    }
    
    private var gameOverView: some View {
        GameOverView(
            viewModel: viewModel.createGameOverViewModel()
        ) {
            stopConfetti()
            viewModel.showAd()
            withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
                viewModel.startNewGame()
            }
        } onGoBack: {
            stopConfetti()
            viewModel.showAd()
            coordinator.pop()
            viewModel.startNewGame()
        } onShowFullScoreboard: {
            coordinator.presentGameScoreboard(with: [.large()])
        }
        .onAppear {
            startConfetti()
        }
    }
    
    private var viewMaxHeight: CGFloat {
        if horizontalSizeClass == .compact {
            switch viewModel.gameState {
            case .gameOver:
                return ViewConstants.viewHeightBig
            case .play:
                return viewModel.gameMode == .arcade ? ViewConstants.viewHeightBig : ViewConstants.viewHeightSmall
            case .info:
                return ViewConstants.viewHeightSmall
            }
        }
        return .infinity
    }
    
    private func startConfetti() {
        if viewModel.gameState == .gameOver {
            showConfetti = true
        }
    }
    
    private func stopConfetti() {
        showConfetti = false
    }
}

// MARK: - ViewConstants
extension GameView {
    private enum ViewConstants {
        static let padding: CGFloat = 24
        static let paddingFromSuperview: CGFloat = 36
        static let backgroundOpacity: CGFloat = 0.3
        static let cornerRadius: CGFloat = 10
        static let viewHeightSmall: CGFloat = 400
        static let viewHeightBig: CGFloat = 600
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
}
