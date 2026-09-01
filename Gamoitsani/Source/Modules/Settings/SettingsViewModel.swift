//
//  SettingsViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import StoreKit
import Combine

final class SettingsViewModel: NSObject, ObservableObject {
    @Published var selectedLanguage: Language
    @AppStorage(AppSettings.HAS_REMOVED_ADS) var isRemoveAdsPurchased: Bool = false
    @Published var showingAlert: Bool = false
    @Published var languageChanged: Bool = false
    @Published var isShareSheetPresented: Bool = false
    
    private var products: [SKProduct] = []
    private var cancellables = Set<AnyCancellable>()
    
    let languagePickerRowViewModel = LanguagePickerRowViewModel(onLanguageChange: { newLanguage in
        LanguageManager.shared.setLanguage(newLanguage)
    })
    
    var shouldShowPrivacySettingsButton: Bool {
        AppConsentAdManager.shared.shouldShowPrivacySettingsButton
    }
    
    var availableLanguages: [Language] {
        Language.allCases
    }
    
    override init() {
        selectedLanguage = LanguageManager.shared.currentLanguage
        super.init()

        LanguageManager.shared.$currentLanguage
            .sink { [weak self] newLanguage in
                self?.selectedLanguage = newLanguage
                self?.languageChanged = true
            }
            .store(in: &cancellables)
    }


    func updateLanguage(_ language: Language) {
        LanguageManager.shared.setLanguage(language)
    }
    
    func writeReviewAction() {
        guard let appStoreReviewURL = URL(string: AppConstants.reviewUrlLink) else {
            log(.error, "Invalid App Store review URL")
            showingAlert = true
            return
        }

        if UIApplication.shared.canOpenURL(appStoreReviewURL) {
            UIApplication.shared.open(appStoreReviewURL)
        } else {
            showingAlert = true
        }
    }
    
    func feedbackAction() {
        let email = "davitikhvedelidze26@gmail.com"
        let subject = "Gamoitsani Feedback"
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? .empty)") {
            UIApplication.shared.open(url)
        }
    }
    
    // Both delegate to PurchaseManager, which holds the payment queue observer for the
    // whole process. This view model used to be the observer itself, so it stopped
    // listening the moment the Settings screen went away.
    //
    // `isRemoveAdsPurchased` is @AppStorage over the same key PurchaseManager writes, so
    // the entitlement still lands here without this type observing the queue.
    func purchaseProduct() {
        PurchaseManager.shared.purchaseRemoveAds()
    }

    func restoreProduct() {
        PurchaseManager.shared.restorePurchases()
    }
}
