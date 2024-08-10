//
//  SettingsViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import SwiftUI

final class SettingsViewController: BaseViewController<SettingsCoordinator> {
    
    var viewModel: SettingsViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSwipeGestureRecogniser()
        setupHostingVC()
    }
    
    private func setupHostingVC() {
        let hostingController = UIHostingController(rootView: SettingsView())
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo:
 view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            hostingController.view.bottomAnchor.constraint(equalTo:
 view.safeAreaLayoutGuide.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    private func addSwipeGestureRecogniser() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func swipeAction() {
        coordinator?.dismiss()
    }
}
