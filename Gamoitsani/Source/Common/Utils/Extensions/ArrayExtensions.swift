//
//  ArrayExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 11/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

extension Array {
    mutating func removeFirstNItems(_ n: Int) -> [Element] {
        guard n <= count else {
            return []
        }
        
        let removedItems = Array(self[0..<n])
        removeFirst(n)
        
        return removedItems
    }
}
