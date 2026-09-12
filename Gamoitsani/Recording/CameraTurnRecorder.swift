//
//  CameraTurnRecorder.swift
//  Gamoitsani
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
    /// The file currently being written. Nothing may delete this.
    @ObservationIgnored private var currentClip: URL?
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

    /// The game the current turns belong to, so an abandoned evening is never spliced into
    /// the next one's reel.
    @ObservationIgnored private var gameID = UUID().uuidString

    /// Exports run one at a time, behind the game rather than in front of it.
    ///
    /// They used to hold the recorder in `.exporting`, and `startTurn` refused while it
    /// was — so every turn that began before the previous clip finished composing was
    /// silently not filmed. A 44s clip takes 16s to export and a turn transition takes
    /// three, so in practice only the first turn of a game was ever kept.
    @ObservationIgnored private var exportChain: Task<Void, Never>?

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
        // Only whether a camera is already running. An export in flight belongs to the
        // previous turn and must not cost this one.
        guard !isFilming else { return }

        // Cleared rather than inspected: a refusal on one turn — a full disk that has
        // since been emptied — must not disable filming for the rest of the game.
        state = .idle

        RecordingLog.note("startTurn team=\(teamName) round=\(Int(roundLength))s enabled=\(isEnabled)")

        if let refusal = policy.refusalToRecord(conditions, roundLength: roundLength) {
            RecordingLog.note("  refused: \(refusal)")
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
        currentClip = url

        let proxy = RecordingDelegateProxy(recorder: self)
        delegateProxy = proxy

        capture.start { [weak self, capture, policy] in
            RecordingLog.note("  session started, beginning recording")
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
                RecordingLog.note("  state = recording")
            }
        }
    }

    // These gate on `isFilming`, which is set synchronously, and never on `state`.
    //
    // `state` becomes `.recording` only once the capture session has finished starting,
    // which takes a moment — and the words on the table are announced the instant the
    // phase becomes `.playing`. Gating on the published state dropped those calls, and
    // because the bridge records what it has already announced, they were never retried.
    // A turn could end with an empty timeline, fail `isWorthKeeping`, and be discarded
    // with nothing reaching Photos.

    func wordShown(_ word: String) {
        guard isFilming else { return }
        timeline?.wordShown(word, at: elapsed)
    }

    func wordAnswered(_ word: String, outcome: RecordingOutcome) {
        guard isFilming else { return }
        timeline?.wordAnswered(word, outcome: outcome, at: elapsed)
    }

    func undoAnswer(_ word: String) {
        guard isFilming else { return }
        timeline?.undoAnswer(word)
    }

    func finishTurn() {
        guard isFilming else {
            RecordingLog.note("finishTurn ignored (not filming)")
            return
        }
        timeline?.finish(at: elapsed)
        RecordingLog.note(
            "finishTurn \(Int(timeline?.duration ?? 0))s words=\(timeline?.entries.count ?? 0)"
        )
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

        // The only sweep, and only at startup, when nothing is being written.
        PendingClipStore.removeOrphans(excluding: currentClip)

        // Turns left by a launch that ended before the podium, grouped so each game gets
        // its own reel. No end card: the scores went with the session that had them.
        for (game, pending) in Dictionary(grouping: PendingClipStore.pending(), by: \.gameID)
        where game != gameID && !game.isEmpty {
            // Counted on disk before the attempt, so footage that kills the process runs
            // out of chances instead of killing every future launch.
            guard let first = pending.first,
                  PendingClipStore.beginAttempt(for: first.clip) else { continue }
            enqueueReel(
                pending.map { HighlightReel.Source(clip: $0.clip, timeline: $0.timeline) },
                endCard: nil,
                gameID: game
            )
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

    /// Seconds into the clip. Zero until the camera has actually started, which is right:
    /// anything announced before the first frame was on screen from the beginning.
    private var elapsed: TimeInterval {
        clipStart.map { CACurrentMediaTime() - $0 } ?? 0
    }

    // MARK: - Finishing

    fileprivate func handleFinishedClip(at url: URL, error: (any Error)?) async {
        RecordingLog.note("delegate fired for \(url.lastPathComponent) error=\(error.map { "\($0)" } ?? "none")")
        let finished = timeline
        timeline = nil
        clipStart = nil
        delegateProxy = nil
        isFilming = false
        currentClip = nil
        // Releases the camera. A party game is put down constantly, and holding the device
        // between turns keeps the orange indicator lit for no reason.
        capture.stop()

        // A clip stopped by `maxRecordedDuration` arrives with an error and a perfectly
        // usable file, so the file's existence decides this, not the error.
        let exists = FileManager.default.fileExists(atPath: url.path)

        guard let finished else {
            // Cancelled: the player left mid-turn.
            PendingClipStore.discard(url)
            state = .idle
            return
        }
        guard exists else {
            let listing = (try? FileManager.default.contentsOfDirectory(
                atPath: PendingClipStore.directory.path
            )) ?? []
            RecordingLog.note("  no file at \(url.path)")
            RecordingLog.note("  directory holds: \(listing)")
            noteExportFailure("no file was written")
            PendingClipStore.discard(url)
            state = .idle
            return
        }
        guard policy.isWorthKeeping(finished) else {
            RecordingLog.note(
                "  discarded: \(finished.duration ?? 0)s, \(finished.entries.count) words"
            )
            noteExportFailure(
                "not kept: \(Int(finished.duration ?? 0))s, \(finished.entries.count) words"
            )
            PendingClipStore.discard(url)
            state = .idle
            return
        }

        // Kept, not exported. A turn clip is a working file until the game ends and the
        // whole evening is cut into one reel — six videos of one game is a folder nobody
        // opens. Written before anything else so being killed costs time, not footage.
        PendingClipStore.write(finished, gameID: gameID, for: url)
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        RecordingLog.note("  kept for the reel, \((size ?? 0) / 1024)KB")
        state = .idle
    }

    // MARK: - The reel

    /// The game reached the podium: cut everything filmed into one reel and save that.
    ///
    /// `endCard` is the share card the podium has already rendered, reused as the closing
    /// frame so the reel explains itself to someone who was not in the room.
    func finishGame(endCard: UIImage?) {
        let sources = PendingClipStore.pending()
            .filter { $0.gameID == gameID }
            .map { HighlightReel.Source(clip: $0.clip, timeline: $0.timeline) }

        // Whatever happens next, this game's clips belong to it and not to the next one.
        let finished = gameID
        gameID = UUID().uuidString

        guard !sources.isEmpty else { return }
        state = .exporting
        enqueueReel(sources, endCard: endCard, gameID: finished)
    }

    /// Chains reels so two never run at once — each is a full-resolution video
    /// composition, and one on top of another mid-game is how a round drops frames.
    private func enqueueReel(
        _ sources: [HighlightReel.Source],
        endCard: UIImage?,
        gameID: String
    ) {
        let previous = exportChain
        exportChain = Task { [weak self] in
            await previous?.value
            await self?.buildReel(sources, endCard: endCard)
        }
    }

    private func buildReel(_ sources: [HighlightReel.Source], endCard: UIImage?) async {
        // The identifier is checked before it is ended. `beginBackgroundTask` returns
        // `.invalid` when the app is not in a state to take one, and ending an invalid
        // identifier traps.
        let task = UIApplication.shared.beginBackgroundTask(withName: "gamoitsani.reel")
        defer {
            if task != .invalid { UIApplication.shared.endBackgroundTask(task) }
            state = .idle
        }

        RecordingLog.note("reel: cutting \(sources.count) turns")
        guard let reel = await HighlightReel.build(from: sources, endCard: endCard) else {
            // The footage stays. The next launch tries again rather than throwing away an
            // evening because the device was busy.
            noteExportFailure("reel could not be built")
            return
        }

        do {
            try await Self.saveToPhotos(reel)
            RecordingLog.note("  reel: SAVED TO PHOTOS")
        } catch {
            RecordingLog.note("  reel: PHOTOS FAILED: \(error)")
            noteExportFailure("photos: \(error.localizedDescription)")
            Self.delete(reel)
            return
        }

        Self.delete(reel)
        for source in sources { PendingClipStore.discard(source.clip) }
    }

    private nonisolated static func saveToPhotos(_ url: URL) async throws {
        // Copies rather than moves. `shouldMoveFile` saves a few megabytes of I/O and is
        // not worth handing Photos a move of a file the export has just written.
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .video, fileURL: url, options: nil)
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
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        RecordingLog.note("  delegate: started writing \(fileURL.lastPathComponent)")
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        Task { @MainActor [recorder] in
            await recorder?.handleFinishedClip(at: outputFileURL, error: error)
        }
    }
}
