//
//  GameViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameViewController: BaseViewController<GameCoordinator> {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var mainViewHeightConstraint: NSLayoutConstraint!
    
    private var shouldShowInfoView: Bool = false
    private var gameStory = GameStory.shared
    
    private lazy var gameInfoView: GameInfoView? = {
        GameInfoView.loadFromNib()
    }()
    
    private lazy var gamePlayView: GamePlayView? = {
        GamePlayView.loadFromNib()
    }()
    
    private lazy var gameOverView: GameOverView? = {
        GameOverView.loadFromNib()
    }()
    
    private lazy var confettiLayer = CAEmitterLayer()
    private lazy var audioManager = AudioManager()
    
    var viewModel: GameViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackButton()
        showGameInfoView()
        configureAudioManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func setupBackButton() {
        let action = UIAction { [weak self] _ in
            self?.presentAlertOnBackButton()
        }
        
        navigationItem.backAction = action
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    private func configureAudioManager() {
        let operationQueue = OperationQueue()
        let audioSetupOperation = BlockOperation { [weak self] in
            self?.audioManager.setupSounds()
        }
        operationQueue.addOperation(audioSetupOperation)
    }
    
    private func showGameInfoView() {
        guard let gameInfoView,
              let viewModel else { return }
        gameInfoView.configure(with: .init(
            teamName: viewModel.currentTeamName,
            currentRound: viewModel.currentRound,
            currentExtraRound: viewModel.currentExtraRound),
                               delegate: self)
        
        gameInfoView.frame = mainView.bounds
        mainView.addSubview(gameInfoView)
    }
    
    private func showGamePlayView() {
        guard let gamePlayView else { return }
        gamePlayView.configure(with: .init(words: gameStory.words.removeFirstNItems(50),
                                           roundLength: gameStory.lengthOfRound,
                                           score: gameStory.teams.values[gameStory.currentTeamIndex]),
                               audioManager: audioManager,
                               delegate: self)
        gamePlayView.frame = mainView.bounds
        mainView.addSubview(gamePlayView)
    }
    
    private func showGameOverView(teamName: String, score: Int) {
        guard let gameOverView else { return }
        navigationController?.isNavigationBarHidden = true
        startConfettiAnimation()
        
        mainViewHeightConstraint.constant = 600
        
        gameOverView.configure(with: .init(teamName: teamName,
                                           score: score),
                               delegate: self)
        gameOverView.frame = mainView.bounds
        
        UIView.transition(with: mainView, duration: 0.5, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
            self.mainView.addSubview(gameOverView)
        })
    }
    
    private func toggleGameView() {
        mainView.removeAllSubviews()
        
        if viewModel?.handleEndOfGame() ?? false {
            presentGameOverView()
            return
        }
        
        toggleInfoView()
    }
    
    private func toggleInfoView() {
        shouldShowInfoView.toggle()
        if shouldShowInfoView {
            gameStory.playingSessionCount += 1
            showGamePlayView()
        } else {
            showGameInfoView()
        }
    }
    
    @objc private func presentAlertOnBackButton() {
        let alert = UIAlertController(title: L10n.Screen.Game.ConfirmationAlert.title,
                                      message: L10n.Screen.Game.ConfirmationAlert.message,
                                      preferredStyle: .alert)
        
        alert.addAction(.init(title: L10n.yesPolite,
                              style: .destructive) { [weak self] _ in
            guard let self else { return }
            gameStory.reset()
            self.coordinator?.pop()
        })
        
        alert.addAction(.init(title: L10n.no, style: .default))
        
        present(alert, animated: true)
    }
    
    private func presentGameOverView() {
        guard let sortedTeams = viewModel?.sortedTeams,
              let winnerTeam = sortedTeams.first else { return }
        
        gameStory.finishedGamesCountInSession += 1
        showGameOverView(teamName: winnerTeam.key, score: winnerTeam.value)
    }
    
    private func startConfettiAnimation() {
        confettiLayer.emitterPosition = .init(x: view.center.x, y: -view.frame.height/2)
        confettiLayer.opacity = 1
        
        let colors: [UIColor] = [
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
        
        let cells: [CAEmitterCell] = colors.compactMap {
            let cell = CAEmitterCell()
            cell.scale = ViewControllerConstants.cellScale
            cell.scaleRange = ViewControllerConstants.cellScaleRange
            cell.emissionRange = .pi * 2
            cell.lifetime = ViewControllerConstants.cellLifetime
            cell.birthRate = ViewControllerConstants.cellBirthRate
            cell.velocity = ViewControllerConstants.cellVelocity
            cell.velocityRange = ViewControllerConstants.cellVelocityRange
            cell.spin = ViewControllerConstants.cellSpin
            cell.spinRange = ViewControllerConstants.cellSpinRange
            cell.color = $0.cgColor
            cell.contents = Asset.confetti.image.cgImage
            return cell
        }
        
        let birthRateAnimation = CABasicAnimation(keyPath: ViewControllerConstants.birthRateAnimation)
        birthRateAnimation.fromValue = ViewControllerConstants.birthRateStartFromValue
        birthRateAnimation.toValue = ViewControllerConstants.birthRateStartToValue
        birthRateAnimation.duration = ViewControllerConstants.birthRateStartDuration
        birthRateAnimation.isRemovedOnCompletion = false
        
        confettiLayer.add(birthRateAnimation, forKey: ViewControllerConstants.birthRateAnimationKey)
        confettiLayer.emitterCells = cells
        view.layer.addSublayer(confettiLayer)
    }
    
    private func stopConfettiAnimation() {
        confettiLayer.removeAllAnimations()
        confettiLayer.removeFromSuperlayer()
        confettiLayer.emitterCells = nil
    }
    
    private func resetGameViewController() {
        navigationController?.isNavigationBarHidden = false
        stopConfettiAnimation()
        mainViewHeightConstraint.constant = 400
        gameStory.reset()
    }
}

// MARK: - GameInfoViewDelegate Methods
extension GameViewController: GameInfoViewDelegate {
    func didPressStart() {
        toggleGameView()
    }
    
    func didPressShowScoreboard() {
        coordinator?.presentGameScoreboard()
    }
}

// MARK: - GamePlayViewDelegate Methods
extension GameViewController: GamePlayViewDelegate {
    func timerDidFinished(roundScore: Int) {
        guard let viewModel else { return }
        viewModel.updateGameInfo(with: roundScore)
        toggleGameView()
    }
}

// MARK: - GameOverDelegate Methods
extension GameViewController: GameOverViewDelegate {
    func didPressStartOver() {
        resetGameViewController()
        toggleGameView()
    }
    
    func didPressGoBack() {
        stopConfettiAnimation()
        coordinator?.pop()
    }
    
    func didPressShowFullScoreboard() {
        coordinator?.presentGameScoreboard(with: [.large()])
    }
}
