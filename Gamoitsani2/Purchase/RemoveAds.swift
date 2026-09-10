//
//  RemoveAds.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniDesign
import GamoitsaniL10n

/// The offer, as a card in the setup form.
///
/// Whether it appears at all is `RemoveAdsOfferPolicy`'s decision, not this view's: it is
/// earned by ads actually seen, silenced for a week by a dismissal, and dropped for good
/// after the third refusal.
struct RemoveAdsCard: View {
    let dismiss: () -> Void

    @Environment(Localization.self) private var l10n
    @Environment(\.purchases) private var purchases
    @State private var failure: String?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: buy) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(Tokens.accent.color)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(l10n("iap.removeAds"))
                            .font(Typography.rowTitle)
                            .foregroundStyle(Tokens.onSurface.color)
                        Text(l10n("iap.removeAds.detail"))
                            .font(Typography.caption)
                            .foregroundStyle(Tokens.onSurfaceMuted.color)
                    }

                    Spacer(minLength: Spacing.xs)

                    if purchases.activity == .purchasing {
                        ProgressView().tint(Tokens.accent.color)
                    } else if let price = purchases.displayPrice {
                        Text(price)
                            .font(Typography.rowTitle)
                            .foregroundStyle(Tokens.accent.color)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(purchases.activity.isBusy)

            // Its own button, outside the buy target. A dismiss nested inside a tappable
            // card is a purchase one mis-tap away.
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Tokens.onSurfaceMuted.color)
                    .frame(width: 34, height: 34)
                    .background(Tokens.surface.color)
                    .clipShape(Circle())
                    .frame(width: Sizing.minimumTarget, height: Sizing.minimumTarget)
                    .contentShape(Circle())
            }
            .accessibilityLabel(l10n("iap.dismiss"))
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Tokens.surfaceRaised.color)
        .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                .strokeBorder(Tokens.cardEdge.color.opacity(0.6), lineWidth: 1)
        }
        .purchaseFailureAlert($failure, l10n: l10n)
    }

    private func buy() {
        Task {
            if case .failed(let message) = await purchases.buyRemoveAds() {
                failure = message
            }
        }
    }
}

/// The Settings rows, which are there whatever the card is doing.
///
/// Nothing gates these. Restore Purchases has to be findable, and somebody who goes
/// looking for the offer after dismissing it three times should still find it.
struct RemoveAdsSettingsRows: View {
    @Environment(Localization.self) private var l10n
    @Environment(\.purchases) private var purchases
    @State private var failure: String?
    @State private var restoredNothing = false

    var body: some View {
        // One Group so the alerts below are attached once. Putting them on the rows meant
        // two alerts bound to the same state, and only one of them ever presented.
        Group {
            if purchases.hasRemovedAds {
                // Nothing left to sell. Saying so is better than an inert row or a gap.
                HStack {
                    Text(l10n("iap.owned"))
                        .font(Typography.rowTitle)
                        .foregroundStyle(Tokens.onSurface.color)
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Tokens.success.color)
                }
                .padding(.vertical, Spacing.sm)
            } else {
                row(
                    l10n("iap.removeAds"),
                    trailing: purchases.displayPrice,
                    spinsFor: .purchasing,
                    action: buy
                )
                Divider().overlay(Tokens.cardEdge.color)
                row(
                    l10n("iap.restore"),
                    trailing: nil,
                    spinsFor: .restoring,
                    action: restore
                )
            }
        }
        .purchaseFailureAlert($failure, l10n: l10n)
        .alert(l10n("iap.restore"), isPresented: $restoredNothing) {
            Button(l10n("common.ok"), role: .cancel) {}
        } message: {
            Text(l10n("iap.restore.nothing"))
        }
    }

    /// `spinsFor` is the activity this row owns. Buying must not spin the Restore row —
    /// that read as the app restoring and purchasing at the same time.
    private func row(
        _ title: String,
        trailing: String?,
        spinsFor activity: PurchaseActivity,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Tokens.onSurface.color)
                Spacer()
                if purchases.activity == activity {
                    ProgressView().tint(Tokens.accent.color)
                } else if let trailing {
                    Text(trailing)
                        .font(Typography.body)
                        .foregroundStyle(Tokens.accent.color)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Tokens.onSurfaceMuted.color)
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Both rows still go inert while either is running — starting a restore in the
        // middle of a purchase is not something to allow, only something not to advertise.
        .disabled(purchases.activity.isBusy)
    }

    private func buy() {
        Task {
            if case .failed(let message) = await purchases.buyRemoveAds() {
                failure = message
            }
        }
    }

    private func restore() {
        Task {
            // "Restored nothing" is a real outcome and silence reads as a broken button.
            restoredNothing = await purchases.restore() == false
        }
    }
}

private extension View {
    /// A failure worth interrupting for. Cancelling is not one, and never reaches here.
    func purchaseFailureAlert(_ message: Binding<String?>, l10n: Localization) -> some View {
        alert(
            l10n("iap.failed"),
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button(l10n("common.ok"), role: .cancel) {}
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}
