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
    
    var viewModel: GameViewModel?
    
    private var isShowingDashboard: Bool = false
    private var playingSessionCount = 0
    
    private var mockedTeam = "ხარება და გოგია"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackButton()
        showGameInfoView()
    }
    
    private func setupBackButton() {
        navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(title: "Back", image: UIImage(systemName: "chevron.backward"), target: self, action: #selector(presentAlertOnBackButton))
        navigationItem.leftBarButtonItem = backButton
    }

    private func toggleView() {
        mainView.removeAllSubviews()
        isShowingDashboard.toggle()
        if isShowingDashboard {
            showGamePlayView()
        } else {
            showGameInfoView()
        }
    }
    
    // TODO: Review! For now like this
    private func showGameInfoView() {
        guard let gameInfoView = GameInfoView.loadFromNib() else { return }
        gameInfoView.configure(with: .init(teamName: mockedTeam, currentRound: viewModel?.gameSettingsModel.currentRound ?? 0), delegate: self)
        mainView.addSubview(gameInfoView)
    }
    
    // TODO: Review! For now like this
    private func showGamePlayView() {
        guard let gamePlayView = GamePlayView.loadFromNib() else { return }
        gamePlayView.configure(with: .init(words: ["სიტყვა", "წაგება", "მოგება"], roundLength: viewModel?.gameSettingsModel.lengthOfRound ?? 0, score: viewModel?.gameSettingsModel.teams[mockedTeam] ?? 0), delegate: self) // score: viewModel.gameSettingsModel.teams[currentTeam]
        playingSessionCount += 1
        mainView.addSubview(gamePlayView)
    }
    
    // TODO: Implement custom back bar button to call this action
    @objc private func presentAlertOnBackButton() {
        // TODO: Localization
        let alert = UIAlertController(title: "დარწმუნებული ხარ რომ უკან დაბრუნება გინდა?", message: "ამ შემთხვევაში თამაშის სესია მორჩება.", preferredStyle: .alert)
        
        alert.addAction(.init(title: "დიახ", style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            self.coordinator?.goToHome()
        }))
        
        alert.addAction(.init(title: "არა", style: .default))
        
        present(alert, animated: true)
    }
}

extension GameViewController: GameInfoViewDelegate {
    func didPressStart() {
        toggleView()
    }
}

extension GameViewController: GamePlayViewDelegate {
    func timerDidFinished(roundScore: Int) {
        toggleView()
//        viewModel.updateModel()
        viewModel?.gameSettingsModel.teams[mockedTeam] = roundScore // currentTeam
    }
}
