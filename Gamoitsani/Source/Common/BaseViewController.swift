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
    var customBackBarButtonItem: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        subscribeToPublishers()
        setupCustomBackBarButtonItem()
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
        setupCustomBackBarButtonItem()
    }
    
    private func subscribeToPublishers() {
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
    }
    
    private func setupCustomBackBarButtonItem() {
        let backButton: UIBarButtonItem
        
        if customBackBarButtonItem {
            backButton = BackBarButtonItem(title: L10n.back, style: .plain, target: nil, action: nil)
        } else {
            backButton = UIBarButtonItem(title: L10n.back, style: .plain, target: nil, action: nil)
        }
        
        navigationItem.backBarButtonItem = backButton
    }

    private func setupGradientBackground() {
        guard shouldApplyGradientBackground else {
            view.backgroundColor = Asset.primary.color
            return
        }
        
        let gradientView = GradientView(frame: view.bounds)
        view.insertSubview(gradientView, at: 0)
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
