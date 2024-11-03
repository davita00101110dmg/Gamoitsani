//
//  GameDetailsCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

final class GameDetailsCoordinator: BaseCoordinator, ObservableObject {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let gameDetailsView = GameDetailsView()
            .environmentObject(self)
        
        let hostingController = UIHostingController(rootView: gameDetailsView)
        hostingController.title = L10n.Screen.GameDetails.title
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    func navigateToGame() {
        guard let navigationController else { return }
        let gameCoordinator = GameCoordinator(navigationController: navigationController)
        coordinate(to: gameCoordinator)
    }
}
