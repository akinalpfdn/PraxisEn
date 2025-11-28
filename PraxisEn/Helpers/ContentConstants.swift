import Foundation
import SwiftData

/// Constants and helper functions for content management with ODR support
enum ContentConstants {
    // MARK: - Seed Words Configuration

    /// Complete list of seed words available immediately without ODR download
    static let seedWords: [String] = [
        "hello", "yes", "no", "thank", "please", "water", "food",
        "house", "family", "friend", "work", "school", "time",
        "today", "tomorrow", "good", "bad", "help", "love", "money"
    ]

    // MARK: - Content Availability Helpers

    /// Check if a word is a seed word
    static func isSeedWord(_ word: String) -> Bool {
        return seedWords.contains(word.lowercased())
    }

    /// Get seed words as a Set for faster lookup
    static func getSeedWordSet() -> Set<String> {
        return Set(seedWords.map { $0.lowercased() })
    }

    // MARK: - Vocabulary Selection Logic

    /// Get seed-first vocabulary words from SwiftData
    /// Returns seed words first if ODR not complete, otherwise returns all vocabulary
    static func getVocabularyWords(
        modelContext: ModelContext,
        limit: Int = 50
    ) async throws -> [VocabularyWord] {
        let descriptor = FetchDescriptor<VocabularyWord>()
        let allWords = try modelContext.fetch(descriptor)

        // Check if ODR content is available
        let isODRAvailable = await ODRManager.shared.checkFullContentAvailability()

        if isODRAvailable {
            // Return random words from full vocabulary
            let shuffledWords = allWords.shuffled()
            return Array(shuffledWords.prefix(limit))
        } else {
            // Return only seed words
            let seedWordSet = getSeedWordSet()
            let seedVocabularyWords = allWords.filter { seedWordSet.contains($0.word.lowercased()) }

            // Shuffle seed words for variety, but ensure we have enough
            let shuffledSeedWords = seedVocabularyWords.shuffled()
            let additionalWords = allWords.shuffled().filter { !seedWordSet.contains($0.word.lowercased()) }

            // Combine seed words with additional words if needed to reach limit
            let result = shuffledSeedWords + additionalWords
            return Array(result.prefix(limit))
        }
    }

    /// Get next word for flashcard learning with ODR awareness
    /// Prioritizes seed words during initial app usage
    static func getNextFlashcardWord(
        modelContext: ModelContext,
        excludeWords: Set<String> = []
    ) async throws -> VocabularyWord? {
        let descriptor = FetchDescriptor<VocabularyWord>()
        let allWords = try modelContext.fetch(descriptor)

        let isODRAvailable = await ODRManager.shared.checkFullContentAvailability()
        let seedWordSet = getSeedWordSet()

        // Filter out excluded words
        let availableWords = allWords.filter { !excludeWords.contains($0.word.lowercased()) }

        if isODRAvailable {
            // ODR available - return any available word
            return availableWords.randomElement()
        } else {
            // ODR not available - prioritize seed words
            let seedWords = availableWords.filter { seedWordSet.contains($0.word.lowercased()) }

            // Return seed word if available
            if let seedWord = seedWords.randomElement() {
                return seedWord
            }

            // If all seed words have been used, return any word (rare case)
            return availableWords.randomElement()
        }
    }

    /// Check if content is available for a word (both media and examples)
    static func isContentFullyAvailable(for word: String) async -> Bool {
        let normalizedWord = word.lowercased()

        // Check if it's a seed word (always available)
        if await ODRManager.shared.isSeedWord(normalizedWord) {
            return true
        }

        // For non-seed words, check ODR status
        return await ODRManager.shared.checkFullContentAvailability()
    }
}