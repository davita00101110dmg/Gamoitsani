//
//  BaseViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import Combine

class BaseViewController<T: Coordinator>: UIViewController {
    
    var subscribers = Set<AnyCancellable>()
    weak var coordinator: T?
    
    var shouldApplyGradientBackground: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        subscribeToPublishers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            guard let coordinator else { return }
            coordinator.childDidFinish(coordinator)
        }
    }
    
    @objc private func languageDidChange() {
        setupLocalizedTexts()
    }
    
    private func subscribeToPublishers() {
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
    }
    
    private func setupGradientBackground() {
        guard shouldApplyGradientBackground else {
            view.backgroundColor = Asset.primary.color
            return
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [Asset.gradientColor1.color.cgColor,
                                Asset.gradientColor2.color.cgColor,
                                Asset.gradientColor3.color.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: -0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.locations = [0, 0.47, 1]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    deinit {
        dump("deinited \(self)")
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupUI() { 
        setupGradientBackground()
        navigationItem.enableMultilineTitle()
        setupLocalizedTexts()
    }
    
    func setupLocalizedTexts() { }
}
