//
//  Sound.swift
//  GamoitsaniDesign
//
import AVFoundation
import Observation

/// The audible half of the sensory vocabulary, alongside `Motion`.
///
/// Cases are the filenames. `scripts/generate-sounds.py` writes them.
public enum Sound: String, CaseIterable, Sendable, Hashable {
    case correct
    case skip
    case superWord
    case tick
    case warning
    case timeUp
    case gameOver

    /// Recognised formats, in the order they win. `.wav` is last because that is what
    /// `scripts/generate-sounds.py` writes: dropping `gameOver.m4a` into Resources replaces
    /// that sound outright, with no code change and nothing to delete.
    private static let formats = ["m4a", "mp3", "caf", "aiff", "wav"]

    /// The packaged audio. Lives here so callers — including tests in another module —
    /// never reach for this package's resource bundle themselves.
    public var url: URL? {
        Self.formats.lazy
            .compactMap { Bundle.module.url(forResource: rawValue, withExtension: $0) }
            .first
    }
}

/// Plays the set. One preloaded player per sound.
@MainActor
@Observable
public final class SoundPlayer {

    /// Persisted, because someone who turns sound off means it.
    public var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.key) }
    }

    private static let key = "sound.enabled"

    @ObservationIgnored private var players: [Sound: AVAudioPlayer] = [:]
    @ObservationIgnored private var sessionConfigured = false

    public init() {
        isEnabled = UserDefaults.standard.object(forKey: Self.key) as? Bool ?? true
    }

    /// Decodes every sound up front. Call once at launch: doing it on first play costs a
    /// hitch at exactly the wrong moment.
    public func prepare() async {
        let loaded = await Task.detached(priority: .utility) { () -> [Sound: Data] in
            var result: [Sound: Data] = [:]
            for sound in Sound.allCases {
                guard let url = sound.url, let data = try? Data(contentsOf: url)
                else { continue }
                result[sound] = data
            }
            return result
        }.value

        for (sound, data) in loaded {
            guard let player = try? AVAudioPlayer(data: data) else { continue }
            player.prepareToPlay()
            players[sound] = player
        }
    }

    public func play(_ sound: Sound) {
        guard isEnabled, let player = players[sound] else { return }
        configureSession()
        // Restart rather than overlap. Tapping correct twice quickly should sound like two
        // taps, not one smeared chord.
        player.currentTime = 0
        player.play()
    }

    /// `.ambient` so the silent switch still silences the app and someone else's music
    /// keeps playing. `.playback` would override both, which is wrong for a party game.
    private func configureSession() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
