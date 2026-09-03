//
//  CameraTurnRecorder.swift
//  Gamoitsani2
//
import AVFoundation
import Observation
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
        guard state == .idle else { return }

        if let refusal = policy.refusalToRecord(conditions, roundLength: roundLength) {
            // `.disabled` is the ordinary case — most games are not filmed — and is not
            // worth telling anyone about.
            state = refusal == .disabled ? .idle : .failed(refusal)
            return
        }

        timeline = RecordingTimeline(teamName: teamName)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("turn-\(UUID().uuidString).mov")

        capture.start { [weak self, capture, policy] in
            capture.beginRecording(
                to: url,
                maximumDuration: policy.maximumDuration,
                delegate: RecordingDelegateProxy(recorder: self)
            )
            Task { @MainActor in
                guard let self, self.state == .idle else { return }
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
        guard state == .recording else { return }
        timeline?.finish(at: elapsed ?? 0)
        state = .exporting
        capture.stopRecording()
    }

    /// The player left mid-turn. The footage exists but describes nothing, so it goes.
    func cancelTurn() {
        guard state == .recording else { return }
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
        // Releases the camera. A party game is put down constantly, and holding the device
        // between turns keeps the orange indicator lit for no reason.
        capture.stop()

        // A clip stopped by `maxRecordedDuration` arrives with an error and a perfectly
        // usable file, so the file's existence decides this, not the error.
        let exists = FileManager.default.fileExists(atPath: url.path)

        guard let finished, exists, policy.isWorthKeeping(finished) else {
            Self.delete(url)
            state = .idle
            return
        }

        let exported = await RecordingExporter.export(clip: url, timeline: finished)
        Self.delete(url)

        if let exported {
            await Self.saveToPhotos(exported)
            // Both copies go. v1 left every recording in Documents forever, invisible to
            // the player, on top of the copy it had already put in Photos.
            Self.delete(exported)
        }
        state = .idle
    }

    private static func saveToPhotos(_ url: URL) async {
        try? await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: url, options: nil)
        }
    }

    private static func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
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
