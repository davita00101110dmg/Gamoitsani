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
    
    func start()
}

extension Coordinator {
    func coordinate<T: Coordinator>(to coordinator: T) {
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
    
    deinit {
        dump("Deinited \(self)")
    }
    
    func start() {
        fatalError("Start method should be implemented.")
    }
    
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
}
