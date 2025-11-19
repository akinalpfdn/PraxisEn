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

    // MARK: - Translation Input Properties

    /// Whether the translation input field should be shown
    @Published var showTranslationInput: Bool = false

    /// User's translation input
    @Published var userTranslationInput: String = ""

    /// Current validation state
    @Published var translationValidationState: ValidationState = .none

    /// Result of the last translation validation
    @Published var translationValidationResult: ValidationResult?

    /// Whether user has seen the back of the current card
    private var hasSeenBackOfCard: Bool = false

    /// User settings for learning preferences
    @Published var userSettings: UserSettings?

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Word Management

    /// Load next word using spaced repetition algorithm with user settings
    func loadNextWord() async {
        if let settings = userSettings {
            // Use settings-based selection
            guard let word = await SpacedRepetitionManager.selectNextWordWithSettings(
                from: modelContext,
                excluding: Array(wordHistory.suffix(10)),
                settings: settings
            ) else {
                // Handle no more words case
                await handleNoMoreWords(settings: settings)
                return
            }

            currentWord = word
            addToHistory(word)

            // Reset state for new word
            isFlipped = false
            hasSeenBackOfCard = false

            await loadPhotoForCurrentWord()
            await loadExamplesForCurrentWord()
            await updatePreviews()
            await updateKnownWordsCount()
            await updateSettingsProgress(settings: settings)
        } else {
            // Fallback to old method for backward compatibility
            await loadNextWordLegacy()
        }
    }

    /// Legacy word loading method (for backward compatibility)
    private func loadNextWordLegacy() async {
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

        // Reset state for new word
        isFlipped = false
        hasSeenBackOfCard = false

        await loadPhotoForCurrentWord()
        await loadExamplesForCurrentWord()
        await updatePreviews()
        await updateKnownWordsCount()
    }

    /// Handle case when no more words are available in target levels
    private func handleNoMoreWords(settings: UserSettings) async {
        if settings.allLevelsCompleted {
            print("🎉 All levels completed! No more new words available.")
            // Could show completion UI or message
        } else {
            print("📚 No more words available in current level(s)")
            // Could try to advance level or show message
        }
    }

    /// Update user settings progress when words are marked as known
    private func updateSettingsProgress(settings: UserSettings) async {
        // Calculate word counts per level
        let descriptor = FetchDescriptor<VocabularyWord>()
        let allWords = (try? modelContext.fetch(descriptor)) ?? []

        var totalWordsByLevel: [String: Int] = [:]
        var knownWordsByLevel: [String: Int] = [:]

        // Initialize counters
        for level in ["A1", "A2", "B1", "B2"] {
            totalWordsByLevel[level] = 0
            knownWordsByLevel[level] = 0
        }

        // Count words by level
        for word in allWords {
            if let levelCount = totalWordsByLevel[word.level] {
                totalWordsByLevel[word.level] = levelCount + 1
            }

            if word.isKnown {
                if let knownCount = knownWordsByLevel[word.level] {
                    knownWordsByLevel[word.level] = knownCount + 1
                }
            }
        }

        // Update settings with new counts
        settings.updateWordCounts(totalWords: totalWordsByLevel, knownWords: knownWordsByLevel)

        do {
            try modelContext.save()
        } catch {
            print("❌ Error updating settings progress: \(error)")
        }
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
            hasSeenBackOfCard = false

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
        // Increment repetition count for current word
        if let word = currentWord, !word.isKnown {
            word.incrementRepetition()
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
        hasSeenBackOfCard = false
        await loadPhotoForCurrentWord()
        await loadExamplesForCurrentWord()

        // Update previews
        await updatePreviews()
    }

    /// Go to previous word (swipe left)
    func previousWord() async {
        // Increment repetition count for current word
        if let word = currentWord, !word.isKnown {
            word.incrementRepetition()
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
        hasSeenBackOfCard = false
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

            // Track when user sees the back of the card
            if isFlipped {
                hasSeenBackOfCard = true
            }
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
        // (incrementRepetition will be skipped automatically since word.isKnown = true)
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

    /// Check if user has seen the back of the current card
    func userHasSeenBackOfCard() -> Bool {
        return hasSeenBackOfCard
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

        // Reset translation input state
        showTranslationInput = false
        userTranslationInput = ""
        translationValidationState = .none
        translationValidationResult = nil
        hasSeenBackOfCard = false
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

    // MARK: - Translation Input Methods

    /// Shows the translation input field
    func showTranslationInputField() {
        showTranslationInput = true
        translationValidationState = .typing
        userTranslationInput = ""
        translationValidationResult = nil
    }

    /// Hides the translation input field
    func hideTranslationInputField() {
        showTranslationInput = false
        translationValidationState = .none
        userTranslationInput = ""
        translationValidationResult = nil
    }

    /// Validates and submits the user's translation
    func submitTranslation() async {
        guard let word = currentWord else { return }

        let trimmedInput = userTranslationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        // Start validation
        translationValidationState = .validating

        // Small delay to show loading state
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Validate translation
        let result = TranslationValidator.validate(
            userInput: trimmedInput,
            correctTranslation: word.turkishTranslation
        )

        translationValidationResult = result

        if result.isCorrect {
            await handleCorrectTranslation()
        } else {
            await handleIncorrectTranslation()
        }
    }

    /// Handles a correct translation
    private func handleCorrectTranslation() async {
        translationValidationState = .correct

        // Wait a moment to show success message
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Mark word as known and go to next word
        await markCurrentWordAsKnown()
        hideTranslationInputField()
    }

    /// Handles an incorrect translation
    private func handleIncorrectTranslation() async {
        translationValidationState = .incorrect

        // Wait a moment to show error message
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Flip card to show correct answer
        isFlipped = true
        hasSeenBackOfCard = true  // Mark that user has seen the answer
        hideTranslationInputField()
    }

    /// Clears the translation input field
    func clearTranslationInput() {
        userTranslationInput = ""
        translationValidationState = .typing
        translationValidationResult = nil
    }

    /// Updates validation state when user starts typing
    func userStartedTypingTranslation() {
        if translationValidationState == .none || translationValidationState == .incorrect {
            translationValidationState = .typing
            translationValidationResult = nil
        }
    }

    // MARK: - Settings Management

    /// Load user settings from database
    func loadUserSettings() async {
        let descriptor = FetchDescriptor<UserSettings>()
        let settings = (try? modelContext.fetch(descriptor)) ?? []

        if let firstSettings = settings.first {
            userSettings = firstSettings
            await updateSettingsProgress(settings: firstSettings)
            print("✅ Loaded user settings: \(firstSettings.wordSelectionMode.displayName)")
        } else {
            // Create default settings if none exist
            let defaultSettings = UserSettings()
            modelContext.insert(defaultSettings)

            do {
                try modelContext.save()
                userSettings = defaultSettings
                await updateSettingsProgress(settings: defaultSettings)
                print("✅ Created default user settings")
            } catch {
                print("❌ Error creating default settings: \(error)")
            }
        }
    }

    /// Update user settings and trigger progress recalculation
    func updateUserSettings(_ settings: UserSettings) async {
        userSettings = settings
        await updateSettingsProgress(settings: settings)
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
