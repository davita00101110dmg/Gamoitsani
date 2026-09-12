//
//  TurnRecording.swift
//  Gamoitsani
//
import SwiftUI
import UIKit
import GamoitsaniCapture

/// What the recorder is doing.
enum TurnRecordingState: Sendable, Equatable {
    case idle
    case recording
    /// The clip is being composed with its overlay. This happens on the turn-info screen,
    /// while the phone is being handed to the next player.
    case exporting
    case failed(RecordingRefusal)
}

/// Filming a turn, as the app sees it.
///
/// Screens talk to this and never import AVFoundation, so they stay previewable and the
/// capture stack can be replaced without touching them.
@MainActor
protocol TurnRecording: AnyObject {
    var state: TurnRecordingState { get }

    /// Whether the player asked for this game to be filmed.
    var isEnabled: Bool { get set }

    /// Asks for camera and microphone access. Called from the setup screen when the toggle
    /// goes on, so the prompts never land on a running clock the way v1's did.
    func requestPermissions() async -> Bool

    /// Starts filming a turn. Does nothing unless enabled and permitted.
    func startTurn(teamName: String, roundLength: TimeInterval)

    /// A word appeared on screen.
    func wordShown(_ word: String)

    /// A word left the screen.
    func wordAnswered(_ word: String, outcome: RecordingOutcome)

    /// A word was taken back, so the overlay must un-score it.
    func undoAnswer(_ word: String)

    /// Ends the turn, then exports and saves if the clip is worth keeping.
    func finishTurn()

    /// Abandons the current clip without exporting — the player left mid-turn.
    func cancelTurn()

    /// The game is over: cut every turn filmed into one reel and save it.
    ///
    /// `endCard` closes the video with the final scores.
    func finishGame(endCard: UIImage?)
}

/// A recorder that never touches the camera.
///
/// For previews, and for any build that should not reach AVFoundation. Having a real
/// implementation of "not filming" means call sites never branch on whether recording
/// exists.
@MainActor
final class NoRecording: TurnRecording {
    nonisolated init() {}

    var state: TurnRecordingState { .idle }
    var isEnabled: Bool {
        get { false }
        set {}
    }

    func requestPermissions() async -> Bool { false }
    func startTurn(teamName: String, roundLength: TimeInterval) {}
    func wordShown(_ word: String) {}
    func wordAnswered(_ word: String, outcome: RecordingOutcome) {}
    func undoAnswer(_ word: String) {}
    func finishTurn() {}
    func cancelTurn() {}
    func finishGame(endCard: UIImage?) {}
}

extension EnvironmentValues {
    /// Recording, as the app sees it. Defaults to none so previews never open a camera.
    @Entry var turnRecording: any TurnRecording = NoRecording()
}
