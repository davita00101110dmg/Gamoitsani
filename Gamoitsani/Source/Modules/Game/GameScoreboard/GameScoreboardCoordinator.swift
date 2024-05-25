//
//  GameScoreboardCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameScoreboardCoordinator: BaseCoordinator {
    
    private var detents: [UISheetPresentationController.Detent] = []
    
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController, detents: [UISheetPresentationController.Detent]) {
        super.init()
        self.navigationController = navigationController
        self.detents = detents
    }
    
    override func start() {
        guard let navigationController else { return }
        let gameScoreboardViewController = GameScoreboardViewController.loadFromNib()
        gameScoreboardViewController.viewModel = GameScoreboardViewModel()
        gameScoreboardViewController.coordinator = self
        
        if let sheet = gameScoreboardViewController.presentationController as? UISheetPresentationController {
            sheet.detents = detents
            sheet.prefersGrabberVisible = true
        }

        navigationController.present(gameScoreboardViewController, animated: true)
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true)
    }
}
