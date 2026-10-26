import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class AudioManager {
    static let shared = AudioManager()

    var isSoundEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEffectsEnabled, forKey: Self.soundEffectsKey)
        }
    }

    var isBackgroundMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBackgroundMusicEnabled, forKey: Self.backgroundMusicKey)
            if isBackgroundMusicEnabled {
                startBackgroundMusic()
            } else {
                backgroundMusicPlayer?.stop()
                backgroundMusicPlayer = nil
            }
        }
    }

    @ObservationIgnored private var soundEffectPlayer: AVAudioPlayer?
    @ObservationIgnored private var backgroundMusicPlayer: AVAudioPlayer?

    private static let soundEffectsKey = "soundEffectsEnabled"
    private static let backgroundMusicKey = "backgroundMusicEnabled"

    private init() {
        let defaults = UserDefaults.standard
        isSoundEffectsEnabled = defaults.object(forKey: Self.soundEffectsKey) as? Bool ?? true
        isBackgroundMusicEnabled = defaults.bool(forKey: Self.backgroundMusicKey)
        if isBackgroundMusicEnabled {
            startBackgroundMusic()
        }
    }

    func play(_ sound: SoundEffect) {
        guard isSoundEffectsEnabled else { return }

        let (frequencies, duration): ([Double], Double) = switch sound {
        case .cardFlip: ([660], 0.07)
        case .match: ([660, 880], 0.18)
        case .noMatch: ([220], 0.14)
        case .win: ([523, 659, 784], 0.4)
        case .lose: ([330, 220], 0.35)
        }

        do {
            let player = try AVAudioPlayer(data: Self.makeTone(frequencies: frequencies, duration: duration))
            player.prepareToPlay()
            player.play()
            soundEffectPlayer = player
        } catch {
            print("Failed to play sound effect: \(error)")
        }
    }

    private func startBackgroundMusic() {
        guard backgroundMusicPlayer?.isPlaying != true else { return }

        do {
            let player = try AVAudioPlayer(
                data: Self.makeTone(frequencies: [196, 246.94, 293.66], duration: 3)
            )
            player.numberOfLoops = -1
            player.volume = 0.06
            player.prepareToPlay()
            player.play()
            backgroundMusicPlayer = player
        } catch {
            print("Failed to start background music: \(error)")
        }
    }

    private static func makeTone(frequencies: [Double], duration: Double) -> Data {
        let sampleRate: UInt32 = 22_050
        let sampleCount = Int(Double(sampleRate) * duration)
        let byteCount = UInt32(sampleCount * MemoryLayout<Int16>.size)
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        data.appendLittleEndian(36 + byteCount)
        data.append(contentsOf: "WAVEfmt ".utf8)
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(sampleRate)
        data.appendLittleEndian(sampleRate * UInt32(MemoryLayout<Int16>.size))
        data.appendLittleEndian(UInt16(MemoryLayout<Int16>.size))
        data.appendLittleEndian(UInt16(16))
        data.append(contentsOf: "data".utf8)
        data.appendLittleEndian(byteCount)

        for sampleIndex in 0..<sampleCount {
            let time = Double(sampleIndex) / Double(sampleRate)
            let fadeIn = min(1, time / 0.015)
            let fadeOut = min(1, (duration - time) / 0.04)
            let amplitude = min(fadeIn, fadeOut) * 0.18 / Double(frequencies.count)
            let value = frequencies.reduce(0.0) { partial, frequency in
                partial + sin(2 * .pi * frequency * time)
            }
            let sample = Int16(max(-1, min(1, value * amplitude)) * Double(Int16.max))
            data.appendLittleEndian(sample)
        }

        return data
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { bytes in
            append(contentsOf: bytes)
        }
    }
}
