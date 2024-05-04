//
//  UITableViewExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 04/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

extension UITableView {
    
    func register<T: UITableViewCell>(_ cellClass: T.Type,
                                      reuseIdentifier: String = T.className) {
        let nibName = String(describing: cellClass)
        let bundles = [
            { Bundle.main },
            { Bundle.forClass(cellClass) }
        ]

        guard let nib = UINib.with(name: nibName, bundleCandidates: bundles) else {
            assertionFailure("No Nib candidate to register in \(bundles.compactMap { $0() }) bundles with \(nibName) name")
            return
        }

        register(nib, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func dequeueReusableCell<T: UITableViewCell>(by reuseIdentifier: String = T.className,
                                                 for indexPath: IndexPath) -> T {
        let dequeuedCell = dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        guard let cell = dequeuedCell as? T else {
            fatalError("Could not dequeue cell with identifier: \(reuseIdentifier)")
        }

        return cell
    }
}
