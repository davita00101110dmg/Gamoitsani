//
//  AppCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 23/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class AppCoordinator: BaseCoordinator {
    
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
        applyTheme()
    }
    
    private func applyTheme() {
        UINavigationBar.appearance().tintColor = Asset.tintColor.color
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor : Asset.tintColor.color]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor : Asset.tintColor.color,
            .font: F.BPGNinoMtavruli.bold.font(size: 18)]
        UINavigationBar.appearance().prefersLargeTitles = false

        UIView.appearance().tintColor = Asset.tintColor.color
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .black
        
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
    }
    
    override func start() {
        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        coordinate(to: homeCoordinator)
    }
}
