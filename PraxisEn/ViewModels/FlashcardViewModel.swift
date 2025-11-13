import Foundation
import SwiftUI
import SwiftData
internal import Combine

@MainActor
class FlashcardViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current word being displayed
    @Published var currentWord: VocabularyWord?

    /// Is card flipped (showing back side)
    @Published var isFlipped: Bool = false

    /// Example sentences for current word (max 3)
    @Published var exampleSentences: [SentencePair] = []

    /// Photo for current word
    @Published var currentPhoto: UIImage?

    /// Loading state
    @Published var isLoadingPhoto: Bool = false

    /// Word history (for back navigation)
    private var wordHistory: [VocabularyWord] = []

    /// Current index in history
    private var currentIndex: Int = -1

    /// Next word preview
    @Published var nextWordPreview: VocabularyWord?

    /// Previous word preview
    @Published var previousWordPreview: VocabularyWord?

    /// Next word preview photo
    @Published var nextWordPreviewPhoto: UIImage?

    /// Previous word preview photo
    @Published var previousWordPreviewPhoto: UIImage?

    /// Known words count (for progress bar)
    @Published var knownWordsCount: Int = 0

    /// Total words count (for progress bar)
    @Published var totalWordsCount: Int = 3000

    /// Show progress animation (+1 popup)
    @Published var showProgressAnimation: Bool = false

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Word Management

    /// Load next word using spaced repetition algorithm
    func loadNextWord() async {
        guard let word = await SpacedRepetitionManager.selectNextWord(
            from: modelContext,
            excluding: Array(wordHistory.suffix(10))
        ) else {
            // Fallback: use old random method
            await loadRandomWord()
            return
        }

        currentWord = word
        addToHistory(word)

        isFlipped = false
        await loadPhotoForCurrentWord()
        await loadExamplesForCurrentWord()
        await updatePreviews()
        await updateKnownWordsCount()
    }

    /// Load a random word
    func loadRandomWord() async {
        do {
            // Fetch random word from database
            let descriptor = FetchDescriptor<VocabularyWord>(
                sortBy: [SortDescriptor(\.word)]
            )

            let allWords = try modelContext.fetch(descriptor)

            guard !allWords.isEmpty else {
                print("⚠️ No words found in database")
                return
            }

            // Get random word
            let randomWord = allWords.randomElement()!

            // Update current word
            currentWord = randomWord

            // Add to history
            addToHistory(randomWord)

            // Reset flip state
            isFlipped = false

            // Load photo and examples
            await loadPhotoForCurrentWord()
            await loadExamplesForCurrentWord()

            // Update previews
            await updatePreviews()

        } catch {
            print("❌ Error loading random word: \(error)")
        }
    }

    /// Go to next word (swipe right)
    func nextWord() async {
        // Schedule current word for review
        if let word = currentWord, !word.isKnown {
            word.scheduleNextReview()
            try? modelContext.save()
        }

        // Check if we can move forward in history
        if currentIndex < wordHistory.count - 1 {
            currentIndex += 1
            currentWord = wordHistory[currentIndex]
        } else {
            // Use the preview word if available, otherwise load next word
            if let preview = nextWordPreview {
                currentWord = preview
                addToHistory(preview)
            } else {
                await loadNextWord()
                return
            }
        }

        // Use preview photo immediately for smooth transition
        currentPhoto = nextWordPreviewPhoto

        // Reset flip and load content
        isFlipped = false
        await loadPhotoForCurrentWord()
        await loadExamplesForCurrentWord()

        // Update previews
        await updatePreviews()
    }

    /// Go to previous word (swipe left)
    func previousWord() async {
        // Schedule current word for review
        if let word = currentWord, !word.isKnown {
            word.scheduleNextReview()
            try? modelContext.save()
        }

        guard currentIndex > 0 else {
            print("ℹ️ No previous word")
            return
        }

        currentIndex -= 1
        currentWord = wordHistory[currentIndex]

        // Use preview photo immediately for smooth transition
        currentPhoto = previousWordPreviewPhoto

        // Reset flip and load content
        isFlipped = false
        await loadPhotoForCurrentWord()
        await loadExamplesForCurrentWord()

        // Update previews
        await updatePreviews()
    }

    // MARK: - Card Flip

    /// Toggle card flip state
    func toggleFlip() {
        withAnimation(AppAnimation.flip) {
            isFlipped.toggle()
        }
    }

    // MARK: - Content Loading

    /// Load photo for current word
    private func loadPhotoForCurrentWord() async {
        guard let word = currentWord else { return }

        // Don't show loading spinner - just silently load in background
        // Check if already cached first
        if let cachedImage = await ImageCache.shared.get(word.word) {
            currentPhoto = cachedImage
            print("📸 Using cached image for: \(word.word)")
            return
        }

        // Load in background without showing loading state
        print("📸 Starting background photo fetch for: \(word.word)")

        // Fetch photo from Unsplash
        let photo = await UnsplashService.shared.fetchPhotoSafely(for: word.word)

        // Update state silently
        currentPhoto = photo
        print("📸 Photo loaded and set: \(word.word)")
    }

    /// Load example sentences for current word (max 10)
    private func loadExamplesForCurrentWord() async {
        guard let word = currentWord else { return }

        do {
            print("🔍 Searching sentences for word: '\(word.word)'")

            // Search for sentences containing the word
            let sentences = try await DatabaseManager.shared.searchSentences(
                containing: word.word,
                limit: 10
            )

            print("📥 SQL returned \(sentences.count) sentences")

            // Filter and limit to best examples
            let filtered = sentences
                .filter { $0.englishText.lowercased().contains(word.word.lowercased()) }
                .sorted { $0.difficultyTier < $1.difficultyTier } // Easier first
                .prefix(10)

            exampleSentences = Array(filtered)

            print("📖 Found \(exampleSentences.count) example sentences for '\(word.word)'")

        } catch {
            print("❌ Error loading examples: \(error)")
            exampleSentences = []
        }
    }

    // MARK: - History Management

    private func addToHistory(_ word: VocabularyWord) {
        // Remove any words after current index
        if currentIndex < wordHistory.count - 1 {
            wordHistory.removeLast(wordHistory.count - currentIndex - 1)
        }

        // Add new word
        wordHistory.append(word)
        currentIndex = wordHistory.count - 1

        // Limit history size
        if wordHistory.count > 50 {
            wordHistory.removeFirst()
            currentIndex -= 1
        }
    }

    // MARK: - Learning Progress

    /// Mark current word as learned
    func markAsLearned() {
        guard let word = currentWord else { return }

        word.toggleLearned()

        do {
            try modelContext.save()
            print("✅ Word marked as learned: \(word.word)")
        } catch {
            print("❌ Error saving learned state: \(error)")
        }
    }

    /// Mark current word as reviewed
    func markAsReviewed() {
        guard let word = currentWord else { return }

        word.markAsReviewed()

        do {
            try modelContext.save()
            print("✅ Word reviewed: \(word.word) (count: \(word.reviewCount))")
        } catch {
            print("❌ Error saving review: \(error)")
        }
    }

    /// Mark current word as known (swipe up gesture)
    func markCurrentWordAsKnown() async {
        guard let word = currentWord else { return }

        // Mark as known
        word.markAsKnown()
        try? modelContext.save()

        await updateKnownWordsCount()

        // Show success animation (non-blocking, runs in parallel with word transition)
        showProgressAnimation = true
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000) // 1.4 sec (2x duration)
            await MainActor.run {
                showProgressAnimation = false
            }
        }

        // No need to sleep here - DispatchQueue.main.asyncAfter already waited 0.3s!
        // Go to next word - EXACTLY like swipe left!
        // (scheduleNextReview will be skipped automatically since word.isKnown = true)
        await nextWord()
    }

    /// Update known words count for progress bar
    func updateKnownWordsCount() async {
        let descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { $0.isKnown }
        )
        let knownWords = (try? modelContext.fetch(descriptor)) ?? []
        knownWordsCount = knownWords.count
    }

    // MARK: - Helper Methods

    /// Get formatted word display text
    var wordDisplayText: String {
        currentWord?.word.capitalized ?? ""
    }

    /// Get formatted translation text
    var translationText: String {
        currentWord?.turkishTranslation ?? ""
    }

    /// Get current word level with emoji
    var levelDisplay: String {
        guard let word = currentWord else { return "" }

        let emoji: String
        switch word.level {
        case "A1": emoji = "🟢"
        case "A2": emoji = "🔵"
        case "B1": emoji = "🟠"
        case "B2": emoji = "🔴"
        default: emoji = "⚪️"
        }

        return "\(emoji) \(word.level)"
    }

    /// Check if we can go back
    var canGoBack: Bool {
        currentIndex > 0
    }

    /// Reset the flashcard session
    func reset() {
        currentWord = nil
        isFlipped = false
        exampleSentences = []
        currentPhoto = nil
        wordHistory.removeAll()
        currentIndex = -1
        nextWordPreview = nil
        previousWordPreview = nil
        nextWordPreviewPhoto = nil
        previousWordPreviewPhoto = nil
    }

    // MARK: - Audio Playback

    /// Play pronunciation audio for current word
    func playWordAudio() {
        guard let word = currentWord else { return }
        AudioManager.shared.play(word: word.word)
    }

    // MARK: - Preview Management

    /// Update next and previous word previews
    private func updatePreviews() async {
        // Set previous word preview
        if currentIndex > 0 {
            previousWordPreview = wordHistory[currentIndex - 1]
        } else {
            previousWordPreview = nil
            previousWordPreviewPhoto = nil
        }

        // Set next word preview
        if currentIndex < wordHistory.count - 1 {
            nextWordPreview = wordHistory[currentIndex + 1]
        } else {
            // Load a random word as preview
            do {
                let descriptor = FetchDescriptor<VocabularyWord>(
                    sortBy: [SortDescriptor(\.word)]
                )
                let allWords = try modelContext.fetch(descriptor)
                nextWordPreview = allWords.randomElement()
            } catch {
                print("❌ Error loading next word preview: \(error)")
                nextWordPreview = nil
            }
        }

        // Load photos in parallel
        await withTaskGroup(of: Void.self) { group in
            // Load previous photo
            if let prev = previousWordPreview {
                group.addTask {
                    let photo = await UnsplashService.shared.fetchPhotoSafely(for: prev.word)
                    await MainActor.run {
                        self.previousWordPreviewPhoto = photo
                    }
                }
            }

            // Load next photo
            if let next = nextWordPreview {
                group.addTask {
                    let photo = await UnsplashService.shared.fetchPhotoSafely(for: next.word)
                    await MainActor.run {
                        self.nextWordPreviewPhoto = photo
                    }
                }
            }
        }

        // Clear photos if no preview words
        if previousWordPreview == nil {
            previousWordPreviewPhoto = nil
        }
        if nextWordPreview == nil {
            nextWordPreviewPhoto = nil
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension FlashcardViewModel {
    static func preview(with context: ModelContext) -> FlashcardViewModel {
        let vm = FlashcardViewModel(modelContext: context)
        vm.currentWord = VocabularyWord.sample
        vm.currentPhoto = UIImage(systemName: "photo")
        vm.exampleSentences = SentencePair.samples
        return vm
    }
}
#endif
