//
//  StoreKitPurchases.swift
//  Gamoitsani2
//
import Foundation
import Observation
import StoreKit

/// The remove-ads upgrade, on StoreKit 2.
///
/// Replaces v1's `PurchaseManager`, which was StoreKit 1 and registered its payment-queue
/// observer from the Settings screen — so a purchase that completed after the player
/// navigated away arrived with nobody listening, and they paid and kept seeing ads. The
/// listener here starts at launch and runs for the life of the process, which is the whole
/// reason that bug cannot come back.
@MainActor
@Observable
final class StoreKitPurchases: Purchasing {

    private(set) var hasRemovedAds = false
    private(set) var displayPrice: String?
    private(set) var isBusy = false

    @ObservationIgnored private var product: Product?
    @ObservationIgnored private var listener: Task<Void, Never>?
    @ObservationIgnored private var didStart = false

    deinit { listener?.cancel() }

    func start() async {
        guard !didStart else { return }
        didStart = true

        // Before anything else. A transaction can arrive while the app is not running —
        // Ask to Buy approved overnight, a deferred payment cleared — and StoreKit
        // replays it to whoever is listening at launch.
        listener = listenForTransactions()

        await refreshEntitlement()
        await loadProduct()
    }

    // MARK: - Buying

    func buyRemoveAds() async -> PurchaseOutcome {
        guard !isBusy else { return .cancelled }

        // Products can fail to load on a cold, offline launch; retry rather than making
        // the button permanently dead.
        if product == nil { await loadProduct() }
        guard let product else { return .failed(ProductID.missingProductMessage) }

        isBusy = true
        defer { isBusy = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard let transaction = verified(verification) else {
                    return .failed("The App Store could not verify that purchase.")
                }
                // Finish only after the entitlement is recorded. An unfinished transaction
                // is replayed on next launch, which is the safety net if this crashes in
                // between.
                hasRemovedAds = true
                await transaction.finish()
                return .bought

            case .userCancelled:
                return .cancelled

            case .pending:
                // Ask to Buy. There is no entitlement yet and there may never be one; the
                // listener delivers it if approval comes.
                return .pending

            @unknown default:
                return .failed("The App Store returned something unexpected.")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    @discardableResult
    func restore() async -> Bool {
        guard !isBusy else { return hasRemovedAds }
        isBusy = true
        defer { isBusy = false }

        // `AppStore.sync()` prompts for a password, so it is only correct behind an
        // explicit Restore button. Ordinary ownership comes from `currentEntitlements`,
        // which needs no prompt and is checked at every launch.
        try? await AppStore.sync()
        await refreshEntitlement()
        return hasRemovedAds
    }

    // MARK: - Entitlement

    /// The source of truth for ownership.
    ///
    /// Deliberately not a stored flag in `UserDefaults`: that is what v1 did, and a flag
    /// written on one device is a purchase the same person does not have on their next
    /// one. `currentEntitlements` is per-Apple-Account and survives reinstalls.
    private func refreshEntitlement() async {
        for await result in Transaction.currentEntitlements
        where verified(result)?.productID == ProductID.removeAds {
            hasRemovedAds = true
            return
        }
        hasRemovedAds = false
    }

    /// The task inherits this class's main-actor isolation, so the entitlement is written
    /// on the actor that publishes it without hopping.
    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, let transaction = self.verified(result) else { continue }

                if transaction.productID == ProductID.removeAds {
                    // A revocation arrives the same way a purchase does — refunds and
                    // family-sharing removals both land here.
                    self.hasRemovedAds = transaction.revocationDate == nil
                }
                await transaction.finish()
            }
        }
    }

    /// Unverified transactions are dropped rather than trusted. A failed signature is the
    /// shape a jailbroken store takes.
    private func verified(_ result: VerificationResult<Transaction>) -> Transaction? {
        switch result {
        case .verified(let transaction): transaction
        case .unverified: nil
        }
    }

    #if DEBUG
    var debugSummary: [(String, String)] {
        [
            ("product id", ProductID.removeAds.isEmpty ? "missing from Info.plist" : ProductID.removeAds),
            ("product", product == nil ? "not loaded" : "loaded"),
            ("price", displayPrice ?? "—"),
            ("owned", hasRemovedAds ? "yes" : "no"),
            ("busy", isBusy ? "yes" : "no"),
        ]
    }
    #endif

    // MARK: - Product

    private func loadProduct() async {
        guard !ProductID.removeAds.isEmpty else { return }
        let products = try? await Product.products(for: [ProductID.removeAds])
        product = products?.first
        // Localised, and follows the storefront. Never a hardcoded price.
        displayPrice = product?.displayPrice
    }
}

/// The product's identifier, substituted from `Config.xcconfig`.
enum ProductID {
    /// Deliberately the same identifier v1 sells.
    ///
    /// Product identifiers belong to the App Store Connect app record, not to a bundle id,
    /// so at cutover the people who already bought this in v1 keep it. A new identifier
    /// would silently take the upgrade away from every existing customer and there would
    /// be no way to give it back.
    static let removeAds = value("REMOVE_ADS_PRODUCT_ID")

    #if DEBUG
    /// Debug builds say why. Release keeps the plain sentence — a player does not need to
    /// hear about StoreKit configurations.
    static let missingProductMessage = """
        No product for "\(removeAds)".

        StoreKit test configurations are injected by Xcode at launch, so this always \
        fails when the app is started any other way. Run from Xcode (⌘R) to test buying.
        """
    #else
    static let missingProductMessage = "That upgrade is not available right now."
    #endif

    private static func value(_ key: String) -> String {
        let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
        return raw.hasPrefix("$(") ? "" : raw
    }
}
