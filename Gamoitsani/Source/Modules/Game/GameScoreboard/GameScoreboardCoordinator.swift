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
        
        if let sheet = gameScoreboardViewController.presentationController as? UISheetPresentationController {
            var detents: [UISheetPresentationController.Detent] = []
            if UIDevice.current.userInterfaceIdiom != .pad {
                detents.append(.custom(resolver: { context in 250 }))
            }
            detents.append(contentsOf: [.medium(), .large()])
            sheet.detents = detents
            sheet.prefersGrabberVisible = true
        }

        navigationController.present(gameScoreboardViewController, animated: true)
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true)
    }
}
