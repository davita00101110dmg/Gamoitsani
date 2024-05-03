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
        let initialViewController = GameSettingsViewController.loadFromNib()
        initialViewController.coordinator = self
        navigationController.delegate = self
        navigationController.pushViewController(initialViewController, animated: true)
    }
    
    func goToHome() {
        navigationController.popToRootViewController(animated: true)
        parentCoordinator?.childDidFinish(self)
    }
}
