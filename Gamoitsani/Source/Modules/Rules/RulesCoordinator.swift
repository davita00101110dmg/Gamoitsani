//
//  RulesCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class RulesCoordinator: BaseCoordinator {

    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        let viewController = RulesViewController.loadFromNib()
        viewController.coordinator = self
        navigationController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}
