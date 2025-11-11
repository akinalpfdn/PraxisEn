import Foundation
import SwiftData

/// Represents a Turkish-English sentence pair from the Tatoeba corpus
@Model
final class SentencePair {
    // MARK: - Basic Information

    /// Unique identifier for the Turkish sentence in Tatoeba
    var turkishId: Int

    /// The Turkish sentence text
    var turkishText: String

    /// Unique identifier for the English sentence in Tatoeba
    var englishId: Int

    /// The English translation text
    var englishText: String

    // MARK: - Learning Features

    /// Whether the user has marked this sentence pair as a favorite
    var isFavorite: Bool

    /// Estimated difficulty level based on sentence complexity
    var difficultyLevel: String

    /// Date when the sentence pair was added
    var createdAt: Date

    // MARK: - Computed Properties

    /// Word count in the Turkish sentence
    var turkishWordCount: Int {
        turkishText.split(separator: " ").count
    }

    /// Word count in the English sentence
    var englishWordCount: Int {
        englishText.split(separator: " ").count
    }

    /// Returns true if this is a short sentence (≤5 words)
    var isShortSentence: Bool {
        turkishWordCount <= 5
    }

    /// Returns the difficulty tier (1-4)
    var difficultyTier: Int {
        switch difficultyLevel {
        case "A1": return 1
        case "A2": return 2
        case "B1": return 3
        case "B2": return 4
        default: return 1
        }
    }

    /// Character count for the Turkish text
    var turkishCharacterCount: Int {
        turkishText.count
    }

    /// Character count for the English text
    var englishCharacterCount: Int {
        englishText.count
    }

    // MARK: - Initialization

    init(
        turkishId: Int,
        turkishText: String,
        englishId: Int,
        englishText: String,
        isFavorite: Bool = false,
        difficultyLevel: String = "A1",
        createdAt: Date = Date()
    ) {
        self.turkishId = turkishId
        self.turkishText = turkishText
        self.englishId = englishId
        self.englishText = englishText
        self.isFavorite = isFavorite
        self.difficultyLevel = difficultyLevel
        self.createdAt = createdAt
    }

    // MARK: - Methods

    /// Toggles the favorite status
    func toggleFavorite() {
        isFavorite.toggle()
    }

    /// Checks if the sentence contains a specific word (case-insensitive)
    func contains(word: String, inLanguage language: Language = .both) -> Bool {
        let lowercasedWord = word.lowercased()

        switch language {
        case .turkish:
            return turkishText.lowercased().contains(lowercasedWord)
        case .english:
            return englishText.lowercased().contains(lowercasedWord)
        case .both:
            return turkishText.lowercased().contains(lowercasedWord) ||
                   englishText.lowercased().contains(lowercasedWord)
        }
    }

    /// Returns highlighted text with the search term marked
    func highlightedText(for searchTerm: String, in language: Language) -> String {
        let text = language == .turkish ? turkishText : englishText
        guard !searchTerm.isEmpty else { return text }

        // Simple highlighting - can be enhanced with NSAttributedString
        return text.replacingOccurrences(
            of: searchTerm,
            with: "**\(searchTerm)**",
            options: .caseInsensitive
        )
    }

    // MARK: - Supporting Types

    enum Language {
        case turkish
        case english
        case both
    }
}

// MARK: - Convenience Extensions

extension SentencePair {
    /// Returns a formatted pair string for debugging
    var debugDescription: String {
        """
        SentencePair(
            TR[\(turkishId)]: \(turkishText)
            EN[\(englishId)]: \(englishText)
            Level: \(difficultyLevel), Favorite: \(isFavorite)
        )
        """
    }

    /// Returns true if this is a beginner level sentence
    var isBeginnerLevel: Bool {
        difficultyLevel == "A1" || difficultyLevel == "A2"
    }

    /// Returns true if this is an intermediate level sentence
    var isIntermediateLevel: Bool {
        difficultyLevel == "B1" || difficultyLevel == "B2"
    }

    /// Returns a display-friendly difficulty label
    var difficultyLabel: String {
        switch difficultyLevel {
        case "A1": return "Beginner"
        case "A2": return "Elementary"
        case "B1": return "Intermediate"
        case "B2": return "Upper Intermediate"
        default: return "Unknown"
        }
    }
}

// MARK: - Sample Data

extension SentencePair {
    /// Creates a sample sentence pair for previews
    static var sample: SentencePair {
        SentencePair(
            turkishId: 349063,
            turkishText: "Bilmiyorum.",
            englishId: 349064,
            englishText: "I don't know.",
            isFavorite: false,
            difficultyLevel: "A1"
        )
    }

    /// Creates multiple sample sentence pairs for previews
    static var samples: [SentencePair] {
        [
            SentencePair(
                turkishId: 349063,
                turkishText: "Bilmiyorum.",
                englishId: 349064,
                englishText: "I don't know.",
                difficultyLevel: "A1"
            ),
            SentencePair(
                turkishId: 356666,
                turkishText: "Merhaba, nasılsın?",
                englishId: 138868,
                englishText: "Hello, how are you?",
                difficultyLevel: "A1"
            ),
            SentencePair(
                turkishId: 170564,
                turkishText: "Devenin belini kıran son saman çöpüdür.",
                englishId: 243919,
                englishText: "The last straw breaks the camel's back.",
                isFavorite: true,
                difficultyLevel: "B2"
            )
        ]
    }
}

// MARK: - Search and Filtering

extension SentencePair {
    /// Calculates a match score for a search query (higher is better)
    func matchScore(for query: String) -> Int {
        let lowercasedQuery = query.lowercased()
        var score = 0

        // Exact word match gets highest score
        if turkishText.lowercased() == lowercasedQuery || englishText.lowercased() == lowercasedQuery {
            score += 100
        }

        // Contains the full query
        if turkishText.lowercased().contains(lowercasedQuery) {
            score += 50
        }
        if englishText.lowercased().contains(lowercasedQuery) {
            score += 50
        }

        // Favorite sentences get bonus
        if isFavorite {
            score += 10
        }

        // Shorter sentences are often better examples
        if isShortSentence {
            score += 5
        }

        return score
    }
}
