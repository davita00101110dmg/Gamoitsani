//
//  CaptureSessionBox.swift
//  Gamoitsani2
//
import AVFoundation

/// Owns the capture session and every call into it, on one serial queue.
///
/// `AVCaptureSession`'s configuration and `startRunning()` are documented as blocking for
/// long enough that they must not run on the main thread, so the session cannot live on a
/// `@MainActor` type. Confining it here — with every member private and every entry point
/// hopping to `queue` — is what lets the recorder stay main-actor and still be provably
/// race-free under Swift 6.
///
/// `@unchecked Sendable` is the honest annotation: the invariant is enforced by this file
/// being the only place the session is touched, not by the type system.
final class CaptureSessionBox: @unchecked Sendable {

    private let queue = DispatchQueue(label: "gamoitsani.recording.session")
    private let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()
    private var isConfigured = false

    /// Configures on first use and starts running. `ready` fires on the queue once the
    /// session is live, which is the earliest moment a recording may begin.
    func start(_ ready: @escaping @Sendable () -> Void) {
        queue.async { [self] in
            configureIfNeeded()
            if !session.isRunning { session.startRunning() }
            let audio = AVAudioSession.sharedInstance()
            RecordingLog.note(
                "  session running=\(session.isRunning) audioCategory=\(audio.category.rawValue)"
            )
            ready()
        }
    }

    func beginRecording(
        to url: URL,
        maximumDuration: TimeInterval,
        delegate: any AVCaptureFileOutputRecordingDelegate & Sendable
    ) {
        queue.async { [self] in
            guard session.isRunning, !output.isRecording else {
                RecordingLog.note("  beginRecording skipped (running=\(session.isRunning) recording=\(output.isRecording))")
                return
            }
            output.maxRecordedDuration = CMTime(seconds: maximumDuration, preferredTimescale: 600)
            RecordingLog.note("  output.startRecording -> \(url.lastPathComponent)")
            output.startRecording(to: url, recordingDelegate: delegate)
        }
    }

    func stopRecording() {
        queue.async { [self] in
            guard output.isRecording else {
                RecordingLog.note("  stopRecording skipped (not recording)")
                return
            }
            RecordingLog.note("  output.stopRecording")
            output.stopRecording()
        }
    }

    /// Releases the camera. A party game is put down constantly, and holding the capture
    /// device between turns keeps the orange indicator lit for no reason.
    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func configureIfNeeded() {
        dispatchPrecondition(condition: .onQueue(queue))
        guard !isConfigured else { return }

        session.beginConfiguration()

        // 1080p, against v1's `.medium`. The faces are the subject now, so this is where
        // the bitrate belongs — v1 spent it on a screen recording of a word and a timer.
        session.sessionPreset = .hd1920x1080

        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let input = try? AVCaptureDeviceInput(device: camera),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if let microphone = AVCaptureDevice.default(for: .audio),
           let input = try? AVCaptureDeviceInput(device: microphone),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        // After committing: the connection does not exist until the output is added.
        if let connection = output.connection(with: .video) {
            // Portrait, because the phone is held that way and a clip that has to be
            // rotated to watch is a clip nobody shares.
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            // Not mirrored. A mirrored clip reverses any writing in the room, and unlike a
            // live preview nobody is using this to check their own hair.
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
        }

        RecordingLog.note(
            "  session configured inputs=\(session.inputs.count) outputs=\(session.outputs.count)"
        )
        isConfigured = true
    }
}
