//
//  RecordingBridge.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniCapture
import GamoitsaniCore
import GamoitsaniEngine

/// Turns engine state into recorder calls.
///
/// One observer, not instrumentation at the call sites. Answers are dispatched from four
/// places across the two play screens — the classic buttons, the arcade rows, arcade undo
/// and skip-set — and a fifth added later would silently never be recorded. Everything
/// here is derived from `turnWords` and `playedOutcomes`, so there is nothing to remember
/// to call.
@MainActor
@Observable
final class RecordingBridge {

    @ObservationIgnored private var shown: Set<String> = []
    @ObservationIgnored private var outcomes: [String: PlayOutcome] = [:]
    @ObservationIgnored private var isRecordingTurn = false

    func sync(_ state: GameState, to recorder: any TurnRecording) {
        guard state.phase == .playing else {
            if isRecordingTurn { finish(recorder) }
            return
        }

        if !isRecordingTurn {
            isRecordingTurn = true
            RecordingLog.note("bridge: turn begins")
            shown = []
            outcomes = [:]
            recorder.startTurn(
                teamName: state.currentTeam?.name ?? "",
                roundLength: state.settings.roundLength
            )
        }

        // Anything on the table that has not been announced yet. In classic that is one
        // word; in arcade it is the whole set at the start of each one.
        for word in GameRules.unplayedWords(state) where !shown.contains(word.id) {
            shown.insert(word.id)
            RecordingLog.note("bridge: shown \(word.text)")
            recorder.wordShown(word.text)
        }

        let byID = Dictionary(uniqueKeysWithValues: state.turnWords.map { ($0.id, $0.text) })

        // Newly answered.
        for (id, outcome) in state.playedOutcomes where outcomes[id] != outcome {
            guard let text = byID[id] else { continue }
            // A word can only be shown once before it is answered, but a deck that wraps
            // can deal it again later — announce it if the diff caught it mid-flight.
            if !shown.contains(id) {
                shown.insert(id)
                recorder.wordShown(text)
            }
            RecordingLog.note("bridge: answered \(text) \(outcome)")
            recorder.wordAnswered(text, outcome: outcome == .correct ? .correct : .skipped)
        }

        // Taken back. Arcade lets a wrong tap be undone while the card is still on the
        // table, and without this the overlay keeps the score it should have given up.
        for id in outcomes.keys where state.playedOutcomes[id] == nil {
            guard let text = byID[id] else { continue }
            recorder.undoAnswer(text)
        }

        outcomes = state.playedOutcomes
    }

    /// The game was left, or the screen went away, mid-turn.
    func abandon(_ recorder: any TurnRecording) {
        guard isRecordingTurn else { return }
        RecordingLog.note("bridge: abandoned")
        isRecordingTurn = false
        shown = []
        outcomes = [:]
        recorder.cancelTurn()
    }

    private func finish(_ recorder: any TurnRecording) {
        RecordingLog.note("bridge: turn ends")
        isRecordingTurn = false
        shown = []
        outcomes = [:]
        recorder.finishTurn()
    }
}
