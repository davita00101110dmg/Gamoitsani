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
    
    private lazy var customBackBarButtonItem: UIBarButtonItem = {
        return BackBarButtonItem(title: L10n.back, style: .plain, target: nil, action: nil)
    }()
    
    private lazy var defaultBackBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(title: L10n.back, style: .plain, target: nil, action: nil)
    }()
    
    var subscribers = Set<AnyCancellable>()
    weak var coordinator: T?
    
    var shouldApplyGradientBackground: Bool = true
    var shouldUseCustomBackBarButtonItem: Bool = false

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
        if shouldUseCustomBackBarButtonItem {
            navigationItem.backBarButtonItem = customBackBarButtonItem
        } else {
            navigationItem.backBarButtonItem = defaultBackBarButtonItem
        }
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
