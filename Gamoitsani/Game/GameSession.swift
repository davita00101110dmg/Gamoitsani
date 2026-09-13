//
//  GameSession.swift
//  Gamoitsani
//

import Foundation
import Observation
import GamoitsaniCore
import GamoitsaniData
import GamoitsaniEngine

/// Holds the engine for the game currently being played, and remembers it across launches.
@MainActor
@Observable
final class GameSession {

    private(set) var engine: GameEngine?

    /// A game left unfinished, restorable from a previous launch or an earlier exit.
    private(set) var saved: GameState?

    private let store: GameStateStore

    /// Words this device has already played, so a group works through the database rather
    /// than meeting the same cards every few evenings.
    let seenWords: SeenWords

    /// The ids the current deck started with. Kept because the deck only knows what is
    /// left, and what was played is the difference.
    private var deckIDs: Set<String> = []

    /// Bumped whenever the game changes. A draw started for one game carries the number it
    /// began under and is discarded if it comes back to a different one — otherwise words
    /// fetched for a Hard Georgian game could land in the Easy English game that replaced
    /// it while the draw was still in flight.
    private var generation = 0

    /// One top-up at a time, so a burst of deals cannot fire several overlapping draws.
    private var isToppingUp = false

    init(store: GameStateStore = GameStateStore(), seenWords: SeenWords = SeenWords()) {
        self.store = store
        self.seenWords = seenWords
        self.saved = store.load()
    }

    var isActive: Bool { engine != nil }
    var canResume: Bool { saved != nil }

    @discardableResult
    func start(
        settings: GameSettings,
        teams: [Team],
        deck: Deck,
        language: String = "ka"
    ) -> GameEngine {
        let engine = GameEngine(
            state: GameState(
                settings: settings,
                teams: teams,
                deck: deck,
                deckLanguage: language,
                // Dealt once, here, so each team keeps its rule for the whole game.
                challenges: settings.challengesEnabled ? Challenge.draw(for: teams) : [:]
            )
        )
        self.engine = engine
        deckIDs = Set(deck.remainingIDs)
        generation += 1
        // Restorable from the moment it exists, rather than from the first phase change.
        //
        // This is a layout fix as much as a safety one. `saved` drives the resume card at
        // the top of the setup form, and the setup screen is the navigation root — it
        // stays alive behind the game. Persisting only on the way out meant the card was
        // inserted while that screen was already back on display, shoving the whole form
        // down by its height. Doing it here settles the layout while the game is covering
        // it, so coming back moves nothing.
        //
        // It also means a force-quit between Play and the first turn no longer loses the
        // game it just dealt.
        persist(engine.state)
        return engine
    }

    @discardableResult
    func resume() -> GameEngine? {
        guard var state = saved else { return nil }
        // Restart the clock with whatever was left on it when the game was put down.
        state.resumeClock(at: Date())
        // A game saved before challenges existed has the setting on and no rules, which
        // would put an empty card on the challenge screen. Deal them now instead.
        if state.settings.challengesEnabled && state.challenges.isEmpty {
            state.assignChallenges(Challenge.draw(for: state.teams))
        }
        let engine = GameEngine(state: state)
        self.engine = engine

        // Tracking restarts from what is left, not from the original deck — anything played
        // before the last checkpoint was already recorded as seen. The deck's language
        // comes back with the saved state, so switching language mid-game no longer files
        // the words under whatever is on screen now.
        deckIDs = Set(state.deck.remainingIDs)
        generation += 1
        return engine
    }

    /// Leaves the current game, keeping it restorable unless it had finished.
    func leave() {
        if let state = engine?.state {
            recordSeenWords(from: state)
            if state.phase != .finished {
                persist(state)
            } else {
                saved = nil
                store.clear()
            }
        }
        engine = nil
        // Nothing in flight belongs to a game that has been left.
        generation += 1
    }

    /// Persists progress as the game moves between phases, or when the app goes away.
    func checkpoint() {
        guard let state = engine?.state, state.phase != .finished else { return }
        persist(state)
        // Here too, so a force-quit costs at most the current turn's words.
        recordSeenWords(from: state)
    }

    /// How many words one turn can plausibly get through.
    ///
    /// A quick pair answers about one word every two seconds, which is the ceiling worth
    /// planning for — the old figure was a flat 15 a turn, and a 2-team game ran dry
    /// part-way through the first round.
    static func wordsPerTurn(roundLength: TimeInterval) -> Int {
        max(20, Int((roundLength / 2).rounded(.up)))
    }

    /// Draws more words when the deck gets low, so a game cannot dead-end on an empty deck.
    ///
    /// Everything already dealt into this game is excluded, so a top-up never repeats a
    /// card the group has just seen.
    func topUpDeckIfNeeded() {
        guard let engine, engine.state.phase != .finished, !isToppingUp else { return }

        let settings = engine.state.settings
        let perTurn = Self.wordsPerTurn(roundLength: settings.roundLength)
        guard engine.state.deck.count < perTurn else { return }

        isToppingUp = true
        let language = engine.state.deckLanguage
        let difficulty = settings.difficulty.range
        let excluded = Set(deckIDs.compactMap(Int.init))
        let startedUnder = generation

        Task {
            defer { isToppingUp = false }
            let provider = BundledWordProvider(difficulty: difficulty, seen: seenWords)
            let words = (try? await provider.more(
                language: language, count: perTurn * 2, excluding: excluded
            )) ?? []

            // The game that asked for these may be over, or replaced, by now.
            guard !words.isEmpty,
                  startedUnder == generation,
                  let engine = self.engine
            else { return }

            if engine.apply(.deckRefilled(words)) {
                deckIDs.formUnion(words.map(\.id))
            }
        }
    }

    /// Records the words this game actually got through.
    ///
    /// What was played is the deck it started with minus what is left. Recording the whole
    /// deck up front would burn hundreds of words the group never saw.
    private func recordSeenWords(from state: GameState) {
        let played = deckIDs.subtracting(state.deck.remainingIDs).compactMap(Int.init)
        guard !played.isEmpty else { return }
        // The deck's own language, not the one on screen — they differ after a fallback,
        // and after switching language mid-game.
        let language = state.deckLanguage
        Task { await seenWords.record(played, language: language) }
    }

    /// A saved game is a paused game.
    ///
    /// The clock is frozen on the way to disk, so a round abandoned at 38 seconds is
    /// waiting at 38 seconds however long it takes to come back. The live engine keeps its
    /// wall-clock deadline, so merely suspending the app still costs you the time.
    private func persist(_ state: GameState) {
        var paused = state
        paused.pauseClock(at: Date())
        saved = paused
        store.save(paused)
    }

    func discardSaved() {
        saved = nil
        store.clear()
    }
}

/// Writes the game to disk as one JSON value.
struct GameStateStore {

    private let url: URL

    init(filename: String = "game-in-progress.json") {
        let directory = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appending(path: filename)
    }

    func save(_ state: GameState) {
        // A lost save costs a resume, not a game.
        try? JSONEncoder().encode(state).write(to: url, options: .atomic)
    }

    func load() -> GameState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(GameState.self, from: data)
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
