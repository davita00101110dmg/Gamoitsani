//
//  AdManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

protocol AdManager {
    var isLoadingAd: Bool { get set }
    var isShowingAd: Bool { get set }
    
    func loadAd() async
    func showAdIfAvailable()
}
