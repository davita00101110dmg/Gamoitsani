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

    override init() {
        super.init()
        applyTheme()
    }
    
    private func applyTheme() {
        UINavigationBar.appearance().tintColor = UIColor.gmTint
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor : UIColor.gmTint]
        UIView.appearance().tintColor = UIColor.gmTint
    }
    
    func start() {
        let initialViewController = HomeViewController.loadFromNib()
        initialViewController.coordinator = self
        navigationController.delegate = self
        navigationController.pushViewController(initialViewController, animated: true)
    }
    
    func navigateToRules() {
        let rulesVC = RulesViewController.loadFromNib()
        rulesVC.coordinator = self
        navigationController.delegate = self
        navigationController.pushViewController(rulesVC, animated: true)
    }
}
