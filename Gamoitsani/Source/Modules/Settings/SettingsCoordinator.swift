//
//  SettingsCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class SettingsCoordinator: BaseCoordinator {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let viewController = SettingsViewController.loadFromNib()
        viewController.coordinator = self
        navigationController.present(viewController, animated: true)
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true)
    }
}
