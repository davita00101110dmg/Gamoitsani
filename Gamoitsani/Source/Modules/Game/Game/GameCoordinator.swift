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
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let gameViewController = GameViewController.loadFromNib()
        gameViewController.viewModel = GameViewModel()
        gameViewController.coordinator = self
        navigationController.pushViewController(gameViewController, animated: true)
    }
    
    func pop() {
        guard let navigationController else { return }
        navigationController.popViewController(animated: true)
    }
    
    func presentGameScoreboard(with detents: [UISheetPresentationController.Detent] = UIDevice.current.userInterfaceIdiom != .pad
                               ? [.custom(resolver: { context in 250 }), .medium(), .large()]
                               : [.medium(), .large()]) {
        guard let navigationController else { return }
        
        let gameScoreboardCoordinator = GameScoreboardCoordinator(navigationController: navigationController, detents: detents)
        coordinate(to: gameScoreboardCoordinator)
    }
}
