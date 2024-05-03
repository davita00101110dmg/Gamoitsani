//
//  HomeCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 22/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class HomeCoordinator: BaseCoordinator {

    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    deinit {
        print("deinitialized \(self)")
    }
    
    override func start() {
        let viewController = HomeViewController.loadFromNib()
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func navigateToRules() {
        let rulesCoordinator = RulesCoordinator(navigationController: navigationController)
        coordinate(to: rulesCoordinator)
    }
    
    func navigateToGameSettings() {
        let gameSettingsCoordinator = GameSettingsCoordinator(navigationController: navigationController)
        coordinate(to: gameSettingsCoordinator)
    }
}
