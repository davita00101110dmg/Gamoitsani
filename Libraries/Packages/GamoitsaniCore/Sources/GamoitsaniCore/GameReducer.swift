//
//  GameReducer.swift
//  GamoitsaniCore
//
import Foundation

/// Applies events to state. Pure: same inputs, same output, no clock, no I/O, no
public enum GameReducer {

    /// Returns the new state, or the reason the event was refused.
    ///
    /// `nextPlacement` is supplied rather than drawn, for the same reason `now` is: the
    /// reducer must give the same answer for the same inputs. Only `.rematch` reads it.
    public static func reduce(
        _ state: GameState,
        _ event: GameEvent,
        at now: Date,
        nextPlacement: SuperWordPlacement = .random()
    ) -> Result<GameState, GameEventRejection> {
        var next = state

        switch event {

        case .beginTurn:
            guard state.phase == .turnInfo else { return .failure(.wrongPhase(state.phase)) }
            guard GameRules.canStartTurn(state) else { return .failure(.deckExhausted) }
            next.setPhase(state.settings.challengesEnabled ? .challenge : .countdown)
            return .success(next)

        case .acknowledgeChallenge:
            guard state.phase == .challenge else { return .failure(.wrongPhase(state.phase)) }
            next.setPhase(.countdown)
            return .success(next)

        case .countdownFinished:
            guard state.phase == .countdown else { return .failure(.wrongPhase(state.phase)) }
            next.clearTurn()
            next.dealSet()
            next.setRoundEnd(now.addingTimeInterval(state.settings.roundLength))
            next.setPhase(.playing)
            next.updateCurrentTeam { $0.beginGuessing(at: now) }
            return .success(next)

        case let .answer(wordID, outcome):
            guard state.phase == .playing else { return .failure(.wrongPhase(state.phase)) }
            return answer(next, wordID: wordID, outcome: outcome, at: now)

        case let .undoAnswer(wordID):
            guard state.phase == .playing else { return .failure(.wrongPhase(state.phase)) }
            return undo(next, wordID: wordID)

        case .skipSet:
            guard state.phase == .playing else { return .failure(.wrongPhase(state.phase)) }
            guard state.settings.mode == .arcade else {
                return .failure(.notAvailableInMode(state.settings.mode))
            }
            next.updateCurrentTeam { $0.skipSet(mode: state.settings.mode) }
            next.advanceSet()
            next.dealSet()
            next.updateCurrentTeam { $0.beginGuessing(at: now) }
            return .success(next)

        case .timeExpired:
            guard state.phase == .playing else { return .failure(.wrongPhase(state.phase)) }
            return .success(endTurn(next))

        case .rematch:
            guard state.phase == .finished else { return .failure(.wrongPhase(state.phase)) }
            next.resetForRematch(placement: nextPlacement)
            return .success(next)
        }
    }

    /// Folds the result of outside work into the game.
    ///
    /// Separate from `reduce` so that effect results cannot arrive by the same door as
    /// user intent. Accepted in any phase but `.finished`, because the work is
    /// asynchronous and the game will usually have moved on by the time it lands.
    public static func apply(
        _ state: GameState,
        _ effect: GameEffect
    ) -> Result<GameState, GameEventRejection> {
        var next = state

        switch effect {
        case let .deckRefilled(words):
            guard state.phase != .finished else { return .failure(.wrongPhase(state.phase)) }
            next.refillDeck(with: words)
            return .success(next)
        }
    }

    // MARK: - Answering a word

    private static func answer(
        _ state: GameState,
        wordID: String,
        outcome: PlayOutcome,
        at now: Date
    ) -> Result<GameState, GameEventRejection> {
        var next = state

        // A word must be in the current turn and not already answered. v1's arcade
        guard let word = state.turnWords.first(where: { $0.id == wordID }),
              !state.playedWordIDs.contains(wordID) else {
            return .failure(.wordNotInPlay(wordID))
        }

        next.markPlayed(wordID, as: outcome)
        next.updateCurrentTeam { $0.record(outcome, isSuperWord: word.isSuperWord, at: now) }

        // The allowance is spent when the word is *played*, not when it is generated. v1
        if word.isSuperWord, let team = next.currentTeam {
            next.spendSuperWord(for: team.id)
        }

        if GameRules.isSetComplete(next) {
            next.advanceSet()
            next.dealSet()
        }

        next.updateCurrentTeam { $0.beginGuessing(at: now) }
        return .success(next)
    }

    /// Takes a word back off the scoreboard.
    private static func undo(
        _ state: GameState,
        wordID: String
    ) -> Result<GameState, GameEventRejection> {
        var next = state

        guard let word = state.turnWords.first(where: { $0.id == wordID }),
              let outcome = state.playedOutcomes[wordID] else {
            return .failure(.wordNotInPlay(wordID))
        }

        next.unmarkPlayed(wordID)
        next.updateCurrentTeam { $0.undo(outcome, isSuperWord: word.isSuperWord) }

        // The once-per-round super word allowance is returned too, or a mistaken tap would
        // silently cost the team their only super word of the round.
        if word.isSuperWord, outcome == .correct, let team = next.currentTeam {
            next.returnSuperWord(to: team.id)
        }

        return .success(next)
    }

    // MARK: - Ending a turn

    /// Rotates to the next team and decides whether the game is over, another round is
    /// due, or a tie forces an extra one.
    private static func endTurn(_ state: GameState) -> GameState {
        var next = state
        next.setRoundEnd(nil)
        next.clearTurn()
        next.advanceTurn()

        if GameRules.isGameOver(next) {
            next.setPhase(.finished)
        } else {
            // Covers both a normal next turn and a tie-break round: `needsExtraRound` is
            next.setPhase(.turnInfo)
        }

        return next
    }
}
