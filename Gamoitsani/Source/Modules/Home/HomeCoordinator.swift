//
//  HomeCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 22/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class HomeCoordinator: BaseCoordinator {

    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }

    override func start() {
        guard let navigationController else { return }
        let viewController = HomeViewController.loadFromNib()
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func navigateToRules() {
        guard let navigationController else { return }
        let rulesCoordinator = RulesCoordinator(navigationController: navigationController)
        coordinate(to: rulesCoordinator)
    }
    
    func navigateToGameDetails() {
        guard let navigationController else { return }
        let gameDetailsCoordinator = GameDetailsCoordinator(navigationController: navigationController)
        coordinate(to: gameDetailsCoordinator)
    }
    
    func navigateToAddWord() {
        guard let navigationController else { return }
        let addWordCoordinator = AddWordCoordinator(navigationController: navigationController)
        coordinate(to: addWordCoordinator)
    }
    
    func presentSettings() {
        guard let navigationController else { return }
        let settingsCoordinator = SettingsCoordinator(navigationController: navigationController)
        coordinate(to: settingsCoordinator)
    }

    func navigateToWordPacks() {
        guard let navigationController else { return }
        let wordPackCoordinator = WordPackCoordinator(navigationController: navigationController)
        coordinate(to: wordPackCoordinator)
    }
}
