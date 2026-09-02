//
//  GameReducer.swift
//  GamoitsaniCore
//

import Foundation

/// Applies events to state. Pure: same inputs, same output, no clock, no I/O, no
/// randomness beyond what is handed in.
///
/// This is the entire game. Everything above it — the `@Observable` engine, the views, the
/// animations — is presentation. That separation is what lets the rules be tested
/// exhaustively in milliseconds, and it is the thing v1 most lacked: its rules were spread
/// across five view models, a singleton, and a handful of `asyncAfter` closures.
public enum GameReducer {

    /// Returns the new state, or the reason the event was refused.
    public static func reduce(
        _ state: GameState,
        _ event: GameEvent,
        at now: Date
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
            next.resetForRematch()
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
        // *toggled* `isGuessed`, so re-tapping a card subtracted the points again and
        // incremented `wordsSkipped` — the same word counted as both guessed and skipped,
        // inflating every statistic and breaking the streak. Answering is one-way.
        guard let word = state.turnWords.first(where: { $0.id == wordID }),
              !state.playedWordIDs.contains(wordID) else {
            return .failure(.wordNotInPlay(wordID))
        }

        next.markPlayed(wordID)
        next.updateCurrentTeam { $0.record(outcome, isSuperWord: word.isSuperWord, at: now) }

        // The allowance is spent when the word is *played*, not when it is generated. v1
        // marked it at generation in arcade, so a super word the team never reached still
        // burned their one per round.
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
            // true when every scheduled round is played but the leaders are level, and the
            // rotation simply continues. v1 expressed the same thing by writing an unread
            // `currentExtraRound` and falling through to `.info`.
            next.setPhase(.turnInfo)
        }

        return next
    }
}
