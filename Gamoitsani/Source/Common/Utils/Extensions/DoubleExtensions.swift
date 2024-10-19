//
//  DoubleExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 04/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

extension Double {
    static let week: Double = 7 * 24 * 60 * 60
    static let day: Double = 24 * 60 * 60
    
    var toInt: Int { Int(self) }
    
    func toString(decimalPlaces: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
    }
}
