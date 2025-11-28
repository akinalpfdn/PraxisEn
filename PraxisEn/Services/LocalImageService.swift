import UIKit
import SwiftUI
import OSLog

/// Service for loading local images from the app bundle
actor LocalImageService {
    // MARK: - Singleton

    static let shared = LocalImageService()

    private init() {
        self.logger = Logger(subsystem: "PraxisEn", category: "LocalImageService")
    }

    // MARK: - Private Properties

    private let logger: Logger

    // MARK: - Local Image Loading

    /// Load local image for a word from the bundle
    /// - Parameter word: The word to find an image for
    /// - Returns: UIImage if found, nil otherwise
    func loadLocalImage(for word: String) -> UIImage? {
        // Convert word to lowercase for consistent filename matching
        let normalizedWord = word.lowercased()

        // Try different filename patterns
        let possibleNames = [
            "\(normalizedWord).webp",
            "\(normalizedWord).jpg",
            "\(normalizedWord).jpeg",
            "\(normalizedWord).png"
        ]

        for filename in possibleNames {
            if let image = loadImageFromBundle(filename: filename) {
                //print("📷 [LocalImageService] Found local image: \(filename) for word: '\(word)'")
                return image
            }
        }

        //print("🔍 [LocalImageService] No local image found for word: '\(word)'")
        return nil
    }

    /// Load image from bundle with specified filename
    /// - Parameter filename: The filename to load
    /// - Returns: UIImage if found, nil otherwise
    private func loadImageFromBundle(filename: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: filename.replacingOccurrences(of: ".webp", with: ""), ofType: "webp") ??
              Bundle.main.path(forResource: filename.replacingOccurrences(of: ".jpg", with: ""), ofType: "jpg") ??
              Bundle.main.path(forResource: filename.replacingOccurrences(of: ".jpeg", with: ""), ofType: "jpeg") ??
              Bundle.main.path(forResource: filename.replacingOccurrences(of: ".png", with: ""), ofType: "png") else {
            return nil
        }

        return UIImage(contentsOfFile: path)
    }

    /// Check if local image exists for a word
    /// - Parameter word: The word to check
    /// - Returns: true if image exists, false otherwise
    func localImageExists(for word: String) -> Bool {
        return loadLocalImage(for: word) != nil
    }

    /// Load local image with fallback to placeholder
    /// - Parameters:
    ///   - word: The word to find an image for
    ///   - fallbackColor: Optional color for placeholder (defaults to word-based color)
    /// - Returns: UIImage (either local image or placeholder)
    func loadLocalImageWithFallback(for word: String, fallbackColor: UIColor? = nil) -> UIImage {
        if let localImage = loadLocalImage(for: word) {
            return localImage
        }

        // Return placeholder if no local image found
        return createPlaceholderImage(for: word, color: fallbackColor)
    }

    /// Create a placeholder image similar to ImageService's implementation
    /// - Parameters:
    ///   - word: The word to create placeholder for
    ///   - color: Optional color (defaults to word-based color)
    /// - Returns: Placeholder UIImage
    private func createPlaceholderImage(for word: String, color: UIColor? = nil) -> UIImage {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Use provided color or generate one based on word
            let backgroundColor = color ?? {
                let colorIndex = Int(word.first?.asciiValue ?? 0)
                let hue = CGFloat(colorIndex % 360) / 360.0
                return UIColor(hue: hue, saturation: 0.3, brightness: 0.95, alpha: 1.0)
            }()

            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw word in center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.gray
            ]

            let text = word as NSString
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

// MARK: - Convenience Extensions

extension LocalImageService {
    /// Get all available local image filenames (for debugging/testing)
    func getAllLocalImageNames() -> [String] {
        guard let resourcePath = Bundle.main.resourcePath else { return [] }

        let fileManager = FileManager.default
        var imageFiles: [String] = []

        do {
            let resourceFiles = try fileManager.contentsOfDirectory(atPath: resourcePath)

            // Filter for image files
            let imageExtensions = ["webp", "jpg", "jpeg", "png"]
            imageFiles = resourceFiles.filter { filename in
                let fileExtension = (filename as NSString).pathExtension.lowercased()
                return imageExtensions.contains(fileExtension)
            }

        } catch {
            //print("❌ [LocalImageService] Error listing resource files: \(error)")
        }

        return imageFiles.sorted()
    }

    /// Check how many words have local images available
    /// - Parameter words: Array of words to check
    /// - Returns: Tuple with count and percentage of words with local images
    func checkLocalImageCoverage(for words: [String]) -> (count: Int, percentage: Double) {
        let wordsWithImages = words.filter { localImageExists(for: $0) }
        let count = wordsWithImages.count
        let percentage = words.isEmpty ? 0.0 : (Double(count) / Double(words.count)) * 100.0

        return (count, percentage)
    }
}

// MARK: - ODR-Aware Image Loading

extension LocalImageService {
    /// Load image with ODR awareness - prioritizes bundled seed content
    /// - Parameter word: The word to find an image for
    /// - Returns: UIImage if found, nil otherwise
    func loadImageWithODR(for word: String) async -> UIImage? {
        // Normalize the word for consistent matching
        let normalizedWord = word.lowercased()

        // Check if this is a seed word first (immediate availability)
        if await ODRManager.shared.isSeedWord(normalizedWord) {
            logger.info("Loading seed image for word: '\(word)'")
            return loadLocalImage(for: word)
        }

        // If not a seed word, check if full content is available
        if await ODRManager.shared.checkFullContentAvailability() {
            logger.info("Loading ODR image for word: '\(word)'")
            return loadLocalImage(for: word)
        }

        // No content available yet
        logger.info("No image available for word: '\(word)' - content not downloaded")
        return nil
    }

    /// Load image with ODR awareness and fallback to placeholder
    /// - Parameter word: The word to find an image for
    /// - Returns: UIImage (either actual image or placeholder)
    func loadImageWithODRAndFallback(for word: String) async -> UIImage {
        if let image = await loadImageWithODR(for: word) {
            return image
        }

        // Return placeholder if no image available
        logger.info("Using placeholder for word: '\(word)'")
        return createPlaceholderImage(for: word)
    }

    /// Preload seed images to ensure immediate availability
    func preloadSeedImages() async {
        logger.info("Preloading seed images")

        let seedWords = await ODRManager.shared.getSeedWords()
        var loadedCount = 0

        for seedWord in seedWords {
            if let _ = loadLocalImage(for: seedWord) {
                loadedCount += 1
            }
        }

        logger.info("Preloaded \(loadedCount)/\(seedWords.count) seed images")
    }

    /// Check if image is available for a word considering ODR status
    /// - Parameter word: The word to check
    /// - Returns: true if image is available, false otherwise
    func isImageAvailableWithODR(for word: String) async -> Bool {
        let normalizedWord = word.lowercased()

        // Seed words are always available
        if await ODRManager.shared.isSeedWord(normalizedWord) {
            return localImageExists(for: word)
        }

        // Non-seed words are available only if full content is downloaded
        if await ODRManager.shared.checkFullContentAvailability() {
            return localImageExists(for: word)
        }

        return false
    }
}