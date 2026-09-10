//
//  GameSession.swift
//  Gamoitsani2
//

import Foundation
import Observation
import GamoitsaniCore
import GamoitsaniData
import GamoitsaniEngine
import GamoitsaniL10n

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

    /// The ids the current deck started with, and the language they came from. Kept because
    /// the deck only knows what is left, and what was played is the difference.
    private var deckIDs: Set<String> = []
    private var deckLanguage = ""

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
        let engine = GameEngine(state: GameState(settings: settings, teams: teams, deck: deck))
        self.engine = engine
        deckIDs = Set(deck.remainingIDs)
        deckLanguage = language
        saved = nil
        store.clear()
        return engine
    }

    @discardableResult
    func resume() -> GameEngine? {
        guard var state = saved else { return nil }
        // Restart the clock with whatever was left on it when the game was put down.
        state.resumeClock(at: Date())
        let engine = GameEngine(state: state)
        self.engine = engine

        // Tracking restarts from what is left, not from the original deck — anything played
        // before the last checkpoint was already recorded as seen.
        deckIDs = Set(state.deck.remainingIDs)
        deckLanguage = BundledWordProvider.resolvedLanguage(for: Localization.storedLanguage.rawValue)
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
        let language = deckLanguage
        let difficulty = settings.difficulty.range
        let excluded = Set(deckIDs.compactMap(Int.init))

        Task {
            defer { isToppingUp = false }
            let provider = BundledWordProvider(difficulty: difficulty, seen: seenWords)
            let words = (try? await provider.more(
                language: language, count: perTurn * 2, excluding: excluded
            )) ?? []

            guard !words.isEmpty, let engine = self.engine else { return }
            if engine.send(.deckRefilled(words)) {
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
        let language = deckLanguage
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
