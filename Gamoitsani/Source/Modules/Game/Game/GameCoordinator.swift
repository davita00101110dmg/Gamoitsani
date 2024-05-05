//
//  GameCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameCoordinator: BaseCoordinator {
    
    private var gameSettingsModel: GameSettingsModel
    
    init(navigationController: UINavigationController, gameSettingsModel: GameSettingsModel) {
        self.gameSettingsModel = gameSettingsModel
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        let gameViewController = GameViewController.loadFromNib()
        gameViewController.viewModel = GameViewModel(gameSettingsModel: gameSettingsModel)
        gameViewController.coordinator = self
        navigationController.delegate = self
        navigationController.pushViewController(gameViewController, animated: true)
    }
}
