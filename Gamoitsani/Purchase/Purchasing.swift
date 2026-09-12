//
//  Purchasing.swift
//  Gamoitsani
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

/// What the store is doing, if anything.
///
/// Not a single `isBusy` flag: the buy row and the Restore row read the same state, so one
/// flag put a spinner on both and buying looked like it was also restoring.
enum PurchaseActivity: Sendable, Equatable {
    case idle
    case purchasing
    case restoring

    var isBusy: Bool { self != .idle }
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

    /// What is in flight, so each row can show a spinner only for its own action.
    var activity: PurchaseActivity { get }

    /// Loads products and starts listening for transactions. Safe to call twice.
    func start() async

    func buyRemoveAds() async -> PurchaseOutcome

    /// Re-syncs with the App Store. Returns whether anything was owned afterwards.
    @discardableResult
    func restore() async -> Bool

    #if DEBUG
    /// Why the store is in the state it is. "Not available" looks identical whether the
    /// identifier is wrong, the product did not load, or StoreKit had no configuration to
    /// answer from — and the first time it happened, telling them apart took a rebuild.
    var debugSummary: [(String, String)] { get }
    #endif
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
    var activity: PurchaseActivity { .idle }

    func start() async {}
    func buyRemoveAds() async -> PurchaseOutcome { .cancelled }
    func restore() async -> Bool { false }

    #if DEBUG
    var debugSummary: [(String, String)] { [("store", "off")] }
    #endif
}

extension EnvironmentValues {
    /// Purchases, as the app sees them. Defaults to a store that sells nothing so previews
    /// never reach StoreKit.
    @Entry var purchases: any Purchasing = NoPurchases()
}
