import UIKit
import SwiftUI

/// Simple in-memory image cache
actor ImageCache {
    // MARK: - Singleton

    static let shared = ImageCache()

    private init() {}

    // MARK: - Cache Storage

    private var cache: [String: UIImage] = [:]
    private let maxCacheSize = 50 // Maximum number of images to cache

    // MARK: - Cache Operations

    /// Get cached image for a key
    func get(_ key: String) -> UIImage? {
        return cache[key]
    }

    /// Store image in cache
    func set(_ image: UIImage, forKey key: String) {
        // Remove oldest if cache is full
        if cache.count >= maxCacheSize {
            let keyToRemove = cache.keys.first
            cache.removeValue(forKey: keyToRemove!)
        }

        cache[key] = image
    }

    /// Check if image exists in cache
    func contains(_ key: String) -> Bool {
        return cache[key] != nil
    }

    /// Clear entire cache
    func clear() {
        cache.removeAll()
    }

    /// Remove specific image
    func remove(_ key: String) {
        cache.removeValue(forKey: key)
    }

    /// Get cache statistics
    func getCacheInfo() -> (count: Int, maxSize: Int) {
        return (cache.count, maxCacheSize)
    }
}

// MARK: - SwiftUI Extension

extension Image {
    /// Create Image from cached UIImage or placeholder
    static func cached(for word: String) async -> Image? {
        if let uiImage = await ImageCache.shared.get(word) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}
