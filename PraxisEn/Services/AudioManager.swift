import Foundation
import AVFoundation
import OSLog

/// Manages audio playback for word pronunciations
class AudioManager {
    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Properties

    private var audioPlayer: AVAudioPlayer?
    private let logger: Logger

    // MARK: - Initialization

    private init() {
        self.logger = Logger(subsystem: "PraxisEn", category: "AudioManager")
        // Configure audio session for playback
        configureAudioSession()
    }

    // MARK: - Public Methods

    /// Play audio for a given word
    /// - Parameter word: The word to pronounce (will be lowercased automatically)
    func play(word: String) {
        let fileName = word.lowercased()

        guard let audioPath = Bundle.main.path(forResource: fileName, ofType: "mp3") else {
            //print("⚠️ Audio file not found for word: \(word)")
            return
        }

        let audioURL = URL(fileURLWithPath: audioPath)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = 0.8  // Play at 80% speed
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            //print("🔊 Playing audio for: \(word) at 0.8x speed")
        } catch {
            //print("❌ Error playing audio for \(word): \(error.localizedDescription)")
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
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}

// MARK: - ODR-Aware Audio Loading

extension AudioManager {
    /// Play audio with ODR awareness - handles seed content and ODR downloads
    func playAudioWithODR(for word: String) {
        Task { @MainActor in
            await playAudioWithODRInternal(for: word)
        }
    }

    /// Internal method for ODR-aware audio playback
    private func playAudioWithODRInternal(for word: String) async {
        let fileName = word.lowercased()

        // Check if this is a seed word first (immediate availability)
        if await ODRManager.shared.isSeedWord(fileName) {
            logger.info("Playing seed audio for word: '\(word)'")
            playFromBundle(fileName: fileName, word: word)
            return
        }

        // If not a seed word, check if full content is available
        if await ODRManager.shared.checkFullContentAvailability() {
            logger.info("Playing ODR audio for word: '\(word)'")
            playFromBundle(fileName: fileName, word: word)
            return
        }

        // No audio available yet - silent fallback
        logger.info("No audio available for word: '\(word)' - content not downloaded")
    }

    /// Play audio from bundle (used for both seed and ODR content)
    private func playFromBundle(fileName: String, word: String) {
        guard let audioPath = Bundle.main.path(forResource: fileName, ofType: "mp3") else {
            logger.warning("Audio file not found for word: '\(word)'")
            return
        }

        let audioURL = URL(fileURLWithPath: audioPath)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = 0.8  // Play at 80% speed
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            logger.info("Playing audio for: '\(word)' at 0.8x speed")
        } catch {
            logger.error("Error playing audio for '\(word)': \(error.localizedDescription)")
        }
    }

    /// Preload seed audio files to ensure immediate availability
    func preloadSeedAudio() async {
        logger.info("Preloading seed audio files")

        let seedWords = await ODRManager.shared.getSeedWords()
        var loadedCount = 0

        for seedWord in seedWords {
            let fileName = seedWord.lowercased()
            if Bundle.main.path(forResource: fileName, ofType: "mp3") != nil {
                loadedCount += 1
            }
        }

        logger.info("Found \(loadedCount)/\(seedWords.count) seed audio files available")
    }

    /// Check if audio is available for a word considering ODR status
    /// - Parameter word: The word to check
    /// - Returns: true if audio is available, false otherwise
    func isAudioAvailableWithODR(for word: String) async -> Bool {
        let fileName = word.lowercased()

        // Seed words are always available
        if await ODRManager.shared.isSeedWord(fileName) {
            return Bundle.main.path(forResource: fileName, ofType: "mp3") != nil
        }

        // Non-seed words are available only if full content is downloaded
        if await ODRManager.shared.checkFullContentAvailability() {
            return Bundle.main.path(forResource: fileName, ofType: "mp3") != nil
        }

        return false
    }
}
