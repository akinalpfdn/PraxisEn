import Foundation
import OSLog
internal import Combine

/// Manages On-Demand Resources (ODR) for PraxisEn app
/// Handles silent background download of full content while providing immediate access to seed content
@MainActor
class ODRManager: ObservableObject {
    static let shared = ODRManager()

    // MARK: - Published Properties

    @Published private var isDownloadComplete: Bool = false
    @Published private var isDownloading: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "PraxisEn", category: "ODR")
    private let fullContentTag = "all_media"

    // Seed words configuration - these are available immediately
    private let seedWords: Set<String> = [
        "hello", "yes", "no", "thank", "please", "water", "food",
        "house", "family", "friend", "work", "school", "time",
        "today", "tomorrow", "good", "bad", "help", "love", "money"
    ]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Initialize ODR system and check current download status
    func initializeODR() async {
        logger.info("Initializing ODR system")

        // Check if full content is already available
        isDownloadComplete = await checkFullContentAvailability()

        if isDownloadComplete {
            logger.info("Full content already available")
        } else {
            logger.info("Full content not downloaded yet, will use seed content")
        }
    }

    /// Request download of full content with all_media tag
    func requestFullContentDownload() async throws {
        guard !isDownloadComplete else {
            logger.info("Full content already available, skipping download")
            return
        }

        guard !isDownloading else {
            logger.info("Download already in progress")
            return
        }

        logger.info("Starting download of full content with tag: \(self.fullContentTag)")
        isDownloading = true

        do {
            // Note: This is a placeholder for actual ODR implementation
            // In a real implementation, you would use NSSBundleResourceRequest
            // For now, we'll simulate the download process

            // Simulate download time
            try await simulateDownload()

            isDownloadComplete = true
            isDownloading = false
            logger.info("Full content download completed successfully")

        } catch {
            isDownloading = false
            logger.error("Full content download failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Check if full content is available
    func checkFullContentAvailability() -> Bool {
        // Note: This is a placeholder for actual ODR availability check
        // In a real implementation, you would check NSSBundleResourceRequest.condition == .loaded
        // For now, we'll check if we can access ODR-tagged resources

        // Placeholder implementation - replace with actual ODR check
        return Bundle.main.path(forResource: "hello", ofType: "mp3") != nil
    }

    /// Check if a word is a seed word (available immediately)
    func isSeedWord(_ word: String) -> Bool {
        let normalizedWord = normalizeWord(word)
        return seedWords.contains(normalizedWord)
    }

    /// Get all seed words
    func getSeedWords() -> Set<String> {
        return seedWords
    }

    // MARK: - Private Methods

    /// Normalize word for comparison (remove punctuation, lowercase)
    private func normalizeWord(_ word: String) -> String {
        return word.lowercased()
            .replacingOccurrences(of: "[^a-zA-Z]", with: "", options: .regularExpression)
    }

    /// Simulate download process for testing
    private func simulateDownload() async throws {
        logger.info("Simulating full content download...")

        // Simulate download progress
        for i in 1...10 {
            logger.info("Download progress: \(i * 10)%")
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
    }
}

// MARK: - ODRManager Extensions

extension ODRManager {
    /// Get content availability status for UI decisions
    var contentStatus: ContentStatus {
        if isDownloadComplete {
            return .full
        } else if isDownloading {
            return .downloading
        } else {
            return .seedOnly
        }
    }
}

// MARK: - Supporting Types

enum ContentStatus {
    case seedOnly      // Only 20 seed words available
    case downloading   // Full content downloading in background
    case full          // All content available

    var description: String {
        switch self {
        case .seedOnly:
            return "Using seed content"
        case .downloading:
            return "Downloading additional content"
        case .full:
            return "All content available"
        }
    }
}
