//
//  BannerAd.swift
//  Gamoitsani2
//
import GoogleMobileAds
import SwiftUI
import GamoitsaniAds
import GamoitsaniDesign

/// The banner, as an inset panel.
///
/// On the setup screen and between turns. Never on the play screen: five arcade rows and
/// two classic buttons get tapped fast under a running clock, and a banner in that thumb
/// zone means accidental clicks — invalid traffic, which is what gets AdMob accounts
/// warned, quite apart from costing someone the round.
struct BannerAd: View {
    @Environment(\.adService) private var ads
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether an ad actually loaded.
    ///
    /// Nothing is drawn until one arrives. Reserving the space up front left an empty
    /// bordered card whenever the request did not fill — and it usually does not: the
    /// observed match rate is around 9%, so no-fill is the common case, not the edge one.
    @State private var hasAd = false

    /// The card's real width, measured. This sits inside a safe-area inset, so it is not
    /// the screen's width.
    @State private var width: CGFloat = 0

    /// Anchored adaptive, which is what Google recommends for a banner pinned to the top
    /// or bottom of the screen. The inline form is documented as being for banners inside
    /// scrollable content and is explicitly the taller of the two — this one is pinned.
    ///
    /// 58pt at this device's width, against 50pt for the fixed `AdSizeBanner` and its
    /// gap either side of a 320pt creative. Anchored fills the card and stays short.
    private var adSize: AdSize {
        width > 0 ? currentOrientationAnchoredAdaptiveBanner(width: width) : AdSizeBanner
    }

    /// The width has been measured, so a request would be for the size actually shown.
    private var isMeasured: Bool { width > 0 }

    var body: some View {
        if ads.isBannerAllowed, !AdUnits.banner.isEmpty {
            VStack(spacing: 0) {
                if hasAd {
                    // Full width, unlike the card below it. This is the line between what
                    // scrolls and what does not — content passing under the footer is cut
                    // by it instead of just disappearing.
                    Divider().overlay(Tokens.cardEdge.color)
                }

                // The same radius, border and margins as Round, Mode and Extras. Edge to
                // edge it read as something bolted to the app; inset it reads as part of
                // the screen.
                BannerRepresentable(adSize: adSize, isMeasured: isMeasured, hasAd: $hasAd)
                    // The size asked for, not the size that came back. Anchored adaptive
                    // is a fixed aspect ratio, so a well-behaved creative matches it —
                    // and framing by the creative instead let a short one shrink the bar.
                    .frame(
                        width: adSize.size.width,
                        height: hasAd ? adSize.size.height : 0
                    )
                    // A creative larger than the slot is not hypothetical: Google's own
                    // test unit answers a 320x50 request with 468x60, 320x100 and 728x90
                    // at random, and mediation partners are no more disciplined.
                    .clipped()
                    .frame(maxWidth: .infinity)
                    .background(hasAd ? Tokens.surfaceRaised.color : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
                    .overlay {
                        if hasAd {
                            RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                                .strokeBorder(Tokens.cardEdge.color.opacity(0.6), lineWidth: 1)
                        }
                    }
                    .padding(.horizontal, hasAd ? Spacing.md : 0)
                    .padding(.top, hasAd ? Spacing.sm : 0)
                    .padding(.bottom, hasAd ? Spacing.xs : 0)
            }
            .background(Tokens.surface.color)
            .animation(Motion.card(reduceMotion: reduceMotion), value: hasAd)
            .onGeometryChange(for: CGFloat.self) { $0.size.width - Spacing.md * 2 } action: {
                width = max(0, $0)
            }
            .accessibilityHidden(true)
        }
    }
}

private struct BannerRepresentable: UIViewRepresentable {
    let adSize: AdSize
    /// Nothing is requested until the real width is known. Requesting at the placeholder
    /// size first meant every appearance sent two requests and threw the first away.
    let isMeasured: Bool
    @Binding var hasAd: Bool

    func makeCoordinator() -> Coordinator { Coordinator(hasAd: $hasAd) }

    final class Coordinator: NSObject, BannerViewDelegate {
        private let hasAd: Binding<Bool>

        /// The width last *asked* for.
        ///
        /// Reloading is decided against this, never against `BannerView.adSize`. An inline
        /// adaptive banner rewrites its own `adSize` to the creative it received, so
        /// comparing the view against the request is true forever — which turned every
        /// state change into another `load()`, and the app into an infinite ad request
        /// loop that hung the main thread and crashed.
        var requestedWidth: CGFloat = 0

        init(hasAd: Binding<Bool>) { self.hasAd = hasAd }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            hasAd.wrappedValue = true
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            // Collapses the space again rather than leaving an empty frame behind.
            hasAd.wrappedValue = false
        }
    }

    func makeUIView(context: Context) -> BannerView {
        let view = BannerView(adSize: adSize)
        view.adUnitID = AdUnits.banner
        view.rootViewController = AdMobAds.rootViewController
        view.delegate = context.coordinator
        guard isMeasured else { return view }
        context.coordinator.requestedWidth = adSize.size.width
        view.load(Request())
        return view
    }

    func updateUIView(_ view: BannerView, context: Context) {
        // Only when the width we want actually changed — the first real measurement, or
        // a rotation.
        guard isMeasured, context.coordinator.requestedWidth != adSize.size.width else { return }
        context.coordinator.requestedWidth = adSize.size.width
        view.adSize = adSize
        view.load(Request())
    }

    /// Lets SwiftUI lay the banner out at the requested size rather than proposing one.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BannerView, context: Context) -> CGSize? {
        hasAd ? adSize.size : .zero
    }
}
