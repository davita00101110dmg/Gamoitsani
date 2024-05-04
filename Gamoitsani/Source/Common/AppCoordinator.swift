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
        UINavigationBar.appearance().tintColor = Asset.tintColor.color
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor : Asset.tintColor.color ?? .tintColor]
        UIView.appearance().tintColor = Asset.tintColor.color
    }
    
    override func start() {
        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        coordinate(to: homeCoordinator)
    }
}
