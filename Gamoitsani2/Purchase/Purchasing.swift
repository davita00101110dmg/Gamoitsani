//
//  Purchasing.swift
//  Gamoitsani2
//
import Foundation
import SwiftUI

/// What happened when someone tried to buy.
enum PurchaseOutcome: Sendable, Equatable {
    case bought
    /// Cancelled the sheet. Not an error, and must not be reported as one.
    case cancelled
    /// Ask to Buy, or a payment awaiting approval. The entitlement arrives later, through
    /// the transaction listener, possibly on a future launch.
    case pending
    case failed(String)
}

/// The app's whole view of buying things.
///
/// Screens talk to this and never import StoreKit, so they stay previewable and the
/// implementation can be swapped for a stub.
@MainActor
protocol Purchasing: AnyObject {
    /// Whether the ad-free upgrade is owned. The single source of truth for it.
    var hasRemovedAds: Bool { get }

    /// Localised price for the storefront, once the product has loaded. `nil` while
    /// loading or if the product could not be fetched.
    var displayPrice: String? { get }

    /// Whether a purchase or restore is currently in flight.
    var isBusy: Bool { get }

    /// Loads products and starts listening for transactions. Safe to call twice.
    func start() async

    func buyRemoveAds() async -> PurchaseOutcome

    /// Re-syncs with the App Store. Returns whether anything was owned afterwards.
    @discardableResult
    func restore() async -> Bool
}

/// A store that sells nothing.
///
/// For previews and for any build that should not reach StoreKit. Having a real
/// implementation of "no purchases" means call sites never branch on whether a store
/// exists.
@MainActor
final class NoPurchases: Purchasing {
    nonisolated init() {}

    var hasRemovedAds: Bool { false }
    var displayPrice: String? { nil }
    var isBusy: Bool { false }

    func start() async {}
    func buyRemoveAds() async -> PurchaseOutcome { .cancelled }
    func restore() async -> Bool { false }
}

extension EnvironmentValues {
    /// Purchases, as the app sees them. Defaults to a store that sells nothing so previews
    /// never reach StoreKit.
    @Entry var purchases: any Purchasing = NoPurchases()
}
