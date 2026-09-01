//
//  PurchaseManager.swift
//  Gamoitsani
//
//  Copyright © 2026 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import StoreKit

/// Owns the StoreKit payment queue observer for the lifetime of the process.
///
/// This exists because `SettingsViewModel` used to register *itself* as the
/// `SKPaymentTransactionObserver` in `init` and remove itself in `deinit`. The app
/// therefore only listened for transactions while the Settings screen was on screen. A
/// purchase that completed after the user navigated away — Ask-to-Buy approval, a deferred
/// payment, a network drop that resolves later — arrived with nobody listening, so
/// `hasRemovedAds` was never set and the transaction was never finished. The user paid and
/// kept seeing ads.
///
/// StoreKit 1 replays unfinished transactions to a newly added observer, so the old code
/// would eventually catch up *if* the user happened to reopen Settings. Anyone who did not
/// go back never got what they paid for.
///
/// Phase 8 of docs/2.0/PLAN.md replaces this with StoreKit 2 behind a protocol. This is the
/// minimal v1 fix: one observer, added once at launch, never removed.
final class PurchaseManager: NSObject {

    static let shared = PurchaseManager()

    private var products: [SKProduct] = []
    private var productsRequest: SKProductsRequest?

    /// Set while a restore is in flight so the UI can tell "restored nothing" from
    /// "restore never ran".
    private(set) var isRestoring = false

    private override init() {
        super.init()
    }

    /// Registers the transaction observer. Call once, from `didFinishLaunchingWithOptions`.
    ///
    /// Registering at launch is also what lets StoreKit deliver transactions that
    /// completed while the app was not running.
    func start() {
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }

    func fetchProducts() {
        let identifiers: Set<String> = [AppConstants.removeAdsInAppPurchaseProductID]
        let request = SKProductsRequest(productIdentifiers: identifiers)
        request.delegate = self
        productsRequest = request
        request.start()
    }

    var canMakePurchase: Bool {
        !products.isEmpty && SKPaymentQueue.canMakePayments()
    }

    func purchaseRemoveAds() {
        guard let product = products.first else {
            log(.error, "Remove-ads product unavailable; refetching")
            fetchProducts()
            return
        }
        SKPaymentQueue.default().add(SKPayment(product: product))
    }

    func restorePurchases() {
        isRestoring = true
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate

extension PurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        if !response.invalidProductIdentifiers.isEmpty {
            log(.error, "Invalid product identifiers: \(response.invalidProductIdentifiers)")
        }
        productsRequest = nil
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        log(.error, "Products request failed: \(error.localizedDescription)")
        productsRequest = nil
    }
}

// MARK: - SKPaymentTransactionObserver

extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                AppSettings.hasRemovedAds = true
                queue.finishTransaction(transaction)
                log(.info, "Remove-ads entitlement granted (\(transaction.transactionState == .restored ? "restored" : "purchased"))")

            case .failed:
                // Must still be finished. The previous implementation fell into
                // `default: break` here, leaving failed transactions in the queue for
                // StoreKit to redeliver on every launch, forever.
                if let error = transaction.error as? SKError, error.code != .paymentCancelled {
                    log(.error, "Purchase failed: \(error.localizedDescription)")
                }
                queue.finishTransaction(transaction)

            case .deferred, .purchasing:
                // Not terminal — do not finish. `.deferred` is Ask-to-Buy awaiting a
                // parent's approval, which is precisely the case the old screen-scoped
                // observer used to miss.
                break

            @unknown default:
                break
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        isRestoring = false
        log(.info, "Restore completed")
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        isRestoring = false
        log(.error, "Restore failed: \(error.localizedDescription)")
    }
}
