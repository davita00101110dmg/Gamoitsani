//
//  RulesViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//
//

import Foundation

final class RulesViewModel {
    
    private let rules: [String]
    
    init() {
        rules = [
            L10n.Screen.Rules.rule1,
            L10n.Screen.Rules.rule2,
            L10n.Screen.Rules.rule3,
            L10n.Screen.Rules.rule4,
            L10n.Screen.Rules.rule5,
            L10n.Screen.Rules.rule6,
        ]
    }
    
    func numberOfItems() -> Int {
        rules.count
    }
    
    func rule(at index: Int) -> String {
        rules[index]
    }
}
