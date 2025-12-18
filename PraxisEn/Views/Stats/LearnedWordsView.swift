import SwiftUI
import SwiftData

struct LearnedWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<VocabularyWord> { $0.isKnown },
        sort: \VocabularyWord.word
    ) private var learnedWords: [VocabularyWord]

    @State private var searchText = ""

    var filteredWords: [VocabularyWord] {
        let allLearnedWords = learnedWords

        // Apply subscription-based filtering for free users
        let limitedWords = applySubscriptionLimit(to: allLearnedWords)

        if searchText.isEmpty {
            return limitedWords
        }
        return limitedWords.filter {
            $0.word.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Apply subscription limit to learned words (50 most recent for free users, unlimited for premium)
    private func applySubscriptionLimit(to words: [VocabularyWord]) -> [VocabularyWord] {
        let maxWords = SubscriptionManager.shared.getMaxLearnedWordsToShow()

        if maxWords == Int.max {
            // Premium users - show all words, sorted alphabetically
            return words.sorted { $0.word < $1.word }
        } else {
            // Free users - show most recently learned words first
            return Array(
                words
                    .sorted { word1, word2 in
                        // Sort by most recently learned, then alphabetically
                        if let date1 = word1.learnedAt, let date2 = word2.learnedAt {
                            if date1 != date2 {
                                return date1 > date2  // Most recent first
                            }
                        } else if word1.learnedAt != nil {
                            return true  // Words with learnedAt come first
                        } else if word2.learnedAt != nil {
                            return false
                        }
                        // Fallback to alphabetical if no learnedAt or same date
                        return word1.word < word2.word
                    }
                    .prefix(maxWords)
            )
        }
    }

    var body: some View {
        ZStack {
            // Ensure cream background fills the entire screen
            Color.creamBackground
                .ignoresSafeArea()

            if learnedWords.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredWords, id: \.word) { word in
                        NavigationLink(value: NavigationDestination.learnedFlashcard(wordID: word.word, allLearnedWordIDs: learnedWords.map { $0.word })) {
                            WordRow(word: word) {
                                resetWord(word)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.white)
                        .listRowSeparator(.hidden)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search learned words")
            }
        }
        .navigationTitle("Learned Words")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)

            Text("No learned words yet")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.textSecondary)

            Text("Swipe up on a card to mark it as learned")
                .font(.system(size: 14))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func resetWord(_ word: VocabularyWord) {
        word.resetKnownStatus()
        try? modelContext.save()
    }
}

struct WordRow: View {
    let word: VocabularyWord
    let onReset: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.word.capitalized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(word.turkishTranslation)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16))
                    .foregroundColor(.accentOrange)
                    .padding(8)
                    .background(Circle().fill(Color.accentOrange.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
