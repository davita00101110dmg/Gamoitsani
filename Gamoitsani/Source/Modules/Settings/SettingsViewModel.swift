//
//  SettingsViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import StoreKit

final class SettingsViewModel: NSObject, ObservableObject {
    @AppStorage(UserDefaults.Keys.APP_LANGUAGE) var appLanguage: String = AppConstants.Language.georgian.identifier
    @AppStorage(UserDefaults.Keys.HAS_REMOVED_ADS) var isRemoveAdsPurchased: Bool = false
    @Published var selectedSegment: Int = 0
    @Published var showingAlert: Bool = false
    @Published var languageChanged: Bool = false
    @Published var isShareSheetPresented: Bool = false
        
    private var products: [SKProduct] = []
    
    override init() {
        super.init()
        selectedSegment = appLanguage == AppConstants.Language.georgian.identifier ? 0 : 1
        fetchProducts()
        SKPaymentQueue.default().add(self)
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
    
    func updateLanguage(_ segment: Int) {
        appLanguage = segment == 0 ? AppConstants.Language.georgian.identifier : AppConstants.Language.english.identifier
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
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
