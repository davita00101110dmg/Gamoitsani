//
//  GamoitsaniApp.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniDesign
import GamoitsaniL10n

/// The 2.0 entry point and composition root.
@main
struct GamoitsaniApp: App {
    @State private var router = Router()
    @State private var localization: Localization
    @State private var session = GameSession()
    @State private var sound = SoundPlayer()
    @State private var haptics = Haptics()
    @State private var ads = AdMobAds()
    @State private var store = StoreKitPurchases()
    @State private var recorder = CameraTurnRecorder()
    @State private var reviewPrompter = ReviewPrompter()
    @State private var reminders = Reminders()
    @State private var players = PlayerBook()
    #if DEBUG
    @State private var debugSettings = DebugSettings()
    #endif

    /// Cold start only — `@State` here is created once per process, so resuming never
    /// replays it. Doubles as the `isLaunching` signal.
    @State private var showSplash = true

    @Environment(\.scenePhase) private var scenePhase

    init() {
        // The display face ships inside GamoitsaniDesign, so it is not in the app bundle
        DesignSystem.registerFonts()

        // Before the first `Localization`, which reads the key this writes. A property
        // default would be evaluated ahead of this body, so it is assigned here instead.
        Localization.migrateLegacyLanguage()
        _localization = State(wrappedValue: Localization())
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                root

                if showSplash {
                    // No transition: the cards have already left, so both sides are a
                    // bare surface and there is nothing to fade.
                    SplashView { showSplash = false }
                        .zIndex(1)
                }
            }
            .onChange(of: scenePhase) { was, now in
                guard was != .active, now == .active else { return }
                Task { await showAppOpenAdIfIdle() }
                // Finishes anything a previous launch was killed part-way through. Once
                // active, not during launch: an export needs a background task assertion,
                // and the app cannot take one before it is running.
                Task { await recorder.resumePendingClips() }
            }
        }
    }

    /// The app-open ad, on returning to the foreground and nowhere else.
    ///
    /// Never on a cold launch: the splash is the app's own opening, and an ad on top of it
    /// is the first thing a new player would see. Not interrupting a live round is the
    /// policy's job, not this one's.
    @MainActor
    private func showAppOpenAdIfIdle() async {
        guard !showSplash else { return }
        await ads.showAppOpenIfAllowed()
    }

    @ViewBuilder
    private var root: some View {
        let base = RootView()
            .environment(router)
            .environment(localization)
            .environment(session)
            .environment(sound)
            .environment(haptics)
            .environment(\.adService, ads)
            .environment(\.purchases, store)
            .environment(\.turnRecording, recorder)
            .environment(reviewPrompter)
            .environment(reminders)
            .environment(players)
            .environment(\.isLaunching, showSplash)
            // Formatting follows the language chosen in Settings, not the device's. Without
            // this, `format:` and `.formatted()` would quietly use whatever locale the phone
            // is set to, in an app whose every other string comes from its own picker.
            .environment(\.locale, localization.language.locale)
            // Decoding on first play would hitch on the countdown tick.
            .task { await sound.prepare() }
            .task { await ads.start() }
            .task { await store.start() }
            // Permission can be revoked from iOS Settings while the app is closed, and the
            // schedule needs topping up long before eight weeks of reminders run out.
            .task { await reminders.refresh() }
            // The store owns the entitlement; ads are told about it. `initial: true`
            // covers the ordinary case, where ownership is already known from
            // `currentEntitlements` before anything has changed.
            .onChange(of: store.hasRemovedAds, initial: true) { _, removed in
                ads.setAdsRemoved(removed)
            }
            .tint(Tokens.accent.color)

        #if DEBUG
        base
            .environment(debugSettings)
            .debugMenuOnShake(
                debug: debugSettings,
                session: session,
                ads: ads,
                purchases: store,
                recorder: recorder,
                reviewPrompter: reviewPrompter,
                reminders: reminders,
                players: players
            )
        #else
        base
        #endif
    }
}

/// There is no Home screen. The app opens on setup, because that is what every session
/// starts with and a separate Home was a tap in the way.
struct RootView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            GameSetupView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .game:
                        GameFlowView()
                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
}
