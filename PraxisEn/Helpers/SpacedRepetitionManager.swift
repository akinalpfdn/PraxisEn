import Foundation
import SwiftData

@MainActor
class SpacedRepetitionManager {

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
        let dueForReview = allWords.filter { !$0.isKnown && $0.isDueForReview }.count

        return ReviewStats(
            totalWords: allWords.count,
            knownWords: known,
            wordsInReview: inReview,
            wordsDueForReview: dueForReview
        )
    }

    /// Yeni mi yoksa tekrar mı gösterelim?
    private static func shouldSelectNewWord(stats: ReviewStats) -> Bool {
        let inReview = stats.wordsInReview

        if inReview < 10 {
            return Double.random(in: 0...1) < 0.7  // %70 yeni
        } else if inReview < 15 {
            return Double.random(in: 0...1) < 0.3  // %30 yeni
        } else {
            return false  // %0 yeni (sadece tekrar)
        }
    }

    /// Yeni kelime seç
    private static func selectNewWord(
        from context: ModelContext,
        excluding recentWords: [VocabularyWord]
    ) async -> VocabularyWord? {

        var descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { word in
                !word.isKnown && word.repetitions == 0
            }
        )
        descriptor.fetchLimit = 100

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

        var descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { word in
                !word.isKnown && word.repetitions > 0
            },
            sortBy: [SortDescriptor(\.nextReviewDate)]
        )
        descriptor.fetchLimit = 50

        let reviewWords = (try? context.fetch(descriptor)) ?? []
        let recentIDs = Set(recentWords.map { $0.word })
        let available = reviewWords.filter { !recentIDs.contains($0.word) }

        // Vadesi geçmiş olanları önceliklendir
        let overdue = available.filter { $0.isDueForReview }
        return overdue.first ?? available.randomElement()
    }
}

struct ReviewStats {
    let totalWords: Int
    let knownWords: Int
    let wordsInReview: Int
    let wordsDueForReview: Int
}
