//
//  GameViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

// MARK: - Review structure
final class GameViewController: BaseViewController<GameCoordinator> {
    
    @IBOutlet weak var mainView: UIView!
    
    var viewModel: GameViewModel?

    private var isShowingInfoView: Bool = false
    private var gameStory = GameStory.shared
    
    private lazy var gameInfoView: GameInfoView? = {
        GameInfoView.loadFromNib()
    }()
    
    private lazy var gamePlayView: GamePlayView? = {
        GamePlayView.loadFromNib()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackButton()
        showGameInfoView()
    }
    
    override func setupUI() {
        super.setupUI()
    }
    
    private func setupBackButton() {
        navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(title: "Back", image: UIImage(systemName: "chevron.backward"), target: self, action: #selector(presentAlertOnBackButton))
        navigationItem.leftBarButtonItem = backButton
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
    
    private func showGameInfoView() {
        guard let gameInfoView else { return }
        gameInfoView.configure(with: .init(
            teamName: gameStory.teams.keys[gameStory.currentTeamIndex],
            currentRound: gameStory.currentRound),
                               delegate: self)
        
        mainView.addSubview(gameInfoView)
    }
    
    private func showGamePlayView() {
        guard let gamePlayView else { return }
        gamePlayView.configure(with: .init(
            words: gameStory.words,
            roundLength: gameStory.lengthOfRound,
            score: gameStory.teams.values[gameStory.currentTeamIndex]), delegate: self)
        mainView.addSubview(gamePlayView)
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

        // TODO: Localization
        let alert = UIAlertController(title: "გილოცავთ \(winnerTeam.key)", message: "თქვენ გაიმარჯვეთ \(winnerTeam.value) ქულით", preferredStyle: .alert)
        
        alert.addAction(.init(title: "მადლობა!", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.coordinator?.goToHome()
        }))
        
        present(alert, animated: true)
    }
    
    private func updateGameInfo() {
        gameStory.currentTeamIndex = gameStory.playingSessionCount % gameStory.teams.count
        gameStory.currentRound = gameStory.playingSessionCount / gameStory.teams.count + 1
    }
    
    private func updateTeamScore(_ roundScore: Int) {
        gameStory.teams.values[gameStory.currentTeamIndex] = roundScore
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
        updateTeamScore(roundScore)
        dump("Round: \(gameStory.currentRound) Team: \(gameStory.teams.keys[gameStory.currentTeamIndex]) Score: \(gameStory.teams.values[gameStory.currentTeamIndex])")
        updateGameInfo()
        toggleView()
    }
}
