import Foundation
import UIKit
import OSLog

/// Simple offline image service - prioritizes local images, creates placeholders as fallback
actor ImageService {
    // MARK: - Singleton

    static let shared = ImageService()

    private init() {
        self.logger = Logger(subsystem: "PraxisEn", category: "ImageService")
    }

    // MARK: - Private Properties

    private let logger: Logger

    // MARK: - Primary Image Loading Method

    /// Fetch photo for a word with local-only approach
    func fetchPhotoSafely(for word: String) async -> UIImage {
        // 1. Check cache first (fastest)
        if let cachedImage = await ImageCache.shared.get(word) {
            return cachedImage
        }

        // 2. Try local image (second fastest)
        if let localImage = await LocalImageService.shared.loadLocalImage(for: word) {
            await ImageCache.shared.set(localImage, forKey: word) 
            return localImage
        }
 
        let placeholder = createPlaceholderImage(for: word)
        await ImageCache.shared.set(placeholder, forKey: word)
        return placeholder
    }

    // MARK: - Placeholder Creation

    private func createPlaceholderImage(for word: String) -> UIImage {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Use word's first letter to generate consistent color
            let colorIndex = Int(word.first?.asciiValue ?? 0)
            let hue = CGFloat(colorIndex % 360) / 360.0

            UIColor(hue: hue, saturation: 0.3, brightness: 0.95, alpha: 1.0).setFill()
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

// MARK: - ODR-Aware Image Loading

extension ImageService {
    /// Fetch photo with ODR awareness - handles seed content and ODR downloads
    func fetchPhotoWithODR(for word: String) async -> UIImage {
        logger.info("Fetching ODR-aware photo for word: '\(word)'")

        // 1. Check cache first (fastest)
        if let cachedImage = await ImageCache.shared.get(word) {
            logger.debug("Found cached image for word: '\(word)'")
            return cachedImage
        }

        // 2. Use ODR-aware local image loading
        let image = await LocalImageService.shared.loadImageWithODRAndFallback(for: word)

        // 3. Cache the result
        await ImageCache.shared.set(image, forKey: word)

        logger.info("Loaded ODR-aware image for word: '\(word)'")
        return image
    }

    /// Preload seed images to ensure immediate availability
    func preloadSeedImages() async {
        logger.info("Preloading seed images via ImageService")
        await LocalImageService.shared.preloadSeedImages()
    }
}