//
//  SceneDelegate.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 22/04/2024.
//

import UIKit
import FacebookCore
import UserMessagingPlatform
import GoogleMobileAds

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: AppCoordinator?
    
    private var didEnterBackground = false
    private var sceneActivationTime: Date?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let storyboard = UIStoryboard(name: AppConstants.launchScreen, bundle: nil)
        guard let initialViewController = storyboard.instantiateInitialViewController() else { return }
        
        let navigationController = UINavigationController(rootViewController: initialViewController)
        
        coordinator = AppCoordinator(navigationController: navigationController)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.windowScene = windowScene
        window?.rootViewController = coordinator?.navigationController
        window?.makeKeyAndVisible()
        
        coordinator?.start()
        
        AppConsentAdManager.shared.requestAdConsent(from: window?.rootViewController)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        didEnterBackground = true
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        let currentTime = Date()
        let shouldShowAd = didEnterBackground &&
                          !GameRecordingManager.shared.isRecording &&
                          (sceneActivationTime == nil || currentTime.timeIntervalSince(sceneActivationTime!) > 2.0)

        if shouldShowAd {
            AppOpenAdManager.shared.showAdIfAvailable()
        }
        
        AppSettings.isFirstLaunch = false
        sceneActivationTime = currentTime
        didEnterBackground = false
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }
}
