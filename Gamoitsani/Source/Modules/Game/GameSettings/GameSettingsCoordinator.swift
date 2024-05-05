//
//  GameSettingsCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameSettingsCoordinator: BaseCoordinator {
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }

    override func start() {
        let gameSettingsViewController = GameSettingsViewController.loadFromNib()
        gameSettingsViewController.viewModel = GameSettingsViewModel()
        gameSettingsViewController.coordinator = self
        navigationController.delegate = self
        navigationController.pushViewController(gameSettingsViewController, animated: true)
    }
    
    func navigateToGame(_ gameSettingsModel: GameSettingsModel) {
        let gamesCoordinator = GameCoordinator(navigationController: navigationController, gameSettingsModel: gameSettingsModel)
        coordinate(to: gamesCoordinator)
    }
}
