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
    @AppStorage(UserDefaults.Keys.HAS_REMOVED_ADS) var isRemoveAdsPurchased: Bool = false
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
        
        fetchProducts()
        SKPaymentQueue.default().add(self)
        
        LanguageManager.shared.$currentLanguage
            .sink { [weak self] newLanguage in
                self?.selectedLanguage = newLanguage
                self?.languageChanged = true
            }
            .store(in: &cancellables)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    private func fetchProducts() {
        let productIdentifiers: Set<String> = [AppConstants.removeAdsInAppPurchaseProductID]
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    func updateLanguage(_ language: Language) {
        LanguageManager.shared.setLanguage(language)
    }
    
    func writeReviewAction() {
        guard let appStoreReviewURL = URL(string: AppConstants.reviewUrlLink) else {
            dump("Error: Invalid App Store review URL")
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
    
    func purchaseProduct() {
        guard let product = products.first else { return }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restoreProduct() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate
extension SettingsViewModel: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            switch transaction.transactionState {
            case .purchased, .restored:
                isRemoveAdsPurchased = true
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
