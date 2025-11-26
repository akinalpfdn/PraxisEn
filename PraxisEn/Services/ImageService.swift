import Foundation
import UIKit

/// Simple offline image service - prioritizes local images, creates placeholders as fallback
actor ImageService {
    // MARK: - Singleton

    static let shared = ImageService()

    private init() {}

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