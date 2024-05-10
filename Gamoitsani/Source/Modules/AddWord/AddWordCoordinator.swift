//
//  AddWordCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class AddWordCoordinator: BaseCoordinator {
    
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        let addWordViewController = AddWordViewController.loadFromNib()
        addWordViewController.coordinator = self
        navigationController?.pushViewController(addWordViewController, animated: true)
    }
}
