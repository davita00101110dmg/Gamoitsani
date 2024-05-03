//
//  BaseCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 03/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

protocol Coordinator: AnyObject {
    var parentCoordinator: Coordinator? { get set }
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}

extension Coordinator {
    func coordinate(to coordinator: Coordinator) {
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func childDidFinish(_ coordinator: Coordinator) {
        guard let parentCoordinator = coordinator.parentCoordinator,
              let index = parentCoordinator.childCoordinators.firstIndex(where: { $0 === coordinator }) else { return }
        parentCoordinator.childCoordinators.remove(at: index)
    }
}


class BaseCoordinator: NSObject, Coordinator {
    var parentCoordinator: Coordinator?
    
    var childCoordinators: [Coordinator] = []
    var navigationController = UINavigationController()
    
    func start() {
        fatalError("Start method should be implemented.")
    }
    
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
}

extension BaseCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard let sourceViewController = navigationController.transitionCoordinator?.viewController(forKey: .from) else { return }
        
        if navigationController.viewControllers.contains(sourceViewController) { return }
        
        childDidFinish(self)
    }
}