//
//  GamoitsaniApp.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/11/2025.
//

import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform

@main
struct GamoitsaniApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    @State private var didEnterBackground = false
    @State private var sceneActivationTime: Date?

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(coordinator)
                .onAppear {
                    // Request ad consent when app appears
                    requestAdConsent()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
        }
    }

    // MARK: - Ad Consent

    private func requestAdConsent() {
        // Get the root window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        AppConsentAdManager.shared.requestAdConsent(from: rootViewController)
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            didEnterBackground = true

        case .active:
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

        case .inactive:
            break

        @unknown default:
            break
        }
    }
}
