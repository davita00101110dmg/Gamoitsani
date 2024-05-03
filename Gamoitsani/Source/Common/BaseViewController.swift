//
//  BaseViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

class BaseViewController<T: Coordinator>: UIViewController {
    
    weak var coordinator: T?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        subscribeToPublishers()
    }
    
    @objc private func languageDidChange() {
        setupLocalizedTexts()
    }
    
    private func subscribeToPublishers() {
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupUI() { 
        view.backgroundColor = UIColor.primary
        navigationController?.navigationBar.prefersLargeTitles = true
        setupLocalizedTexts()
    }
    
    func setupLocalizedTexts() { }
}
