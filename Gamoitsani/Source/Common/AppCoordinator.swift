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
            .font: F.Mersad.semiBold.font(size: 18)]
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor : UIColor.white,
            .font: F.Mersad.semiBold.font(size: 48)]

        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = Asset.tintColor.color
        
        UIStepper.appearance().setDecrementImage(UIStepper().decrementImage(for: .normal), for: .normal)
        UIStepper.appearance().setIncrementImage(UIStepper().incrementImage(for: .normal), for: .normal)
        UIStepper.appearance().tintColor = .white
        
        navigationController.navigationBar.barStyle = .black
        navigationController.navigationBar.prefersLargeTitles = UIDevice.current.userInterfaceIdiom == .pad
    }
    
    override func start() {
        navigationController.viewControllers.removeAll()
        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        coordinate(to: homeCoordinator)
    }
}
