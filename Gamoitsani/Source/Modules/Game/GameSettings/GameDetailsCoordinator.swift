//
//  GameDetailsCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameDetailsCoordinator: BaseCoordinator {
    
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }

    override func start() {
        guard let navigationController else { return }
        let gameDetailsViewController = GameDetailsViewController.loadFromNib()
        gameDetailsViewController.viewModel = GameDetailsViewModel()
        gameDetailsViewController.coordinator = self
        navigationController.pushViewController(gameDetailsViewController, animated: true)
    }
    
    func navigateToGame() {
        guard let navigationController else { return }
        let gamesCoordinator = GameCoordinator(navigationController: navigationController)
        coordinate(to: gamesCoordinator)
    }
}
