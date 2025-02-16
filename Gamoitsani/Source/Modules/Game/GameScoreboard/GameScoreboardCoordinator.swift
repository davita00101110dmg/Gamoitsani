//
//  GameScoreboardCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

final class GameScoreboardCoordinator: BaseCoordinator, ObservableObject {
    private var detents: [UISheetPresentationController.Detent]
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController, detents: [UISheetPresentationController.Detent]) {
        self.navigationController = navigationController
        self.detents = detents
        super.init()
    }
    
    override func start() {
        guard let navigationController else { return }
        
        let gameScoreboardView = GameScoreboardView()
            .environmentObject(self)
        
        let hostingController = UIHostingController(rootView: gameScoreboardView)
        
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = detents
            sheet.prefersGrabberVisible = true
            
            if !GameStory.shared.isGameInProgress {
                sheet.preferredCornerRadius = 12
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            }
        }
        
        navigationController.present(hostingController, animated: true)
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true)
    }
}
