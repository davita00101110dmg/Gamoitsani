//
//  ShakeEffect.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func modifier(_ x: CGFloat) -> CGFloat {
        10 * sin(x * .pi * 2)
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let transform = CGAffineTransform(translationX: modifier(animatableData), y: 0)
        
        return ProjectionTransform(transform)
    }
}
