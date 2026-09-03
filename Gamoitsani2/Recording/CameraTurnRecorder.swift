//
//  CameraTurnRecorder.swift
//  Gamoitsani2
//
import AVFoundation
import Observation
import UIKit
import Photos
import GamoitsaniCapture

/// Films a turn with the front camera, then burns the word overlay in on the way out.
///
/// The screen is never captured. v1 used ReplayKit and got the face into the video only
/// because the camera preview happened to be on screen — which also meant every banner and
/// interstitial was recorded, and the faces were whatever `.medium` gave.
@MainActor
@Observable
final class CameraTurnRecorder: NSObject, TurnRecording {

    private(set) var state: TurnRecordingState = .idle
    var isEnabled = false

    @ObservationIgnored private let policy = RecordingPolicy()
    @ObservationIgnored private let capture = CaptureSessionBox()

    @ObservationIgnored private var timeline: RecordingTimeline?
    @ObservationIgnored private var clipStart: CFTimeInterval?
    /// Held for the life of the recording.
    ///
    /// `AVCaptureMovieFileOutput` does not keep its recording delegate alive, so an
    /// inline-constructed one is deallocated before the file is written and
    /// `didFinishRecordingTo` never arrives. Everything downstream of that callback —
    /// stopping the session, the export, the Photos save — then silently never happens.
    @ObservationIgnored private var delegateProxy: RecordingDelegateProxy?

    /// Set the instant a turn starts filming, cleared only when the file has been dealt
    /// with. Stopping is gated on this rather than on `state`, which is published a moment
    /// later from the session queue — a turn ended inside that window used to leave the
    /// camera running for the rest of the game.
    @ObservationIgnored private var isFilming = false

    /// Recovery runs once per process.
    ///
    /// It is triggered by the scene becoming active, and that happens more than once per
    /// launch — a full-screen ad, the app switcher, an interruption. Without this the same
    /// clip is retried several times in one session, which burned every attempt it had
    /// before the first export even finished.
    @ObservationIgnored private var didResume = false

    // MARK: - Permissions

    /// Asked from the setup screen, so the prompts never land on a running clock the way
    /// v1's did — it requested them mid-game, behind a 0.5s delay, as the round began.
    func requestPermissions() async -> Bool {
        let camera = await AVCaptureDevice.requestAccess(for: .video)
        let microphone = await AVCaptureDevice.requestAccess(for: .audio)
        // Add-only. The app writes clips and never reads the library.
        let photos = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        guard camera else {
            state = .failed(.cameraDenied)
            return false
        }
        guard microphone else {
            state = .failed(.microphoneDenied)
            return false
        }
        return photos == .authorized || photos == .limited
    }

    private var conditions: RecordingConditions {
        RecordingConditions(
            isEnabled: isEnabled,
            hasCamera: AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
            hasMicrophone: AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
            freeDiskBytes: Self.freeDiskBytes
        )
    }

    /// `volumeAvailableCapacityForImportantUsage`, not a ratio of `systemFreeSize` — the
    /// latter is unreliable and reports nonsense on a simulator.
    private static var freeDiskBytes: Int64 {
        let values = try? URL.documentsDirectory.resourceValues(
            forKeys: [.volumeAvailableCapacityForImportantUsageKey]
        )
        return values?.volumeAvailableCapacityForImportantUsage ?? 0
    }

    // MARK: - A turn

    func startTurn(teamName: String, roundLength: TimeInterval) {
        guard !isFilming, state != .exporting else { return }

        // Cleared rather than inspected: a refusal on one turn — a full disk that has
        // since been emptied — must not disable filming for the rest of the game.
        state = .idle

        if let refusal = policy.refusalToRecord(conditions, roundLength: roundLength) {
            // `.disabled` is the ordinary case — most games are not filmed — and is not
            // worth telling anyone about.
            state = refusal == .disabled ? .idle : .failed(refusal)
            return
        }

        isFilming = true
        timeline = RecordingTimeline(teamName: teamName)
        // Durable storage, not `temporaryDirectory`: a clip has to survive the app being
        // killed between filming and saving.
        let url = PendingClipStore.newClipURL()

        let proxy = RecordingDelegateProxy(recorder: self)
        delegateProxy = proxy

        capture.start { [weak self, capture, policy] in
            capture.beginRecording(
                to: url,
                maximumDuration: policy.maximumDuration,
                delegate: proxy
            )
            Task { @MainActor in
                // `isFilming` rather than the state: a turn that ended before the session
                // finished starting must not be marked as recording afterwards.
                guard let self, self.isFilming else { return }
                // The clip's clock starts here rather than at its first frame. The gap is a
                // few frames, and the timeline clamps anything arriving early rather than
                // producing a negative interval.
                self.clipStart = CACurrentMediaTime()
                self.state = .recording
            }
        }
    }

    func wordShown(_ word: String) {
        guard state == .recording, let elapsed else { return }
        timeline?.wordShown(word, at: elapsed)
    }

    func wordAnswered(_ word: String, outcome: RecordingOutcome) {
        guard state == .recording, let elapsed else { return }
        timeline?.wordAnswered(word, outcome: outcome, at: elapsed)
    }

    func undoAnswer(_ word: String) {
        guard state == .recording else { return }
        timeline?.undoAnswer(word)
    }

    func finishTurn() {
        guard isFilming else { return }
        timeline?.finish(at: elapsed ?? 0)
        state = .exporting
        capture.stopRecording()
    }

    /// Finishes any clip left behind by a previous launch.
    ///
    /// Called at startup. A force-quit during an export used to lose the clip outright;
    /// now the footage and its timeline are both on disk, so it can simply be finished.
    func resumePendingClips() async {
        guard !didResume else { return }
        didResume = true

        for pending in PendingClipStore.pending() {
            // Counted on disk before the attempt, so a clip that kills the process runs
            // out of chances instead of killing every future launch.
            guard PendingClipStore.beginAttempt(for: pending.clip) else { continue }
            await export(pending.clip, timeline: pending.timeline)
        }
    }

    /// The player left mid-turn. The footage exists but describes nothing, so it goes.
    func cancelTurn() {
        guard isFilming else { return }
        // Cleared before the callback arrives, so `handleFinishedClip` finds no timeline
        // and deletes the footage instead of exporting a turn nobody finished.
        timeline = nil
        state = .idle
        capture.stopRecording()
    }

    private var elapsed: TimeInterval? {
        clipStart.map { CACurrentMediaTime() - $0 }
    }

    // MARK: - Finishing

    fileprivate func handleFinishedClip(at url: URL) async {
        let finished = timeline
        timeline = nil
        clipStart = nil
        delegateProxy = nil
        isFilming = false
        // Releases the camera. A party game is put down constantly, and holding the device
        // between turns keeps the orange indicator lit for no reason.
        capture.stop()

        // A clip stopped by `maxRecordedDuration` arrives with an error and a perfectly
        // usable file, so the file's existence decides this, not the error.
        let exists = FileManager.default.fileExists(atPath: url.path)

        guard let finished, exists, policy.isWorthKeeping(finished) else {
            PendingClipStore.discard(url)
            state = .idle
            return
        }

        // Written before the export starts, so being killed mid-export costs time rather
        // than the clip.
        PendingClipStore.write(finished, for: url)
        await export(url, timeline: finished)
        state = .idle
    }

    /// Composes the overlay and saves the result, then removes both copies.
    private func export(_ clip: URL, timeline: RecordingTimeline) async {
        // The export outlives the turn-info screen if the player backgrounds the app, and
        // without this iOS suspends it part-written.
        //
        // The identifier is checked before it is ended. `beginBackgroundTask` returns
        // `.invalid` when the app is not in a state to take one — during launch, which is
        // exactly when pending clips are resumed — and ending an invalid identifier traps.
        let task = UIApplication.shared.beginBackgroundTask(withName: "gamoitsani.export")
        defer {
            if task != .invalid {
                UIApplication.shared.endBackgroundTask(task)
            }
        }

        guard let exported = await RecordingExporter.export(clip: clip, timeline: timeline) else {
            // Leave the pair in place. The next launch tries again rather than throwing
            // away footage that may only have lost to a locked screen or a busy device.
            noteExportFailure("export returned no file")
            return
        }

        await Self.saveToPhotos(exported)
        // Both copies go. v1 left every recording in Documents forever, invisible to the
        // player, on top of the copy it had already put in Photos.
        Self.delete(exported)
        PendingClipStore.discard(clip)
    }

    private static func saveToPhotos(_ url: URL) async {
        try? await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: url, options: nil)
        }
    }

    private static func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func noteExportFailure(_ reason: String) {
        #if DEBUG
        lastExportFailure = reason
        #endif
    }

    #if DEBUG
    /// Why the last clip did not reach Photos. An export that quietly does nothing looks
    /// identical to one that was never asked for.
    @ObservationIgnored private(set) var lastExportFailure: String?

    var debugSummary: [(String, String)] {
        [
            ("enabled", isEnabled ? "yes" : "no"),
            ("state", "\(state)"),
            ("pending clips", "\(PendingClipStore.pending().count)"),
            ("last failure", lastExportFailure ?? "—"),
        ]
    }
    #endif
}

/// Receives the capture callbacks off the main actor and hands them back to the recorder.
///
/// A separate object because `AVCaptureMovieFileOutput` holds its delegate strongly for
/// the duration of a recording, and pointing that at the recorder would keep the whole
/// object graph — camera session included — alive past the game.
private final class RecordingDelegateProxy: NSObject, AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {

    private weak var recorder: CameraTurnRecorder?

    init(recorder: CameraTurnRecorder?) {
        self.recorder = recorder
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        Task { @MainActor [recorder] in
            await recorder?.handleFinishedClip(at: outputFileURL)
        }
    }
}
