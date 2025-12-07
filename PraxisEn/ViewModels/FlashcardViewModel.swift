import Foundation
import SwiftUI
import SwiftData
import OSLog
internal import Combine

@MainActor
class FlashcardViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current word being displayed
    @Published var currentWord: VocabularyWord?

    /// Is card flipped (showing back side)
    @Published var isFlipped: Bool = false

    /// Example sentences for current word (limited by subscription)
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
    @Published var totalWordsCount: Int = 0

    /// B2 words count (for progress bar gray overlay)
    @Published var b2WordsCount: Int = 0

    /// Show progress animation (+1 popup)
    @Published var showProgressAnimation: Bool = false

    /// Show daily limit alert
    @Published var showDailyLimitAlert: Bool = false

    /// Show level restriction upgrade prompt
    @Published var showLevelRestrictionAlert: Bool = false

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
    private let logger: Logger

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.logger = Logger(subsystem: "PraxisEn", category: "FlashcardViewModel")
    }

    // MARK: - Word Management

    /// Load next word using spaced repetition algorithm with ODR-aware content loading
    func loadNextWord() async {
        guard let settings = userSettings else {
            logger.error("No user settings found - attempting fallback word loading")
            await loadFallbackWord()
            return
        }

        // Use SpacedRepetitionManager with ODR-aware content loading
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
    }

    /// Handle case when no more words are available in target levels
    private func handleNoMoreWords(settings: UserSettings) async {
        let subscriptionManager = SubscriptionManager.shared

        // Check if user has completed all available free levels but isn't premium
        if !subscriptionManager.isPremiumActive {
            let unlockedLevels = subscriptionManager.getUnlockedLevels() // Should be ["A1", "A2", "B1"] for free users
            let completedLevels = ["A1", "A2", "B1"].filter { settings.isLevelCompleted[$0] == true }

            // If all free levels are completed, show level restriction alert for B2
            if completedLevels.count == unlockedLevels.count && completedLevels.count >= 3 {
                //print("🎯 All free levels completed, showing level restriction alert for B2")
                showLevelRestrictionAlert = true
                return
            }
        }

        // Default behavior - just log the situation
        if settings.allLevelsCompleted {
            //print("🎉 All levels completed including B2!")
        } else {
            //print("📚 No more words available in current target levels")
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
            ////print("❌ Error updating settings progress: \(error)")
        }
    }

    
    /// Check if user can make another card advance
    private func canMakeCardAdvance() -> Bool {
        guard SubscriptionManager.shared.canMakeSwipe() else {
            showDailyLimitAlert = true
            return false
        }
        return true
    }

        /// Go to next word (swipe right)
    func nextWord() async {
        // Check swipe limit for free users
        guard canMakeCardAdvance() else { return }

        // Record the swipe
        SubscriptionManager.shared.recordSwipe()

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
            ////print("ℹ️ No previous word")
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
            ////print("📸 Using cached image for: \(word.word)")
            return
        }

        // Load in background without showing loading state
        let photo = await ImageService.shared.fetchPhotoSafely(for: word.word)

        // Update state silently
        currentPhoto = photo
    }

    /// Load example sentences for current word (max 10)
    private func loadExamplesForCurrentWord() async {
        guard let word = currentWord else {
            //print("⚠️ No current word to load examples for")
            return
        }

        //print("🔍 Loading examples for word: '\(word.word)'")

        // Show loading state first
        await MainActor.run {
            exampleSentences = []
        }

        do {
            // Search for sentences containing the word (ODR-aware)
            let sentences = try await DatabaseManager.shared.searchSentencesWithFallback(
                containing: word.word,
                limit: 10
            )

            //print("📝 Found \(sentences.count) raw sentences for '\(word.word)'")

            // Filter and limit to best examples
            let filtered = sentences
                .filter { $0.englishText.lowercased().contains(word.word.lowercased()) }
                .sorted { $0.difficultyTier < $1.difficultyTier } // Easier first
                .prefix(SubscriptionManager.shared.getMaxSentencesPerWord())

            //print("✅ After filtering: \(filtered.count) sentences for '\(word.word)'")

            await MainActor.run {
                exampleSentences = Array(filtered)
            }

        } catch {
            //print("❌ Failed to load examples for '\(word.word)': \(error)")
            // Keep showing loading state instead of empty array
            // The UI should show "Example sentences loading..." when array is empty
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
            ////print("✅ Word marked as learned: \(word.word)")
        } catch {
            ////print("❌ Error saving learned state: \(error)")
        }
    }

    /// Mark current word as reviewed
    func markAsReviewed() {
        guard let word = currentWord else { return }

        word.markAsReviewed()

        do {
            try modelContext.save()
            ////print("✅ Word reviewed: \(word.word) (count: \(word.reviewCount))")
        } catch {
            ////print("❌ Error saving review: \(error)")
        }
    }

    /// Mark current word as known (swipe up gesture)
    func markCurrentWordAsKnown() async {
        // Check swipe limit for free users
        guard canMakeCardAdvance() else { return }

        guard let word = currentWord else { return }

        // Record the swipe
        SubscriptionManager.shared.recordSwipe()

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

    /// Update total words count for progress bar
    func updateTotalWordsCount() async {
        let descriptor = FetchDescriptor<VocabularyWord>()
        let allWords = (try? modelContext.fetch(descriptor)) ?? []
        totalWordsCount = allWords.count
    }

    /// Update B2 words count for progress bar gray overlay
    func updateB2WordsCount() async {
        let descriptor = FetchDescriptor<VocabularyWord>(
            predicate: #Predicate { $0.level == "B2" }
        )
        let b2Words = (try? modelContext.fetch(descriptor)) ?? []
        b2WordsCount = b2Words.count
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
            // Use SpacedRepetitionManager for preview with ODR-aware content loading
            guard let settings = userSettings else {
                logger.error("No user settings found - cannot load next word preview")
                nextWordPreview = nil
                return
            }

            if let nextWord = await SpacedRepetitionManager.selectNextWordWithSettings(
                from: modelContext,
                excluding: Array(wordHistory.suffix(10)),
                settings: settings
            ) {
                nextWordPreview = nextWord
            } else {
                logger.info("No more words available for preview")
                nextWordPreview = nil
            }
        }

        // Load photos in parallel
        await withTaskGroup(of: Void.self) { group in
            // Load previous photo
            if let prev = previousWordPreview {
                group.addTask {
                    let photo = await ImageService.shared.fetchPhotoSafely(for: prev.word)
                    await MainActor.run {
                        self.previousWordPreviewPhoto = photo
                    }
                }
            }

            // Load next photo
            if let next = nextWordPreview {
                group.addTask {
                    let photo = await ImageService.shared.fetchPhotoSafely(for: next.word)
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
            ////print("✅ Loaded user settings: \(firstSettings.wordSelectionMode.displayName)")
        } else {
            // Create default settings if none exist
            let defaultSettings = UserSettings()
            modelContext.insert(defaultSettings)

            do {
                try modelContext.save()
                userSettings = defaultSettings
                await updateSettingsProgress(settings: defaultSettings)
                ////print("✅ Created default user settings")
            } catch {
                ////print("❌ Error creating default settings: \(error)")
            }
        }
    }

    /// Fallback method to load any available word when settings are missing
    private func loadFallbackWord() async {
        do {
            let descriptor = FetchDescriptor<VocabularyWord>()
            let words = try modelContext.fetch(descriptor)

            // Prefer A1 words as the ultimate fallback
            let fallbackWord = words.first { $0.level == "A1" } ?? words.first

            if let word = fallbackWord {
                logger.info("Loaded fallback word: \(word.word)")
                currentWord = word
                addToHistory(word)

                // Reset state for new word
                isFlipped = false
                hasSeenBackOfCard = false

                await loadContentForCurrentWord()
            } else {
                logger.error("No words available in database for fallback")
            }
        } catch {
            logger.error("Failed to load fallback word: \(error)")
        }
    }

    /// Public method to load content for the current word (photo + examples)
    func loadContentForCurrentWord() async {
        await loadPhotoForCurrentWord()
        await loadExamplesForCurrentWord()
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
