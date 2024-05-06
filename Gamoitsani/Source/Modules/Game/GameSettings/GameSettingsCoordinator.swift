//
//  GameSettingsCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameSettingsCoordinator: BaseCoordinator {
    
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }

    override func start() {
        guard let navigationController else { return }
        let gameSettingsViewController = GameSettingsViewController.loadFromNib()
        gameSettingsViewController.viewModel = GameSettingsViewModel()
        gameSettingsViewController.coordinator = self
        navigationController.pushViewController(gameSettingsViewController, animated: true)
    }
    
    func navigateToGame() {
        guard let navigationController else { return }
        let gamesCoordinator = GameCoordinator(navigationController: navigationController)
        coordinate(to: gamesCoordinator)
    }
}
