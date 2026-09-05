//
//  RecordingPolicyTests.swift
//  GamoitsaniCaptureTests
//

import Foundation
import Testing
@testable import GamoitsaniCapture

@Suite("Recording policy")
struct RecordingPolicyTests {

    private let policy = RecordingPolicy()

    private func conditions(free: Int64 = 8 * 1024 * 1024 * 1024) -> RecordingConditions {
        RecordingConditions(
            isEnabled: true,
            hasCamera: true,
            hasMicrophone: true,
            freeDiskBytes: free
        )
    }

    @Test("a healthy device records")
    func happyPath() {
        #expect(policy.refusalToRecord(conditions(), roundLength: 60) == nil)
    }

    @Test("switched off means no camera is ever touched")
    func disabled() {
        var state = conditions()
        state.isEnabled = false
        #expect(policy.refusalToRecord(state, roundLength: 60) == .disabled)
    }

    /// v1 checked only the microphone, so denying the camera produced a recording with no
    /// picture and no explanation.
    @Test("a denied camera refuses instead of recording nothing")
    func cameraDenied() {
        var state = conditions()
        state.hasCamera = false
        #expect(policy.refusalToRecord(state, roundLength: 60) == .cameraDenied)
    }

    @Test("a denied microphone refuses")
    func microphoneDenied() {
        var state = conditions()
        state.hasMicrophone = false
        #expect(policy.refusalToRecord(state, roundLength: 60) == .microphoneDenied)
    }

    @Test("a full disk refuses before the camera starts")
    func notEnoughDisk() {
        // Typed, not an inline literal. Inside the `#expect` macro expansion the literal
        // loses its context and defaults to `Int`, which fails to convert to `Int64` —
        // under `xcodebuild` only, so `swift test` passes and CI does not.
        let free: Int64 = 10 * 1024 * 1024
        let state = conditions(free: free)
        let needed = policy.requiredBytes(forRoundLength: 60)
        #expect(
            policy.refusalToRecord(state, roundLength: 60)
                == .notEnoughDisk(freeBytes: free, needsBytes: needed)
        )
    }

    /// The export writes a second copy before the original goes, so the estimate has to
    /// cover both at once.
    @Test("the space estimate covers the clip and its export")
    func requirementCoversBothCopies() {
        let needed = policy.requiredBytes(forRoundLength: 60)
        let oneClip = Int64(60) * policy.bytesPerSecond
        #expect(needed == oneClip * 2 + policy.reservedDiskBytes)
    }

    @Test("a stuck clock cannot demand unbounded space")
    func durationIsCapped() {
        let absurd = policy.requiredBytes(forRoundLength: 86_400)
        let capped = policy.requiredBytes(forRoundLength: policy.maximumDuration)
        #expect(absurd == capped)
    }

    @Test("a turn abandoned after two seconds is not worth exporting")
    func tooShortToKeep() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 0)
        timeline.finish(at: 2)
        #expect(!policy.isWorthKeeping(timeline))
    }

    @Test("a clip where nothing happened is not worth exporting")
    func nothingHappened() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.finish(at: 30)
        #expect(!policy.isWorthKeeping(timeline))
    }

    @Test("an unfinished timeline is never exported")
    func unfinished() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 0)
        #expect(!policy.isWorthKeeping(timeline))
    }

    @Test("a real turn is kept")
    func worthKeeping() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 0)
        timeline.wordAnswered("ა", outcome: .correct, at: 4)
        timeline.finish(at: 30)
        #expect(policy.isWorthKeeping(timeline))
    }
}
