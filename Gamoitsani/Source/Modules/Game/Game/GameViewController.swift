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
    
    private var isShowingInfoView: Bool = false
    private var gameStory = GameStory.shared
    
    private lazy var gameInfoView: GameInfoView? = {
        GameInfoView.loadFromNib()
    }()
    
    private lazy var gamePlayView: GamePlayView? = {
        GamePlayView.loadFromNib()
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
        stopConfettiAnimation()
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
        guard let gameInfoView else { return }
        gameInfoView.configure(with: .init(
            teamName: gameStory.teams.keys[gameStory.currentTeamIndex],
            currentRound: gameStory.currentRound),
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
    
    private func validateEndOfTheGame() -> Bool {
        gameStory.currentRound > gameStory.numberOfRounds
    }

    private func toggleView() {
        mainView.removeAllSubviews()
        
        if validateEndOfTheGame() {
            presentGameOverAlert()
        } else {
            isShowingInfoView.toggle()
            
            if isShowingInfoView {
                gameStory.playingSessionCount += 1
                showGamePlayView()
            } else {
                showGameInfoView()
            }
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
            self.coordinator?.goToHome()
        })
        
        alert.addAction(.init(title: L10n.no, style: .default))
        
        present(alert, animated: true)
    }
    
    private func presentGameOverAlert() {
        let sortedTeams = gameStory.teams.sorted { l, r in
            l.value > r.value
        }
        
        guard let winnerTeam = sortedTeams.first else { return }
        
        let alert = UIAlertController(title: L10n.Screen.Game.WinningAlert.title(winnerTeam.key),
                                      message: L10n.Screen.Game.WinningAlert.message(winnerTeam.value.toString),
                                      preferredStyle: .alert)
        
        alert.addAction(.init(title: L10n.thanks, style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.coordinator?.goToHome()
        }))
        
        present(alert, animated: true)
        
        startConfettiAnimation()
    }
    
    private func updateGameInfo(_ roundScore: Int) {
        gameStory.teams.values[gameStory.currentTeamIndex] = roundScore
        dump("Round: \(gameStory.currentRound) Team: \(gameStory.teams.keys[gameStory.currentTeamIndex]) Score: \(gameStory.teams.values[gameStory.currentTeamIndex])")
        gameStory.currentTeamIndex = gameStory.playingSessionCount % gameStory.teams.count
        gameStory.currentRound = gameStory.playingSessionCount / gameStory.teams.count + 1
    }
    
    private func startConfettiAnimation() {
        confettiLayer.emitterPosition = .init(x: view.center.x, y: -view.frame.height)
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
            cell.scale = 0.5
            cell.emissionRange = .pi * 2
            cell.lifetime = 20
            cell.birthRate = 250
            cell.velocity = 250
            cell.color = $0.cgColor
            cell.contents = Asset.confetti.image.cgImage
            return cell
        }
        
        confettiLayer.emitterCells = cells
        
        view.layer.addSublayer(confettiLayer)
    }
    
    private func stopConfettiAnimation() {
        confettiLayer.removeFromSuperlayer()
    }
}

// MARK: - GameInfoViewDelegate Methods
extension GameViewController: GameInfoViewDelegate {
    func didPressStart() {
        toggleView()
    }
    
    func didPressShowScoreboard() {
        coordinator?.presentGameScoreboard()
    }
}

// MARK: - GamePlayViewDelegate Methods
extension GameViewController: GamePlayViewDelegate {
    func timerDidFinished(roundScore: Int) {
        updateGameInfo(roundScore)
        toggleView()
    }
}
