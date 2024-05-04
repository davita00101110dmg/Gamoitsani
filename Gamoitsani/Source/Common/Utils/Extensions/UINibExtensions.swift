//
//  UINibExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 04/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

extension UINib {

    static func with<T: Sequence>(name: String, bundleCandidates: T) -> UINib? where T.Element == () -> Bundle? {
        for bundle in bundleCandidates {
            if let bundle = bundle(), let nib = with(name: name, in: bundle) { return nib }
        }
        return nil
    }

    static func with(name: String, in bundle: Bundle) -> UINib? {
        if bundle.path(forResource: name, ofType: "nib") == nil {
            return nil
        }
        return UINib(nibName: name, bundle: bundle)
    }
}
