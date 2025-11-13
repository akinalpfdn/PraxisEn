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
        if searchText.isEmpty {
            return learnedWords
        }
        return learnedWords.filter {
            $0.word.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
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
                    }
                }
                .searchable(text: $searchText, prompt: "Search learned words")
            }
        }
        .background(Color.creamBackground.ignoresSafeArea())
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
