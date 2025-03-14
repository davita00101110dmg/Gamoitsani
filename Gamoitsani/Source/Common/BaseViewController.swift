//
//  BaseViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import Combine
import GoogleMobileAds

class BaseViewController<T: Coordinator>: UIViewController {
    
    private lazy var customBackBarButtonItem: UIBarButtonItem = {
        let button = BackBarButtonItem(title: L10n.back, style: .plain, target: nil, action: nil)
        button.setTitleTextAttributes([.font: UIFont.appFont(type: .semiBold, size: 16)], for: .normal)
        button.setTitleTextAttributes([.font: UIFont.appFont(type: .semiBold, size: 16)], for: .selected)
        return button
    }()
    
    private lazy var defaultBackBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(title: L10n.back, style: .plain, target: nil, action: nil)
        button.setTitleTextAttributes([.font: UIFont.appFont(type: .semiBold, size: 16)], for: .normal)
        button.setTitleTextAttributes([.font: UIFont.appFont(type: .semiBold, size: 16)], for: .selected)
        return button
    }()
    
    var subscribers = Set<AnyCancellable>()
    weak var coordinator: T?
    
    var shouldApplyGradientBackground: Bool = true
    var shouldUseCustomBackBarButtonItem: Bool = false
    
    private var bannerView: BannerView?

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
        updateBackBarButtonItemTitles()
    }
    
    private func subscribeToPublishers() {
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
    }
    
    private func setupCustomBackBarButtonItem() {
        navigationItem.backBarButtonItem = shouldUseCustomBackBarButtonItem ? customBackBarButtonItem : defaultBackBarButtonItem
    }
    
    private func updateBackBarButtonItemTitles() {
        customBackBarButtonItem.title = L10n.back
        defaultBackBarButtonItem.title = L10n.back
    }

    private func setupGradientBackground() {
        guard shouldApplyGradientBackground else {
            view.backgroundColor = Asset.gmPrimary.color
            return
        }
        
        let gradientView = GradientView(frame: view.bounds)
        view.insertSubview(gradientView, at: 0)
    }
    
    deinit {
        log(.info, "Deinited \(self)")
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupUI() { 
        setupGradientBackground()
        navigationItem.enableMultilineTitle()
        setupLocalizedTexts()
    }
    
    func setupLocalizedTexts() { }
    
    @objc func presentAdInspector() {
        MobileAds.shared.presentAdInspector(from: self) { error in
            log(.error, "Inspector error \(error?.localizedDescription ?? .empty)")
        }
    }
}
