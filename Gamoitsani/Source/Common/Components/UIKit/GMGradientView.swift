//
//  GMGradientView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 18/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import SwiftUI

final class GradientView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        
        gradientLayer.colors = [Asset.gradientColor1.color.cgColor,
                                Asset.gradientColor2.color.cgColor,
                                Asset.gradientColor3.color.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: -0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.locations = [0, 0.47, 1]
        gradientLayer.frame = bounds
    }
    
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }
}

struct GradientBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> GradientView {
        return GradientView() 
    }

    func updateUIView(_ uiView: GradientView, context: Context) {
        // No updates needed in this case
    }
}
