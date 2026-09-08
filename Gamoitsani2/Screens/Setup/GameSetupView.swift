//
//  GameSetupView.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniCore
import GamoitsaniData
import GamoitsaniDesign
import GamoitsaniL10n

/// The app's front door.
struct GameSetupView: View {
    @Environment(Router.self) private var router
    @Environment(Localization.self) private var l10n
    @Environment(GameSession.self) private var session
    #if DEBUG
    @Environment(DebugSettings.self) private var debugSettings
    #endif
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLaunching) private var isLaunching
    @Environment(\.adService) private var ads
    @Environment(\.turnRecording) private var recording
    @Environment(PlayerBook.self) private var players
    @State private var model = GameSetupModel()
    @State private var hasAppeared = false

    /// True while the opening deck is being drawn. The Play button is a `Button`, not a
    /// gate — without this a second tap during the draw starts a second game.
    @State private var isStarting = false

    /// Whether this language's word file has a difficulty spread worth selecting on.
    ///
    /// True for Georgian, which is curated. False for the languages exported from v1's
    /// Firestore, where 99.9% of every file sits at `<= 3` — four tiers there would deal
    /// the same deck three times and call the fourth one Hard.
    @State private var canChooseDifficulty = false

    private let headerHeight: CGFloat = 168

    /// How far the screen has scrolled, driving the header collapse.
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        @Bindable var model = model

        return ScrollView {
            VStack(spacing: Spacing.lg) {
                // In with the rest, or the mark pops into place while everything below
                // it is still rising.
                section(index: 0) {
                    CollapsingFanHeader(height: headerHeight, collapse: headerCollapse)
                }

                if let saved = session.saved {
                    section(index: 1) { resumeCard(saved) }
                }

                section(index: 1) { roundSection }
                section(index: 2) { modeSection }
                if canChooseDifficulty {
                    section(index: 3) { difficultySection }
                }
                section(index: 4) { extrasSection }
                section(index: 5) { teamsSection }

                // Above Play rather than below it: everything under the Play button is
                // read as part of pressing it.
                if ads.isRemoveAdsOfferAllowed {
                    section(index: 6) {
                        RemoveAdsCard {
                            withAnimation(Motion.card(reduceMotion: reduceMotion)) {
                                ads.removeAdsOfferDismissed()
                            }
                        }
                    }
                }

                section(index: 6) { playButton }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            scrollOffset = offset
        }
        .safeAreaInset(edge: .bottom) {
            // Pinned rather than scrolled with the form: an ad that slides under the Play
            // button is an ad placed where a mis-tap costs someone the game.
            BannerAd()
        }
        // Re-asked when the language changes, because the answer is a property of that
        // language's word file, not of the app.
        .task(id: l10n.language) {
            let language = l10n.language.rawValue
            canChooseDifficulty = await BundledWordProvider.hasUsableDifficulty(language: language)
            // Otherwise a tier chosen under Georgian would silently follow you into a
            // language whose file cannot honour it.
            if !canChooseDifficulty { model.settings.difficulty = .mixed }
        }
        .background(Tokens.surface.color.ignoresSafeArea())
        .navigationTitle(l10n("home.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.push(.settings) } label: {
                    Image(systemName: "gearshape")
                }
                .tint(Tokens.onSurface.color)
                .accessibilityLabel(l10n("settings.title"))
            }
        }
        // Not `onAppear` — this is built behind the splash, so the stagger would finish
        // unseen. `initial: true` keeps it immediate when there is no splash to wait for.
        .onChange(of: isLaunching, initial: true) { _, launching in
            guard !launching, !hasAppeared else { return }
            hasAppeared = true
        }
        .onChange(of: l10n.language) { _, language in
            withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                model.applyLanguage(language)
            }
        }
    }

    /// An unfinished game, offered before the setup form.
    private func resumeCard(_ saved: GameState) -> some View {
        SetupPanel(title: l10n("setup.inProgress")) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(saved.currentTeam?.name ?? "")
                        .font(Typography.rowTitle)
                        .foregroundStyle(Tokens.onSurface.color)
                    HStack(spacing: Spacing.xs) {
                        Text("\(l10n("game.round")) \(saved.round) / \(saved.settings.rounds)")
                        if let remaining = saved.pausedRemaining, remaining > 0 {
                            Text("·")
                            // Where the clock stopped, so it is clear the round is waiting
                            // rather than starting over.
                            Text("\(Int(remaining.rounded()))s")
                                .monospacedDigit()
                        }
                    }
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.onSurfaceMuted.color)
                }

                Spacer()

                Button {
                    withAnimation(Motion.card(reduceMotion: reduceMotion)) {
                        session.discardSaved()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Tokens.danger.color)
                        .frame(width: 34, height: 34)
                        .background(Tokens.surface.color)
                        .clipShape(Circle())
                        .frame(width: Sizing.minimumTarget, height: Sizing.minimumTarget)
                        .contentShape(Circle())
                }
                .accessibilityLabel(l10n("setup.discard"))

                Button {
                    session.resume()
                    router.push(.game)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Tokens.onAccent.color)
                        .frame(width: 34, height: 34)
                        .background(Tokens.accent.color)
                        .clipShape(Circle())
                        .frame(width: Sizing.minimumTarget, height: Sizing.minimumTarget)
                        .contentShape(Circle())
                }
                .accessibilityLabel(l10n("setup.resume"))
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    /// Builds the deck and hands the engine a game to run.
    private func startGame() {
        guard !isStarting else { return }
        isStarting = true

        var settings = model.settings
        #if DEBUG
        settings = debugSettings.apply(to: settings)
        #endif
        let teams = model.resolvedTeams
        let language = l10n.language.rawValue

        // Anything gathered for a game that was abandoned rather than finished.
        players.reset()

        Task {
            defer { isStarting = false }
            // Sized from the clock rather than a flat per-turn guess. Whatever this misses
            // by, the deck is topped up during play, so it only has to be a good opening
            // hand rather than the whole game's supply.
            let perTurn = GameSession.wordsPerTurn(roundLength: settings.roundLength)
            let wanted = max(80, teams.count * settings.rounds * perTurn)
            let provider = BundledWordProvider(
                difficulty: settings.difficulty.range,
                seen: session.seenWords
            )
            let deck = (try? await provider.deck(language: language, count: wanted)) ?? Deck(words: [])
            session.start(
                settings: settings,
                teams: teams,
                deck: deck,
                language: BundledWordProvider.resolvedLanguage(for: language)
            )
            router.push(.game)
        }
    }

    /// 0 while the header is fully shown, 1 once it has scrolled away.
    private var headerCollapse: CGFloat {
        min(1, max(0, scrollOffset / headerHeight))
    }

    /// Sections stagger in on first appearance. Reduce Motion collapses the stagger to
    /// zero and the movement to a crossfade — substitution, not deletion.
    private func section<Content: View>(index: Int, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared || reduceMotion ? 0 : 18)
            .animation(
                reduceMotion
                    ? Motion.reduced
                    : Motion.card.delay(Double(index) * 0.06),
                value: hasAppeared
            )
    }

    // MARK: - Round

    private var roundSection: some View {
        SetupPanel(title: l10n("setup.round")) {
            StepperRow(
                label: l10n("setup.rounds"),
                value: "\(model.settings.rounds)",
                canDecrease: model.canDecreaseRounds,
                canIncrease: model.canIncreaseRounds,
                decrease: { model.adjustRounds(by: -1) },
                increase: { model.adjustRounds(by: 1) }
            )
            Divider().overlay(Tokens.cardEdge.color)
            StepperRow(
                label: l10n("setup.length"),
                value: "\(model.roundLengthSeconds)s",
                canDecrease: model.canDecreaseLength,
                canIncrease: model.canIncreaseLength,
                decrease: { model.adjustRoundLength(by: -1) },
                increase: { model.adjustRoundLength(by: 1) }
            )
        }
    }

    // MARK: - Mode

    private var modeSection: some View {
        SetupPanel(title: l10n("setup.mode")) {
            VStack(spacing: Spacing.sm) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: model.settings.mode == mode,
                        reduceMotion: reduceMotion
                    ) {
                        withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                            model.settings.mode = mode
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Difficulty

    private var difficultySection: some View {
        SetupPanel(title: l10n("setup.difficulty")) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    ForEach(WordDifficulty.allCases) { difficulty in
                        let isOn = model.settings.difficulty == difficulty
                        SetupChip(
                            title: l10n("setup.difficulty.\(difficulty.rawValue)"),
                            isOn: isOn,
                            reduceMotion: reduceMotion
                        ) {
                            withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                                model.settings.difficulty = difficulty
                            }
                        } glyph: {
                            DifficultyGlyph(difficulty: difficulty, isOn: isOn)
                        }
                    }
                }

                // The tiers are caps rather than bands — Normal contains every Easy word —
                // so which slice each one draws is worth the line a chip cannot say.
                Text(l10n("setup.difficulty.\(model.settings.difficulty.rawValue).detail"))
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.onSurfaceMuted.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(
                        Motion.control(reduceMotion: reduceMotion),
                        value: model.settings.difficulty
                    )
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Extras

    private var extrasSection: some View {
        SetupPanel(title: l10n("setup.extras")) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    extraChip(
                        key: "setup.superWord",
                        symbol: "star.fill",
                        isOn: model.settings.superWordsEnabled
                    ) { model.settings.superWordsEnabled.toggle() }

                    extraChip(
                        key: "setup.challenge",
                        symbol: "bolt.fill",
                        isOn: model.settings.challengesEnabled
                    ) { model.settings.challengesEnabled.toggle() }

                    // Not a `GameSettings` field. Filming is not a rule of the game, and
                    // adding a property to that persisted struct throws `keyNotFound` on any
                    // game saved before it — which `GameStateStore.load` swallows with
                    // `try?`, losing the game silently on upgrade.
                    extraChip(
                        key: "setup.record",
                        symbol: "record.circle",
                        isOn: recording.isEnabled
                    ) {
                        guard !recording.isEnabled else {
                            recording.isEnabled = false
                            return
                        }
                        // Asked here, once, so the camera and microphone prompts never
                        // land on a running clock the way v1's did.
                        Task { recording.isEnabled = await recording.requestPermissions() }
                    }
                }

                // One line for whichever extras are on, so switching three subtitles for
                // three chips does not lose the explanation of what they actually do.
                Text(activeExtrasDetail)
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.onSurfaceMuted.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(Motion.control(reduceMotion: reduceMotion), value: activeExtrasDetail)
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private func extraChip(
        key: String,
        symbol: String,
        isOn: Bool,
        toggle: @escaping () -> Void
    ) -> some View {
        SetupChip(
            title: l10n(key),
            isOn: isOn,
            reduceMotion: reduceMotion
        ) {
            withAnimation(Motion.control(reduceMotion: reduceMotion)) { toggle() }
        } glyph: {
            Image(systemName: symbol)
                .font(.caption2.weight(.bold))
                .foregroundStyle(isOn ? Tokens.onAccent.color : Tokens.accent.color)
        }
    }

    /// What the chips that are on actually do, or a prompt when none are.
    private var activeExtrasDetail: String {
        var parts: [String] = []
        if model.settings.superWordsEnabled { parts.append(l10n("setup.superWord.detail")) }
        if model.settings.challengesEnabled { parts.append(l10n("setup.challenge.detail")) }
        if recording.isEnabled { parts.append(l10n("setup.record.detail")) }
        return parts.isEmpty ? l10n("setup.extras.none") : parts.joined(separator: " · ")
    }

    // MARK: - Teams

    private var teamsSection: some View {
        SetupPanel(title: l10n("setup.teams")) {
            Picker("", selection: $model.buildMode) {
                ForEach(TeamBuildMode.allCases) { mode in
                    Text(l10n(mode.titleKey)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, Spacing.sm)

            Divider().overlay(Tokens.cardEdge.color)

            if model.buildMode == .draw {
                PlayerRoster(model: model)
                Divider().overlay(Tokens.cardEdge.color)
            }

            ForEach(Array(model.teams.enumerated()), id: \.element.id) { index, team in
                TeamRow(
                    index: index,
                    team: team,
                    name: Binding(
                        get: { model.draftNames[team.id] ?? team.name },
                        set: { model.setName($0, for: team) }
                    ),
                    problem: model.problem(for: team),
                    // The draw owns how many teams there are, so removing one by hand
                    // while in draw mode would just be undone by the next shuffle.
                    canRemove: model.canRemoveTeam && model.buildMode == .byHand,
                    remove: {
                        withAnimation(Motion.card(reduceMotion: reduceMotion)) {
                            model.removeTeam(team)
                        }
                    },
                    isUsingDefaultName: model.isUsingDefaultName(team),
                    roster: {
                        // Only once a team has a line-up. Teams named by hand never gain
                        // one unless someone starts adding people to it.
                        if !team.members.isEmpty || model.buildMode == .draw {
                            TeamRoster(model: model, team: team)
                        }
                    }
                )
                if index < model.teams.count - 1 {
                    Divider().overlay(Tokens.cardEdge.color)
                }
            }

            if model.canAddTeam, model.buildMode == .byHand {
                Divider().overlay(Tokens.cardEdge.color)
                Button {
                    withAnimation(Motion.card(reduceMotion: reduceMotion)) { model.addTeam() }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text(l10n("setup.addTeam"))
                    }
                    .font(Typography.rowTitle)
                    .foregroundStyle(Tokens.accent.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.sm)
                    .contentShape(Rectangle())
                }
            }
        }
        .animation(Motion.card(reduceMotion: reduceMotion), value: model.buildMode)
    }

    private var playButton: some View {
        Button {
            startGame()
        } label: {
            Text(l10n("setup.play"))
                .font(Typography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        }
        .buttonStyle(PrimaryButtonStyle(reduceMotion: reduceMotion))
        .disabled(!model.canStart || isStarting)
        .opacity(model.canStart ? 1 : 0.5)
        .animation(Motion.control(reduceMotion: reduceMotion), value: model.canStart)
        .padding(.top, Spacing.xs)
    }
}

#Preview("Setup — dark") {
    NavigationStack { GameSetupView().environment(Router()) }
        .preferredColorScheme(.dark)
}

#Preview("Setup — light") {
    NavigationStack { GameSetupView().environment(Router()) }
        .preferredColorScheme(.light)
}
