//
//  SettingsCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

final class SettingsCoordinator: BaseCoordinator, ObservableObject {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let settingsView = SettingsView()
            .environmentObject(self)
        
        let hostingController = UIHostingController(rootView: settingsView)
        navigationController.present(hostingController, animated: true)
    }
    
    func presentPrivacySettings() {
        AdManager.shared.presentPrivacySettings(from: navigationController?.presentedViewController)
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true)
    }
}
