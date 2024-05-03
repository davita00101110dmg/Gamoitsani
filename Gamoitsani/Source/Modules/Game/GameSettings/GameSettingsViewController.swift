//
//  GameSettingsViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

final class GameSettingsViewController: BaseViewController<GameSettingsCoordinator> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func startGame(_ sender: Any) {
        coordinator?.goToHome()
    }
    
    @IBAction func seeScore(_ sender: Any) {
        coordinator?.goToHome()
    }
}
