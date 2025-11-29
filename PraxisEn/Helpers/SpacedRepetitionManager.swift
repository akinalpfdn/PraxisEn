import Foundation
import SwiftData
import OSLog

@MainActor
class SpacedRepetitionManager {
    private static let logger = Logger(subsystem: "PraxisEn", category: "SpacedRepetitionManager")

    /// Bir sonraki kelimeyi seç
    static func selectNextWord(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord]
    ) async -> VocabularyWord? {

        let stats = await getReviewStats(from: context)
        let shouldShowNew = shouldSelectNewWord(stats: stats)

        if shouldShowNew {
            return await selectNewWord(from: context, excluding: recentWords)
        } else {
            return await selectReviewWord(from: context, excluding: recentWords)
        }
    }

    /// Stats hesapla
    static func getReviewStats(from context: ModelContext) async -> ReviewStats {
        let descriptor = FetchDescriptor<VocabularyWord>()
        let allWords = (try? context.fetch(descriptor)) ?? []

        let known = allWords.filter { $0.isKnown }.count
        let inReview = allWords.filter { !$0.isKnown && $0.repetitions > 0 }.count

        return ReviewStats(
            totalWords: allWords.count,
            knownWords: known,
            wordsInReview: inReview
        )
    }

    /// Yeni mi yoksa tekrar mı gösterelim?
    private static func shouldSelectNewWord(stats: ReviewStats) -> Bool {
        let inReview = stats.wordsInReview

        if inReview <= 10 {
            return Double.random(in: 0...1) < 1.0  // 100% yeni (0-10 arası: 100-0)
        } else if inReview <= 20 {
            return Double.random(in: 0...1) < 0.6  // 70% yeni (11-20 arası: 70-30)
        } else if inReview <= 50 {
            return Double.random(in: 0...1) < 0.3  // 30% yeni (21-50 arası: 30-70)
        } else {
            return false  // 0% yeni (50+): sadece tekrar
        }
    }

    /// Yeni kelime seç
    private static func selectNewWord(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord]
    ) async -> VocabularyWord? {

        let descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { word in
                !word.isKnown && word.repetitions == 0
            }
        )

        let newWords = (try? context.fetch(descriptor)) ?? []
        let recentIDs = Set(recentWords.map { $0.word })
        let available = newWords.filter { !recentIDs.contains($0.word) }

        return available.randomElement()
    }

    /// Tekrar edilmesi gereken kelime seç
    private static func selectReviewWord(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord]
    ) async -> VocabularyWord? {

        let reviewWords = await getReviewWordsGroupedByRepetition(from: context)
        let recentIDs = Set(recentWords.map { $0.word })

        // Find the lowest repetition group that has available words
        for (_, words) in reviewWords.sorted(by: { $0.key < $1.key }) {
            let available = words.filter { !recentIDs.contains($0.word) }

            if !available.isEmpty {
                // Use time-based preference: sort by last reviewed date (oldest first)
                let sortedByTime = available.sorted { word1, word2 in
                    switch (word1.lastReviewedDate, word2.lastReviewedDate) {
                    case (nil, _): return true  // Never reviewed words come first
                    case (_, nil): return false
                    case (let date1?, let date2?): return date1 < date2
                    }
                }

                // Return the oldest word, but add some randomness
                if sortedByTime.count > 3 && Double.random(in: 0...1) < 0.7 {
                    // 70% chance to pick from the oldest 25%
                    let topQuartileCount = max(1, sortedByTime.count / 4)
                    return sortedByTime.prefix(topQuartileCount).randomElement()
                } else {
                    // 30% chance to pick randomly from all available
                    return available.randomElement()
                }
            }
        }

        return nil
    }

    /// Get review words grouped by repetition count
    private static func getReviewWordsGroupedByRepetition(
        from context: ModelContext
    ) async -> [Int: [VocabularyWord]] {

        var descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { word in
                !word.isKnown && word.repetitions > 0
            }
        )
        descriptor.fetchLimit = 200

        let reviewWords = (try? context.fetch(descriptor)) ?? []
        var grouped: [Int: [VocabularyWord]] = [:]

        for word in reviewWords {
            let repetition = word.repetitions
            if grouped[repetition] == nil {
                grouped[repetition] = []
            }
            grouped[repetition]?.append(word)
        }

        return grouped
    }

    /// Select next word based on user settings with ODR awareness
    static func selectNextWordWithSettings(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord],
        settings: UserSettings
    ) async -> VocabularyWord? {
        // Check if ODR content is available
        let isODRAvailable = await ODRManager.shared.checkFullContentAvailability()

        if !isODRAvailable {
            // ODR not available - prioritize seed words
            return await selectSeedWordWithSettings(from: context, excluding: recentWords, settings: settings)
        }

        // ODR available - use normal spaced repetition logic
        let stats = await getReviewStats(from: context)
        let shouldShowNew = shouldSelectNewWord(stats: stats)

        if shouldShowNew {
            return await selectNewWordWithSettings(from: context, excluding: recentWords, settings: settings)
        } else {
            return await selectReviewWordWithSettings(from: context, excluding: recentWords, settings: settings)
        }
    }

    /// Select seed word when ODR content is not available
    private static func selectSeedWordWithSettings(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord],
        settings: UserSettings
    ) async -> VocabularyWord? {
        let seedWordSet = ContentConstants.getSeedWordSet()
        let targetLevels = settings.getTargetLevels()
        let recentIDs = Set(recentWords.map { $0.word })

        logger.info("Selecting from seed words - ODR content not available")

        for level in targetLevels {
            var descriptor = FetchDescriptor<VocabularyWord>(
                predicate: #Predicate { word in
                    !word.isKnown &&
                    seedWordSet.contains(word.word) &&
                    word.repetitions == 0 &&
                    word.level == level
                }
            )

            let levelWords = (try? context.fetch(descriptor)) ?? []
            let available = levelWords.filter { !recentIDs.contains($0.word) }

            if !available.isEmpty {
                logger.info("Selected seed word from level: \(level)")
                return available.randomElement()
            }
        }

        // If no seed words available in target levels, try any seed word
        var descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { word in
                !word.isKnown &&
                seedWordSet.contains(word.word) &&
                word.repetitions == 0
            }
        )

        let allSeedWords = (try? context.fetch(descriptor)) ?? []
        let available = allSeedWords.filter { !recentIDs.contains($0.word) }

        return available.randomElement()
    }

    /// Select new word based on user settings
    private static func selectNewWordWithSettings(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord],
        settings: UserSettings
    ) async -> VocabularyWord? {

        let targetLevels = settings.getTargetLevels()
        let recentIDs = Set(recentWords.map { $0.word })

        for level in targetLevels {
            var descriptor = FetchDescriptor<VocabularyWord>(
                predicate: #Predicate { word in
                    !word.isKnown &&
                    word.repetitions == 0 &&
                    word.level == level
                }
            )
            let levelWords = (try? context.fetch(descriptor)) ?? []
            let available = levelWords.filter { !recentIDs.contains($0.word) }

            if !available.isEmpty {
                //print("📚 Selected new word from level: \(level)")
                return available.randomElement()
            }
        }

        return nil
    }

    /// Select review word based on user settings
    private static func selectReviewWordWithSettings(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord],
        settings: UserSettings
    ) async -> VocabularyWord? {

        let targetLevels = settings.getTargetLevels()
        let recentIDs = Set(recentWords.map { $0.word })

        // Get review words from target levels, grouped by repetition count
        var descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { word in
                !word.isKnown && word.repetitions > 0 && targetLevels.contains(word.level)
            }
        )

        let reviewWords = (try? context.fetch(descriptor)) ?? []

        // Group by repetition count (existing logic)
        var grouped: [Int: [VocabularyWord]] = [:]

        for word in reviewWords {
            let repetition = word.repetitions
            if grouped[repetition] == nil {
                grouped[repetition] = []
            }
            grouped[repetition]?.append(word)
        }

        // Find the lowest repetition group that has available words
        for (_, words) in grouped.sorted(by: { $0.key < $1.key }) {
            let available = words.filter { !recentIDs.contains($0.word) }

            if !available.isEmpty {
                // Use time-based preference: sort by last reviewed date (oldest first)
                let sortedByTime = available.sorted { word1, word2 in
                    switch (word1.lastReviewedDate, word2.lastReviewedDate) {
                    case (nil, _): return true  // Never reviewed words come first
                    case (_, nil): return false
                    case (let date1?, let date2?): return date1 < date2
                    }
                }

                // Return the oldest word, but add some randomness
                if sortedByTime.count > 3 && Double.random(in: 0...1) < 0.7 {
                    // 70% chance to pick from the oldest 25%
                    let topQuartileCount = max(1, sortedByTime.count / 4)
                    return sortedByTime.prefix(topQuartileCount).randomElement()
                } else {
                    // 30% chance to pick randomly from all available
                    return available.randomElement()
                }
            }
        }

        return nil
    }
}

struct ReviewStats {
    let totalWords: Int
    let knownWords: Int
    let wordsInReview: Int
}
