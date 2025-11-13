//
//  GameView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    var gameStory: GameStory
    @StateObject private var viewModel = GameViewModel()

    @State private var showConfetti = false
    @State private var isRecordingEnabled = false
    
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
                    case .challenge:
                        challengeView
                    case .countdown:
                        countdownView
                    case .play:
                        gamePlayContent
                    case .gameOver:
                        gameOverView
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            presentGoBackAlert()
                        } label: {
                            Image(systemName: AppConstants.SFSymbol.flagCheckeredTwoCrossed)
                                .foregroundColor(.white)
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        if viewModel.gameState == .gameOver {
                            Button {
                                coordinator.presentSheet(.gameShare(gameStory))
                            } label: {
                                Image(systemName: AppConstants.SFSymbol.squareAndArrowUp)
                                    .foregroundColor(.white)
                            }
                        } else {
                            Button {
                                handleRecordingButtonTap()
                            } label: {
                                Image(systemName: AppConstants.SFSymbol.personCropSquareBadgeVideo)
                                    .foregroundColor(GameRecordingManager.shared.isRecordingEnabled ? .red : .white)
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
            
            DraggableCameraPreview()
        }
        .displayConfetti(isActive: $showConfetti)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadAd()
            GameRecordingManager.shared.startGameRecording()
            isRecordingEnabled = GameRecordingManager.shared.isRecordingEnabled
        }
        .onReceive(GameRecordingManager.shared.$isRecordingEnabled) { enabled in
            isRecordingEnabled = enabled
        }
        .onDisappear {
            viewModel.startNewGame()
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
            viewModel.startPlaying()
        } onShowScoreboard: {
            coordinator.presentSheet(.gameScoreboard(gameStory))
        }
    }
    
    private var challengeView: some View {
        GameChallengeView(viewModel: viewModel.createGameChallengeViewModel()) {
            viewModel.startCountdownAfterChallenge()
        }
    }
    
    private var countdownView: some View {
        CountdownView(
            currentCount: $viewModel.countdownValue,
            onComplete: {
                viewModel.startGameAfterCountdown()
            },
            audioManager: viewModel.audioManager
        )
    }
    
    private var classicGamePlayView: some View {
        ClassicGamePlayView(
            viewModel: viewModel.createClassicViewModel()
        ) { roundStats in
            viewModel.handleGamePlayResult(
                score: roundStats.score,
                wasSkipped: roundStats.wordsSkipped,
                wordsGuessed: roundStats.wordsGuessed
            )
        }
    }
    
    private var arcadeGamePlayView: some View {
        ArcadeGamePlayView(
            viewModel: viewModel.createArcadeViewModel()
        ) { roundStats in
            viewModel.handleGamePlayResult(
                score: roundStats.score,
                wasSkipped: roundStats.wordsSkipped,
                wordsGuessed: roundStats.wordsGuessed
            )
        }
    }
    
    private var gameOverView: some View {
        GameOverView(
            viewModel: viewModel.createGameOverViewModel()
        ) {
            stopConfetti()
            viewModel.showAd()
            withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
                viewModel.startNewGameWithRecording()
            }
        } onGoBack: {
            stopConfetti()
            viewModel.showAd()
            coordinator.dismissFullScreen()
            viewModel.startNewGame()
        } onShowFullScoreboard: {
            coordinator.presentSheet(.gameScoreboard(gameStory))
        }
        .onAppear {
            startConfetti()
        }
    }
    
    private var viewMaxHeight: CGFloat {
        if horizontalSizeClass == .compact {
            switch viewModel.gameState {
            case .gameOver, .challenge:
                return ViewConstants.viewHeightBig
            case .play:
                return viewModel.gameMode == .arcade ? ViewConstants.viewHeightBig : ViewConstants.viewHeightSmall
            case .info, .countdown:
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

    private func presentGoBackAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        let alert = UIAlertController(
            title: L10n.Screen.Game.ConfirmationAlert.title,
            message: L10n.Screen.Game.ConfirmationAlert.message,
            preferredStyle: .alert
        )

        alert.addAction(.init(title: L10n.yesPolite, style: .destructive) { [weak coordinator] _ in
            coordinator?.dismissFullScreen()
        })

        alert.addAction(.init(title: L10n.no, style: .cancel))

        rootViewController.present(alert, animated: true)
    }

    private func handleRecordingButtonTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        if GameRecordingManager.shared.isRecording {
            presentStopRecordingAlert()
        } else {
            GameRecordingManager.shared.setRecordingEnabled(true)
            GameRecordingManager.shared.startGameRecording()
        }

        impactFeedback.prepare()
    }

    private func presentStopRecordingAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        let alert = UIAlertController(
            title: L10n.Screen.GamePlay.Alert.StopRecording.title,
            message: L10n.Screen.GamePlay.Alert.StopRecording.message,
            preferredStyle: .alert
        )

        alert.addAction(.init(title: L10n.yesPolite, style: .destructive) { _ in
            GameRecordingManager.shared.stopGameRecording()
            GameRecordingManager.shared.setRecordingEnabled(false)
        })

        alert.addAction(.init(title: L10n.cancel, style: .cancel))

        rootViewController.present(alert, animated: true)
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
        static let rainbowBorderWidth: CGFloat = 4
    }
}

#Preview {
    let mockViewModel = GameViewModel()
    let mockCoordinator = GameCoordinator(navigationController: UINavigationController())
    
    let teams = ["Team A", "Team B"]
    
    GameStory.shared.setTeams([.init(name: "Team 1"), .init(name: "Team 2")])
    
    return GameView(viewModel: mockViewModel)
        .environmentObject(mockCoordinator)
        .onAppear {
            mockViewModel.gameState = .gameOver
        }
}
