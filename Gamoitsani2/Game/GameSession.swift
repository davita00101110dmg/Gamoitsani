//
//  GameSession.swift
//  Gamoitsani2
//

import Foundation
import Observation
import GamoitsaniCore
import GamoitsaniEngine

/// Holds the engine for the game currently being played, and remembers it across launches.
@MainActor
@Observable
final class GameSession {

    private(set) var engine: GameEngine?

    /// A game left unfinished, restorable from a previous launch or an earlier exit.
    private(set) var saved: GameState?

    private let store: GameStateStore

    init(store: GameStateStore = GameStateStore()) {
        self.store = store
        self.saved = store.load()
    }

    var isActive: Bool { engine != nil }
    var canResume: Bool { saved != nil }

    @discardableResult
    func start(settings: GameSettings, teams: [Team], deck: Deck) -> GameEngine {
        let engine = GameEngine(state: GameState(settings: settings, teams: teams, deck: deck))
        self.engine = engine
        saved = nil
        store.clear()
        return engine
    }

    @discardableResult
    func resume() -> GameEngine? {
        guard let saved else { return nil }
        let engine = GameEngine(state: saved)
        self.engine = engine
        return engine
    }

    /// Leaves the current game, keeping it restorable unless it had finished.
    func leave() {
        if let state = engine?.state, state.phase != .finished {
            saved = state
            store.save(state)
        } else {
            saved = nil
            store.clear()
        }
        engine = nil
    }

    /// Persists progress as the game moves between phases.
    func checkpoint() {
        guard let state = engine?.state, state.phase != .finished else { return }
        saved = state
        store.save(state)
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
