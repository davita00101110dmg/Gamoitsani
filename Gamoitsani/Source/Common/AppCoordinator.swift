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
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor : UIColor.white,
            .font: UIFont.appFont(type: .semiBold, size: 18)]
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor : UIColor.white,
            .font: UIFont.appFont(type: .semiBold, size: 48)]

        UIView.appearance().tintColor = .white
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = Asset.tintColor.color
        
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.prefersLargeTitles = UIDevice.current.userInterfaceIdiom == .pad
    }
    
    override func start() {
        guard let window = navigationController.view.window else { return }
        navigationController.viewControllers.removeAll()
        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        coordinate(to: homeCoordinator)
    }
}
