import Foundation

/// App configuration and API keys
struct Config {
    // MARK: - Unsplash API

    /// Unsplash Access Key (loaded from Secrets.plist)
    /// Get your key from: https://unsplash.com/developers
    static var unsplashAccessKey: String {
        return loadSecret(key: "UnsplashAccessKey")
    }

    // MARK: - API Endpoints

    static let unsplashBaseURL = "https://api.unsplash.com"
    static let unsplashSearchEndpoint = "/search/photos"

    // MARK: - Configuration

    /// Number of photos to fetch per request
    static let photosPerRequest = 1

    /// Default photo orientation
    static let photoOrientation = "landscape"

    /// Photo quality
    static let photoQuality = "regular" // thumb, small, regular, full, raw

    // MARK: - Validation

    /// Check if Unsplash API is configured
    static var isUnsplashConfigured: Bool {
        return !unsplashAccessKey.isEmpty &&
               unsplashAccessKey != "YOUR_UNSPLASH_ACCESS_KEY_HERE"
    }

    // MARK: - Private Helpers

    /// Load secret from Secrets.plist
    private static func loadSecret(key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secrets = NSDictionary(contentsOfFile: path),
              let value = secrets[key] as? String else {
            print("⚠️ Warning: Could not load '\(key)' from Secrets.plist")
            print("📝 Make sure Secrets.plist exists and contains '\(key)'")
            return ""
        }
        return value
    }
}
