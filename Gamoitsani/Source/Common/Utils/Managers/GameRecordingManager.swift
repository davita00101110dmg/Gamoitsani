//
//  GameRecordingManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/08/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import AVFoundation
import ReplayKit
import Photos
import UIKit
import Combine

protocol GameRecordingManagerDelegate: AnyObject {
    func recordingDidStart()
    func recordingDidStop(videoURL: URL?)
    func recordingDidFail(error: Error)
}

final class GameRecordingManager: NSObject, ObservableObject {

    static let shared = GameRecordingManager()

    weak var delegate: GameRecordingManagerDelegate?

    @Published private(set) var isRecording = false
    @Published var isRecordingEnabled = false
    @Published private(set) var cameraPreviewLayer: AVCaptureVideoPreviewLayer?

    private let screenRecorder = RPScreenRecorder.shared()
    private let cameraSession = AVCaptureSession()
    private let cameraQueue = DispatchQueue(label: "com.gamoitsani.cameraPreviewQueue")

    private var screenWriter: AVAssetWriter?
    private var screenWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var screenOutputURL: URL?

    private var recordingStartTime: CMTime?
    private var cameraSessionHasStarted = false
    private var isSessionStarted = false
    private var hasReceivedAudio = false

    private override init() {
        super.init()
        setupAudioSession()
    }

    func setRecordingEnabled(_ enabled: Bool) {
        isRecordingEnabled = enabled
    }

    func startGameRecording() {
        guard isRecordingEnabled && !isRecording else {
            log(.warning, "Cannot start recording - either disabled or already recording")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, !self.isRecording else {
                log(.warning, "Recording already in progress, skipping start")
                return
            }
            self.checkPermissionsAndStartRecording()
        }
    }

    func stopGameRecording() {
        guard isRecording else { return }
        
        log(.info, "Stopping game recording...")
        isRecording = false
        
        stopCameraPreview()
        
        screenRecorder.stopCapture { [weak self] error in
            if let error = error {
                log(.error, "Error stopping capture: \(error)")
                DispatchQueue.main.async {
                    self?.delegate?.recordingDidFail(error: error)
                }
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    self?.finalizeScreenRecording()
                }
            }
        }
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord,
                                        mode: .videoRecording,
                                        options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            log(.info, "Audio session configured for microphone recording")
        } catch {
            log(.error, "Failed to configure audio session: \(error)")
        }
    }

    private func checkPermissionsAndStartRecording() {
        var cameraGranted = false
        var micGranted = false
        let group = DispatchGroup()
        
        group.enter()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            cameraGranted = granted
            group.leave()
        }
        
        group.enter()
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            micGranted = granted
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            log(.info, "Permissions - Camera: \(cameraGranted), Microphone: \(micGranted)")
            
            if !micGranted {
                log(.error, "Microphone permission denied - cannot record audio")
                self?.delegate?.recordingDidFail(error: RecordingError.microphonePermissionDenied)
                return
            }
            
            self?.beginRecording()
        }
    }

    private func beginRecording() {
        guard screenRecorder.isAvailable else {
            log(.error, "Screen recording not available")
            delegate?.recordingDidFail(error: RecordingError.screenRecordingNotAvailable)
            return
        }

        isSessionStarted = false
        hasReceivedAudio = false
        recordingStartTime = nil
        
        guard setupScreenAssetWriter() else {
            delegate?.recordingDidFail(error: RecordingError.writingFailed)
            return
        }
        
        startCameraPreview()
        startScreenCapture()
    }

    private func setupScreenAssetWriter() -> Bool {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "gamoitsani_gameplay_\(Int(Date().timeIntervalSince1970)).mp4"
        screenOutputURL = documentsPath.appendingPathComponent(filename)

        guard let outputURL = screenOutputURL else { return false }
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        do {
            screenWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            
            let screenBounds = UIScreen.main.nativeBounds
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: screenBounds.width,
                AVVideoHeightKey: screenBounds.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 10_000_000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                    AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC
                ]
            ]
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 128000
            ]

            screenWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            screenWriterInput?.expectsMediaDataInRealTime = true
            
            guard let videoInput = screenWriterInput,
                  screenWriter?.canAdd(videoInput) == true else {
                log(.error, "Cannot add video input")
                return false
            }
            screenWriter?.add(videoInput)

            audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioWriterInput?.expectsMediaDataInRealTime = true
            
            guard let audioInput = audioWriterInput,
                  screenWriter?.canAdd(audioInput) == true else {
                log(.error, "Cannot add audio input")
                return false
            }
            screenWriter?.add(audioInput)
            
            guard screenWriter?.startWriting() == true else {
                log(.error, "Failed to start writing")
                return false
            }
            
            log(.info, "Asset writer setup successful")
            return true
            
        } catch {
            log(.error, "Failed to setup asset writer: \(error)")
            return false
        }
    }

    private func startScreenCapture() {
        screenRecorder.isMicrophoneEnabled = true
        
        log(.info, "Starting screen capture with microphone enabled...")
        
        screenRecorder.startCapture(handler: { [weak self] sampleBuffer, bufferType, error in
            guard let self = self else { return }
            
            if let error = error {
                log(.error, "Capture error: \(error)")
                return
            }
            
            self.processSampleBuffer(sampleBuffer, bufferType: bufferType)
            
        }, completionHandler: { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    log(.error, "Failed to start recording: \(error)")
                    self?.delegate?.recordingDidFail(error: error)
                } else {
                    log(.info, "Recording started successfully with microphone")
                    self?.isRecording = true
                    self?.delegate?.recordingDidStart()
                }
            }
        })
    }
    
    private func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, bufferType: RPSampleBufferType) {
        guard screenWriter?.status == .writing else {
            if screenWriter?.status == .failed {
                log(.error, "Writer failed: \(screenWriter?.error?.localizedDescription ?? "Unknown")")
            }
            return
        }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if !isSessionStarted {
            recordingStartTime = timestamp
            screenWriter?.startSession(atSourceTime: timestamp)
            isSessionStarted = true
            log(.info, "Started session at \(timestamp.seconds) seconds")
        }
        
        switch bufferType {
        case .video:
            if screenWriterInput?.isReadyForMoreMediaData == true {
                screenWriterInput?.append(sampleBuffer)
            }
            
        case .audioMic:
            if audioWriterInput?.isReadyForMoreMediaData == true {
                audioWriterInput?.append(sampleBuffer)
                
                if !hasReceivedAudio {
                    hasReceivedAudio = true
                    log(.info, "Receiving microphone audio for voice commentary")
                }
            }
            
        case .audioApp:
            break
            
        @unknown default:
            break
        }
    }

    private func finalizeScreenRecording() {
        guard let writer = screenWriter else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.recordingDidStop(videoURL: nil)
            }
            return
        }
        
        guard isSessionStarted else {
            log(.warning, "No data was recorded")
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.recordingDidStop(videoURL: nil)
            }
            return
        }
        
        log(.info, "Finalizing recording. Microphone audio received: \(hasReceivedAudio)")
        
        screenWriterInput?.markAsFinished()
        audioWriterInput?.markAsFinished()
        
        writer.finishWriting { [weak self] in
            guard let self = self else { return }
            
            if writer.status == .completed {
                log(.info, "Writing completed successfully")
                if let url = self.screenOutputURL {
                    self.verifyAndSaveVideo(url: url)
                }
            } else if writer.status == .failed {
                log(.error, "Writing failed: \(writer.error?.localizedDescription ?? "Unknown")")
                DispatchQueue.main.async {
                    self.delegate?.recordingDidFail(error: writer.error ?? RecordingError.writingFailed)
                }
            } else {
                log(.error, "Unexpected writer status: \(writer.status.rawValue)")
                DispatchQueue.main.async {
                    self.delegate?.recordingDidFail(error: RecordingError.writingFailed)
                }
            }
            
            self.cleanupAfterRecording()
        }
    }
    
    private func verifyAndSaveVideo(url: URL) {
        let asset = AVAsset(url: url)
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                
                let fileSize = await self.getFileSize(url: url)
                
                await MainActor.run {
                    log(.info, "Video verification - Video tracks: \(videoTracks.count), Audio tracks: \(audioTracks.count)")
                    log(.info, "File size: \(fileSize) MB")
                    
                    guard !videoTracks.isEmpty else {
                        log(.error, "No video tracks in recording")
                        self.delegate?.recordingDidFail(error: RecordingError.writingFailed)
                        return
                    }
                    
                    if audioTracks.isEmpty {
                        log(.warning, "No audio tracks in recording - microphone might not have captured audio")
                    }
                    
                    self.saveVideoToPhotoLibrary(url: url)
                }
            } catch {
                await MainActor.run {
                    log(.error, "Failed to verify video: \(error)")
                    self.delegate?.recordingDidFail(error: RecordingError.writingFailed)
                }
            }
        }
    }
    
    private func getFileSize(url: URL) async -> Double {
        return await Task {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = attributes[.size] as? NSNumber {
                    return fileSize.doubleValue / (1024 * 1024)
                }
            } catch {
                log(.error, "Failed to get file size: \(error)")
            }
            return 0
        }.value
    }
    
    private func cleanupAfterRecording() {
        screenWriter = nil
        screenWriterInput = nil
        audioWriterInput = nil
        recordingStartTime = nil
        isSessionStarted = false
        hasReceivedAudio = false
    }

    private func startCameraPreview() {
        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                         for: .video,
                                                         position: .front) else {
            log(.warning, "Front camera not available for preview")
            return
        }

        cameraQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.cameraSessionHasStarted {
                self.cameraSession.stopRunning()
            }
            
            do {
                self.cameraSession.beginConfiguration()
                
                self.cameraSession.inputs.forEach { self.cameraSession.removeInput($0) }
                
                self.cameraSession.sessionPreset = .medium
                
                let videoInput = try AVCaptureDeviceInput(device: cameraDevice)
                if self.cameraSession.canAddInput(videoInput) {
                    self.cameraSession.addInput(videoInput)
                }
                
                self.cameraSession.commitConfiguration()
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: self.cameraSession)
                previewLayer.videoGravity = .resizeAspectFill
                
                DispatchQueue.main.async {
                    self.cameraPreviewLayer = previewLayer
                    log(.info, "Camera preview layer updated")
                }
                
                self.cameraSession.startRunning()
                self.cameraSessionHasStarted = true
                
                log(.info, "Camera preview started")
                
            } catch {
                log(.error, "Failed to setup camera preview: \(error)")
            }
        }
    }

    private func stopCameraPreview() {
        cameraQueue.async { [weak self] in
            guard let self = self, self.cameraSessionHasStarted else { return }
            
            self.cameraSession.stopRunning()
            self.cameraSessionHasStarted = false
            
            DispatchQueue.main.async {
                self.cameraPreviewLayer = nil
            }
            
            log(.info, "Camera preview stopped")
        }
    }

    private func saveVideoToPhotoLibrary(url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.performSaveToPhotos(url: url)
                case .denied, .restricted:
                    log(.warning, "Photo library access denied")
                    self?.delegate?.recordingDidStop(videoURL: url)
                case .notDetermined:
                    log(.warning, "Photo library access not determined")
                    self?.delegate?.recordingDidStop(videoURL: url)
                @unknown default:
                    self?.delegate?.recordingDidStop(videoURL: url)
                }
            }
        }
    }

    private func performSaveToPhotos(url: URL) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.performSaveToPhotos(url: url)
            }
            return
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            log(.error, "Video file does not exist at path: \(url.path)")
            delegate?.recordingDidFail(error: RecordingError.savingFailed)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    log(.info, "Video saved to Photos successfully")
                    self?.delegate?.recordingDidStop(videoURL: url)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        try? FileManager.default.removeItem(at: url)
                    }
                } else {
                    log(.error, "Failed to save video: \(error?.localizedDescription ?? "Unknown")")
                    self?.delegate?.recordingDidFail(error: error ?? RecordingError.savingFailed)
                }
            }
        }
    }
}

enum RecordingError: LocalizedError {
    case writingFailed
    case savingFailed
    case screenRecordingNotAvailable
    case microphonePermissionDenied

    var errorDescription: String? {
        switch self {
        case .writingFailed:
            return "Failed to write video file"
        case .savingFailed:
            return "Failed to save video to photo library"
        case .screenRecordingNotAvailable:
            return "Screen recording is not available on this device"
        case .microphonePermissionDenied:
            return "Microphone permission is required to record voice commentary"
        }
    }
}
