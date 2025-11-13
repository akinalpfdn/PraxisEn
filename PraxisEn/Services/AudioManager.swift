import Foundation
import AVFoundation

/// Manages audio playback for word pronunciations
class AudioManager {
    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Properties

    private var audioPlayer: AVAudioPlayer?

    // MARK: - Initialization

    private init() {
        // Configure audio session for playback
        configureAudioSession()
    }

    // MARK: - Public Methods

    /// Play audio for a given word
    /// - Parameter word: The word to pronounce (will be lowercased automatically)
    func play(word: String) {
        let fileName = word.lowercased()

        guard let audioPath = Bundle.main.path(forResource: fileName, ofType: "mp3") else {
            print("⚠️ Audio file not found for word: \(word)")
            return
        }

        let audioURL = URL(fileURLWithPath: audioPath)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = 0.8  // Play at 80% speed
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("🔊 Playing audio for: \(word) at 0.8x speed")
        } catch {
            print("❌ Error playing audio for \(word): \(error.localizedDescription)")
        }
    }

    /// Stop currently playing audio
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    // MARK: - Private Methods

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}
