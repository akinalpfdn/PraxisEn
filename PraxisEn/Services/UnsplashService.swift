import Foundation
import UIKit

/// Service for fetching images from Unsplash API
 actor UnsplashService {
    // MARK: - Singleton

    static let shared = UnsplashService()

    public init() {}

    // MARK: - Models

    struct SearchResponse: Codable {
        let results: [UnsplashPhoto]
    }

    struct UnsplashPhoto: Codable {
        let id: String
        let urls: PhotoURLs
        let description: String?
        let altDescription: String?

        enum CodingKeys: String, CodingKey {
            case id, urls, description
            case altDescription = "alt_description"
        }
    }

    struct PhotoURLs: Codable {
        let raw: String
        let full: String
        let regular: String
        let small: String
        let thumb: String
    }

    // MARK: - API Methods

    /// Fetch photo for a word
    func fetchPhoto(for word: String) async throws -> UIImage {
        //print("🔍 [UnsplashService] Starting fetch for word: '\(word)'")

        // Check cache first
        if let cachedImage = await ImageCache.shared.get(word) {
         //   print("📷 [UnsplashService] Using cached image for: \(word)")
           // print("📷 [UnsplashService] Cached image size: \(cachedImage.size), scale: \(cachedImage.scale)")
            return cachedImage
        }

        // Validate configuration
       // print("🔑 [UnsplashService] Checking API configuration...")
        guard Config.isUnsplashConfigured else {
            print("❌ [UnsplashService] API key not configured!")
            throw UnsplashError.apiKeyNotConfigured
        }
        //print("✅ [UnsplashService] API key is configured")

        // Build URL
        guard let url = buildSearchURL(for: word) else {
            print("❌ [UnsplashService] Failed to build URL")
            throw UnsplashError.invalidURL
        }
        //print("🌐 [UnsplashService] Search URL: \(url.absoluteString)")

        // Create request
        var request = URLRequest(url: url)
        request.addValue("Client-ID \(Config.unsplashAccessKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

       // print("📡 [UnsplashService] Sending API request...")

        // Fetch data
        let (data, response) = try await URLSession.shared.data(for: request)

       // print("📥 [UnsplashService] Received response, data size: \(data.count) bytes")

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [UnsplashService] Invalid response type")
            throw UnsplashError.invalidResponse
        }

       // print("📊 [UnsplashService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("❌ [UnsplashService] HTTP error code: \(httpResponse.statusCode)")
            throw UnsplashError.httpError(httpResponse.statusCode)
        }

        // Parse JSON
       // print("🔄 [UnsplashService] Parsing JSON response...")
        let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
       // print("📋 [UnsplashService] Found \(searchResponse.results.count) photos")

        guard let firstPhoto = searchResponse.results.first else {
            print("❌ [UnsplashService] No photos in results")
            throw UnsplashError.noPhotosFound
        }

      //  print("🖼️  [UnsplashService] Selected photo ID: \(firstPhoto.id)")
      //  print("🔗 [UnsplashService] Image URL: \(firstPhoto.urls.regular)")

        // Download image
        let imageURL = URL(string: firstPhoto.urls.regular)!
       // print("⬇️  [UnsplashService] Downloading image from URL...")
        let (imageData, _) = try await URLSession.shared.data(from: imageURL)
      //  print("📥 [UnsplashService] Downloaded image data: \(imageData.count) bytes")

        guard let image = UIImage(data: imageData) else {
            print("❌ [UnsplashService] Failed to create UIImage from data")
            throw UnsplashError.invalidImageData
        }

      //  print("✅ [UnsplashService] Successfully created UIImage: size=\(image.size), scale=\(image.scale)")

        // Cache the image
        await ImageCache.shared.set(image, forKey: word)
      //  print("💾 [UnsplashService] Cached image for: \(word)")

        return image
    }

    // MARK: - Helper Methods

    private func buildSearchURL(for word: String) -> URL? {
        var components = URLComponents(string: Config.unsplashBaseURL + Config.unsplashSearchEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "query", value: word),
            URLQueryItem(name: "per_page", value: String(Config.photosPerRequest)),
            URLQueryItem(name: "orientation", value: Config.photoOrientation)
        ]
        return components?.url
    }
}

// MARK: - Error Types

enum UnsplashError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noPhotosFound
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "Unsplash API key is not configured. Please add your key to Config.swift"
        case .invalidURL:
            return "Invalid URL for Unsplash API request"
        case .invalidResponse:
            return "Invalid response from Unsplash API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .noPhotosFound:
            return "No photos found for this word"
        case .invalidImageData:
            return "Could not create image from downloaded data"
        }
    }
}

// MARK: - Convenience Extensions

extension UnsplashService {
    /// Fetch photo with fallback to generic image on error
    func fetchPhotoSafely(for word: String) async -> UIImage {
        do {
            let image = try await fetchPhoto(for: word)
            print("✅ [fetchPhotoSafely] Successfully fetched image for '\(word)'")
            return image
        } catch {
            print("⚠️ [fetchPhotoSafely] Error fetching photo for '\(word)': \(error.localizedDescription)")
            print("⚠️ [fetchPhotoSafely] Error details: \(error)")
            // Return a colored placeholder
            let placeholder = createPlaceholderImage(for: word)
            print("🎨 [fetchPhotoSafely] Created placeholder image: size=\(placeholder.size), scale=\(placeholder.scale)")
            return placeholder
        }
    }

    /// Create a simple colored placeholder
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
