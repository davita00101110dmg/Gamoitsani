//
//  UIViewControllerExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 23/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

extension UIViewController {

    static func loadFromNib(_ name: String? = nil) -> Self {
        let bundles = [{ Bundle.main }, { Bundle.forClass(Self.self) }]
        return with(name: name, bundleCandidates: bundles)
    }

    static func with<T: Sequence>(name: String?, bundleCandidates: T) -> Self where T.Element == () -> Bundle? {
        for bundle in bundleCandidates {
            if let bundle = bundle(), let nib = with(name: name, in: bundle) { return nib }
        }
        return self.init(nibName: name, bundle: nil)
    }

    static func with(name: String?, in bundle: Bundle) -> Self? {
        if bundle.path(forResource: name ?? String(describing: Self.self), ofType: "nib") == nil {
            return nil
        }
        return self.init(nibName: name, bundle: bundle)
    }
    
    enum AlertType {
        case team(title: String, message: String?, initialText: String?, addActionTitle: String, addActionHandler: (String) -> Void)
        case info(title: String, message: String)
    }

    func presentAlert(of type: AlertType) {
        let alertController: UIAlertController
        
        switch type {
        case let .team(title, message, initialText, addActionTitle, addActionHandler):
            alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addTextField { $0.text = initialText }
            
            alertController.addAction(UIAlertAction(title: L10n.cancel, style: .default))
            alertController.addAction(UIAlertAction(title: addActionTitle, style: .default) { _ in
                guard let teamName = alertController.textFields?.first?.text else { return }
                addActionHandler(teamName)
            })
        case let .info(title, message):
            alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: L10n.ok, style: .default))
        }
        
        present(alertController, animated: true)
    }
}
