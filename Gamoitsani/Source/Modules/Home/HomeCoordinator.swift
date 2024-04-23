//
//  HomeCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 22/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

class HomeCoordinator: NSObject, Coordinator, UINavigationControllerDelegate {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        navigationController.delegate = self
        
        let viewController = HomeViewController.loadFromNib()
        
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: false)
    }
}
