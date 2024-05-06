//
//  GameCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameCoordinator: BaseCoordinator {
    
    var navigationController: UINavigationController?
    
    private var gameSettingsModel: GameSettingsModel
    
    init(navigationController: UINavigationController, gameSettingsModel: GameSettingsModel) {
        self.gameSettingsModel = gameSettingsModel
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let gameViewController = GameViewController.loadFromNib()
        gameViewController.viewModel = GameViewModel(gameSettingsModel: gameSettingsModel)
        gameViewController.coordinator = self
        navigationController.pushViewController(gameViewController, animated: true)
    }
    
    func goToHome() {
        guard let navigationController else { return }
        navigationController.popViewController(animated: true)
    }
}
