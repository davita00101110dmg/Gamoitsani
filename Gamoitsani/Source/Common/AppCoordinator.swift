//
//  AppCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 23/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class AppCoordinator: BaseCoordinator {
    
    override init() {
        super.init()
        applyTheme()
    }
    
    private func applyTheme() {
        UINavigationBar.appearance().tintColor = UIColor.gmTint
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor : UIColor.gmTint ?? .tintColor]
        UIView.appearance().tintColor = UIColor.gmTint
    }
    
    override func start() {
        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        coordinate(to: homeCoordinator)
    }
}
