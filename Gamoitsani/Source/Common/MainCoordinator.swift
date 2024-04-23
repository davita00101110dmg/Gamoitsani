//
//  MainCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 23/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

protocol ViewControllerContainable {
    var viewController: UIViewController { get }
}

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}

class MainCoordinator: NSObject, Coordinator, UINavigationControllerDelegate {
    var childCoordinators: [Coordinator] = []
    var navigationController = UINavigationController()
    
    func start() {
        let initialViewController = HomeViewController.loadFromNib()
        initialViewController.coordinator = self
        navigationController.delegate = self
        navigationController.pushViewController(initialViewController, animated: true)
    }
}
