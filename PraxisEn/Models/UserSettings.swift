import Foundation
import SwiftData

/// Represents user preferences and learning progress
@Model
final class UserSettings {
    // MARK: - Basic Information

    /// Unique identifier for this settings record
    @Attribute(.unique) var id: UUID

    /// When settings were first created
    var createdAt: Date

    /// When settings were last updated
    var updatedAt: Date

    // MARK: - Learning Preferences

    /// Word selection mode for learning
    var wordSelectionMode: WordSelectionMode

    /// Current level in progressive mode
    var currentLevel: String

    /// Progress tracking for each level
    var isLevelCompleted: [String: Bool]

    /// Known words count per level for progress calculation
    var knownWordsCount: [String: Int]

    /// Total words count per level for progress calculation
    var totalWordsCount: [String: Int]

    // MARK: - Subscription Properties

    /// Current subscription tier
    var subscriptionTier: SubscriptionTier

    /// Whether subscription is currently active
    var subscriptionIsActive: Bool

    /// When subscription expires (nil for lifetime or non-subscribers)
    var subscriptionExpirationDate: Date?

    /// Date when subscription started
    var subscriptionStartDate: Date?

    /// How many daily swipes the user has used (free tier only)
    var dailySwipesUsed: Int

    /// Last date when daily swipe count was reset
    var lastSwipeResetDate: Date

    // MARK: - Initialization

    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()

        // Default: Progressive mode starting with A1
        self.wordSelectionMode = .progressiveByLevel
        self.currentLevel = "A1"

        // Initialize progress tracking
        self.isLevelCompleted = [
            "A1": false,
            "A2": false,
            "B1": false,
            "B2": false
        ]

        // Initialize word counts (will be populated when first loaded)
        self.knownWordsCount = [
            "A1": 0,
            "A2": 0,
            "B1": 0,
            "B2": 0
        ]

        self.totalWordsCount = [
            "A1": 0,
            "A2": 0,
            "B1": 0,
            "B2": 0
        ]

        // Initialize subscription properties (default to free tier)
        self.subscriptionTier = .free
        self.subscriptionIsActive = false
        self.subscriptionExpirationDate = nil
        self.subscriptionStartDate = nil
        self.dailySwipesUsed = 0
        self.lastSwipeResetDate = Date()
    }

    // MARK: - Computed Properties

    /// Returns true if all levels are completed
    var allLevelsCompleted: Bool {
        return isLevelCompleted.values.allSatisfy { $0 }
    }

    /// Returns the next level after current one, or nil if B2 is current
    var nextLevel: String? {
        switch currentLevel {
        case "A1": return "A2"
        case "A2": return "B1"
        case "B1": return "B2"
        case "B2": return nil
        default: return nil
        }
    }

    /// Returns progress percentage for current level
    var currentLevelProgress: Double {
        let known = knownWordsCount[currentLevel] ?? 0
        let total = totalWordsCount[currentLevel] ?? 1
        return Double(known) / Double(total)
    }

    /// Returns progress percentage for specific level
    func progress(for level: String) -> Double {
        let known = knownWordsCount[level] ?? 0
        let total = totalWordsCount[level] ?? 1
        return Double(known) / Double(total)
    }

    // MARK: - Methods

    /// Updates word counts for all levels
    func updateWordCounts(totalWords: [String: Int], knownWords: [String: Int]) {
        totalWordsCount = totalWords
        knownWordsCount = knownWords
        updateLevelCompletionStatus()
        updatedAt = Date()
    }

    /// Updates completion status for current level based on known words count
    func updateLevelCompletionStatus() {
        for level in ["A1", "A2", "B1", "B2"] {
            let known = knownWordsCount[level] ?? 0
            let total = totalWordsCount[level] ?? 0

            // Mark level as completed if all words are known
            let isCompleted = total > 0 && known >= total
            isLevelCompleted[level] = isCompleted

            // Auto-advance to next level in progressive mode
            if wordSelectionMode == .progressiveByLevel &&
               isCompleted &&
               currentLevel == level {
                advanceToNextLevel()
            }
        }
        updatedAt = Date()
    }

    /// Advances to next available level in progressive mode
    private func advanceToNextLevel() {
        guard let next = nextLevel else { return }

        if !isLevelCompleted[next]! {
            currentLevel = next
            ////print("🎯 Advanced to level: \(next)")
        }
    }

    /// Resets all progress
    func resetProgress() {
        currentLevel = "A1"
        isLevelCompleted = [
            "A1": false,
            "A2": false,
            "B1": false,
            "B2": false
        ]
        knownWordsCount = [
            "A1": 0,
            "A2": 0,
            "B1": 0,
            "B2": 0
        ]
        updatedAt = Date()
    }

    /// Gets target levels for word selection based on current mode and progress
    func getTargetLevels() -> [String] {
        // Get levels based on subscription status
        let unlockedLevels = SubscriptionManager.shared.getUnlockedLevels()

        switch wordSelectionMode {
        case .progressiveByLevel:
            // For progressive mode, check if current level is unlocked and completed
            if unlockedLevels.contains(currentLevel) {
                if isLevelCompleted[currentLevel]! {
                    // If current level is completed, find next available unlocked level
                    return findAvailableUnlockedLevels(from: unlockedLevels)
                } else {
                    return [currentLevel]
                }
            } else {
                // Current level is not unlocked, find the first unlocked level
                return unlockedLevels.isEmpty ? [] : [unlockedLevels.first!]
            }
        case .randomAllLevels:
            return unlockedLevels
        }
    }

    /// Finds available levels that aren't completed
    private func findAvailableLevels() -> [String] {
        let allLevels = ["A1", "A2", "B1", "B2"]
        return allLevels.filter { !isLevelCompleted[$0]! }
    }

    /// Finds available unlocked levels that aren't completed
    private func findAvailableUnlockedLevels(from unlockedLevels: [String]) -> [String] {
        return unlockedLevels.filter { !isLevelCompleted[$0]! }
    }
}

// MARK: - Word Selection Mode Enum

extension UserSettings {
    enum WordSelectionMode: String, CaseIterable, Codable {
        case progressiveByLevel = "progressive_by_level"
        case randomAllLevels = "random_all_levels"

        var displayName: String {
            switch self {
            case .progressiveByLevel:
                return "Progressive by Level"
            case .randomAllLevels:
                return "Random All Levels"
            }
        }

        var description: String {
            switch self {
            case .progressiveByLevel:
                return "Learn A1 → A2 → B1 → B2 in order"
            case .randomAllLevels:
                return "Random words from all difficulty levels"
            }
        }
    }
}

// MARK: - Subscription Tier Enum

extension UserSettings {
    enum SubscriptionTier: String, CaseIterable, Codable {
        case free = "free"
        case premium = "premium"

        var displayName: String {
            switch self {
            case .free:
                return "Free"
            case .premium:
                return "Premium"
            }
        }

        var description: String {
            switch self {
            case .free:
                return "Basic features with limitations"
            case .premium:
                return "Full access to all features"
            }
        }
    }
}
