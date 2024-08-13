//
//  UIViewExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

extension UIView {
    static func loadFromNib(_ name: String? = nil) -> Self? {
        return Bundle.main.loadNibNamed(String(describing: Self.self), owner: nil, options: nil)?.first as? Self
    }
    
    @discardableResult func removeAllSubviews() -> [UIView] {
        let subviews = subviews
        for subview in subviews {
            subview.removeFromSuperview()
        }
        return subviews
    }
    
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
     }
}
