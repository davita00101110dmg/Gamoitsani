//
//  SoundTests.swift
//  GamoitsaniDesignTests
//

import AVFoundation
import XCTest
@testable import GamoitsaniDesign

/// A missing or misnamed sound file fails silently at runtime — the game just goes quiet
/// on that event, which no one notices in review. These assertions are the only thing
/// standing between a typo in `scripts/generate-sounds.py` and a shipped silent buzzer.
final class SoundTests: XCTestCase {

    func testEveryCaseHasAFile() throws {
        for sound in Sound.allCases {
            XCTAssertNotNil(
                sound.url,
                "\(sound.rawValue).wav is missing — rerun scripts/generate-sounds.py"
            )
        }
    }

    func testEveryFileIsPlayable() throws {
        for sound in Sound.allCases {
            let url = try XCTUnwrap(sound.url)
            let player = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(player.duration, 0, "\(sound.rawValue) is empty")
            // Nothing here should be long enough to outlast the moment it marks.
            XCTAssertLessThan(player.duration, 1.5, "\(sound.rawValue) is too long")
        }
    }

    /// Relative loudness is a design decision, not an accident of synthesis. The tick fires
    /// three times per turn and the buzzer once, so a tick as loud as the buzzer is wrong.
    func testTickIsQuieterThanTheBuzzer() throws {
        XCTAssertLessThan(try peak(of: .tick), try peak(of: .timeUp))
        XCTAssertLessThan(try peak(of: .warning), try peak(of: .timeUp))
        XCTAssertLessThan(try peak(of: .skip), try peak(of: .superWord))
    }

    func testNothingClips() throws {
        for sound in Sound.allCases {
            XCTAssertLessThan(try peak(of: sound), 1.0, "\(sound.rawValue) clips")
        }
    }

    /// Peak amplitude, 0...1, read straight from the 16-bit samples.
    private func peak(of sound: Sound) throws -> Double {
        let url = try XCTUnwrap(sound.url)
        let data = try Data(contentsOf: url)
        // 44-byte canonical WAV header, then little-endian Int16 frames.
        let samples = data.dropFirst(44)
        var highest: Int16 = 0
        for index in stride(from: 0, to: samples.count - 1, by: 2) {
            let start = samples.startIndex + index
            let value = Int16(littleEndian: Int16(samples[start]) | (Int16(bitPattern: UInt16(samples[start + 1]) << 8)))
            highest = max(highest, value == Int16.min ? Int16.max : abs(value))
        }
        return Double(highest) / Double(Int16.max)
    }
}
