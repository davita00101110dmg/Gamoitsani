//
//  RulesCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class RulesCoordinator: BaseCoordinator {

    var navigationController: UINavigationController?
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let rulesViewController = RulesViewController.loadFromNib()
        rulesViewController.viewModel = RulesViewModel()
        rulesViewController.coordinator = self
        
        AnalyticsManager.shared.logRulesViewed()
        
        navigationController.pushViewController(rulesViewController, animated: true)
    }
}
