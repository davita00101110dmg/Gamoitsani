//
//  UIApplicationExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

extension UIApplication {
    var currentScene: UIWindowScene? {
        connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
}
