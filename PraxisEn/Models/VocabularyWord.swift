import Foundation
import SwiftData

/// Represents a vocabulary word from the Oxford 3000 list with its metadata and learning progress
@Model
final class VocabularyWord {
    // MARK: - Basic Information

    /// The word itself (e.g., "abandon", "ability")
    @Attribute(.unique) var word: String

    /// CEFR level: A1, A2, B1, or B2
    var level: String

    /// English definition of the word
    var definition: String

    /// Turkish translation
    var turkishTranslation: String

    /// Example sentence showing usage
    var exampleSentence: String

    // MARK: - Linguistic Information

    /// Part of speech (noun, verb, adjective, etc.)
    var partOfSpeech: String

    /// Related word forms (plurals, verb conjugations, etc.)
    var relatedForms: String

    /// Comma-separated synonyms
    var synonyms: String

    /// Comma-separated antonyms
    var antonyms: String

    /// Common collocations and phrases
    var collocations: String

    // MARK: - Learning Progress

    /// Whether the user has marked this word as learned
    var isLearned: Bool

    /// Number of times the user has reviewed this word
    var reviewCount: Int

    /// Last date the word was reviewed
    var lastReviewedDate: Date?

    /// Date when the word was added to the database
    var createdAt: Date

    // MARK: - Spaced Repetition Fields

    /// User marked this word as "I know this"
    var isKnown: Bool = false

    /// When to show this word next for review
    var nextReviewDate: Date?

    /// Consecutive successful reviews
    var repetitions: Int = 0

    // MARK: - Computed Properties

    /// Returns synonyms as an array
    var synonymsList: [String] {
        synonyms
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.lowercased() != "none" }
    }

    /// Returns antonyms as an array
    var antonymsList: [String] {
        antonyms
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.lowercased() != "none" }
    }

    /// Returns collocations as an array
    var collocationsList: [String] {
        collocations
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.lowercased() != "none" }
    }

    /// Returns related forms as an array
    var relatedFormsList: [String] {
        relatedForms
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.lowercased() != "none" }
    }

    /// Returns true if the word has been reviewed at least once
    var hasBeenReviewed: Bool {
        reviewCount > 0
    }

    /// Returns the difficulty tier (1-4) based on CEFR level
    var difficultyTier: Int {
        switch level {
        case "A1": return 1
        case "A2": return 2
        case "B1": return 3
        case "B2": return 4
        default: return 4
        }
    }

    /// Returns true if word is due for review today
    var isDueForReview: Bool {
        guard let reviewDate = nextReviewDate else { return true }
        return reviewDate <= Date()
    }

    // MARK: - Initialization

    init(
        word: String,
        level: String,
        definition: String,
        turkishTranslation: String,
        exampleSentence: String,
        partOfSpeech: String,
        relatedForms: String,
        synonyms: String,
        antonyms: String,
        collocations: String,
        isLearned: Bool = false,
        reviewCount: Int = 0,
        lastReviewedDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.word = word
        self.level = level
        self.definition = definition
        self.turkishTranslation = turkishTranslation
        self.exampleSentence = exampleSentence
        self.partOfSpeech = partOfSpeech
        self.relatedForms = relatedForms
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.collocations = collocations
        self.isLearned = isLearned
        self.reviewCount = reviewCount
        self.lastReviewedDate = lastReviewedDate
        self.createdAt = createdAt
    }

    // MARK: - Methods

    /// Marks the word as reviewed and increments the review count
    func markAsReviewed() {
        reviewCount += 1
        lastReviewedDate = Date()
    }

    /// Toggles the learned status
    func toggleLearned() {
        isLearned.toggle()
    }

    /// Resets learning progress
    func resetProgress() {
        isLearned = false
        reviewCount = 0
        lastReviewedDate = nil
    }

    // MARK: - Spaced Repetition Methods

    /// Schedule next review based on repetition count
    func scheduleNextReview() {
        // Interval table: [1, 3, 7, 14, 30] days
        let intervals = [1, 3, 7, 14, 30]
        let dayInterval = repetitions < intervals.count
            ? intervals[repetitions]
            : 30

        nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: dayInterval,
            to: Date()
        )
        repetitions += 1
    }

    /// Mark word as known (exclude from rotation)
    func markAsKnown() {
        isKnown = true
        nextReviewDate = nil
    }

    /// Reset known status (return to unknown)
    func resetKnownStatus() {
        isKnown = false
        repetitions = 0
        nextReviewDate = Date()
    }
}

// MARK: - Convenience Extensions

extension VocabularyWord {
    /// Returns a formatted string for display (e.g., "abandon (B2) - verb")
    var displayTitle: String {
        "\(word) (\(level)) - \(partOfSpeech)"
    }

    /// Returns true if this is a beginner level word (A1 or A2)
    var isBeginnerLevel: Bool {
        level == "A1" || level == "A2"
    }

    /// Returns true if this is an intermediate level word (B1 or B2)
    var isIntermediateLevel: Bool {
        level == "B1" || level == "B2"
    }
}

// MARK: - Sample Data

extension VocabularyWord {
    /// Creates a sample vocabulary word for previews
    static var sample: VocabularyWord {
        VocabularyWord(
            word: "abandon",
            level: "B2",
            definition: "Cease to support or look after (someone); desert",
            turkishTranslation: "terk etmek",
            exampleSentence: "She decided to abandon her plans.",
            partOfSpeech: "verb",
            relatedForms: "abandons, abandoning, abandoned",
            synonyms: "desert, leave",
            antonyms: "support, keep",
            collocations: "abandon a plan, abandon a child",
            isLearned: false,
            reviewCount: 0
        )
    }
}
