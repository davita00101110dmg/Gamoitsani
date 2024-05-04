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
    
    deinit {
        print("deinitialized \(self)")
    }
    
    override func start() {
        let gameSettingsViewController = GameSettingsViewController.loadFromNib()
        gameSettingsViewController.viewModel = GameSettingsViewModel()
        gameSettingsViewController.coordinator = self
        navigationController.pushViewController(gameSettingsViewController, animated: true)
    }
    
    func goToHome() {
        navigationController.popToRootViewController(animated: true)
        parentCoordinator?.childDidFinish(self)
    }
}
