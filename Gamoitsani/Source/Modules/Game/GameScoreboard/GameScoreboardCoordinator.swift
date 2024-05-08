//
//  GameScoreboardCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameScoreboardCoordinator: BaseCoordinator {
    
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let gameScoreboardViewController = GameScoreboardViewController.loadFromNib()
        gameScoreboardViewController.viewModel = GameScoreboardViewModel()
        gameScoreboardViewController.coordinator = self
        
        if let presentationController = gameScoreboardViewController.presentationController as? UISheetPresentationController {
            presentationController.detents = [.custom(resolver: { context in 250 }), .medium(), .large()]
            presentationController.prefersGrabberVisible = true
        }

        navigationController.present(gameScoreboardViewController, animated: true)
    }
    
}
