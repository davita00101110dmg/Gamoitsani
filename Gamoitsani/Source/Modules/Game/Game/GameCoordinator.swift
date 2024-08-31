//
//  GameCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

final class GameCoordinator: BaseCoordinator, ObservableObject {
    
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let viewModel = GameViewModel()
        let gameView = GameView(viewModel: viewModel)
            .environmentObject(self)
        
        let hostingController = UIHostingController(rootView: gameView)
        hostingController.navigationItem.leftBarButtonItem = BackBarButtonItem(image: UIImage(systemName: AppConstants.SFSymbol.flagCheckeredTwoCrossed)!, style: .plain, target: self, action: #selector(presentGoBackAlert))
        hostingController.modalPresentationStyle = .fullScreen
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    @objc func presentGoBackAlert() {
        let alert = UIAlertController(
            title: L10n.Screen.Game.ConfirmationAlert.title,
            message: L10n.Screen.Game.ConfirmationAlert.message,
            preferredStyle: .alert)
        
        alert.addAction(.init(title: L10n.yesPolite, style: .destructive) { [weak self] _ in
            self?.pop()
        })
        
        alert.addAction(.init(title: L10n.no, style: .cancel))

        navigationController?.present(alert, animated: true)
    }
    
    func pop() {
        guard let navigationController else { return }
        navigationController.popViewController(animated: true)
    }
    
    func presentGameScoreboard(with detents: [UISheetPresentationController.Detent] = UIDevice.current.userInterfaceIdiom != .pad
                               ? [.custom(resolver: { context in 250 }), .medium(), .large()]
                               : [.medium(), .large()]) {
        guard let navigationController else { return }
        
        let gameScoreboardCoordinator = GameScoreboardCoordinator(navigationController: navigationController, detents: detents)
        coordinate(to: gameScoreboardCoordinator)
    }
    
    func presentGameShareView(with image: UIImage) {
        guard let navigationController else { return }
        let coordinator = GameShareCoordinator(navigationController: navigationController, image: image)
        coordinate(to: coordinator)
    }
}
