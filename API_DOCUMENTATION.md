# PraxisEn iOS - API Documentation

## Table of Contents
1. [Core Models](#core-models)
2. [ViewModels](#viewmodels)
3. [Services](#services)
4. [Database Management](#database-management)
5. [Configuration](#configuration)
6. [View Components](#view-components)

---

## Core Models

### VocabularyWord

The primary data model representing English vocabulary words with learning progress tracking.

```swift
@Model
final class VocabularyWord {
    // Basic Information
    @Attribute(.unique) var word: String          // The vocabulary word
    var level: String                            // CEFR level: A1, A2, B1, B2
    var definition: String                       // English definition
    var turkishTranslation: String                // Turkish translation
    var exampleSentence: String                  // Usage example

    // Linguistic Information
    var partOfSpeech: String                     // noun, verb, adjective, etc.
    var relatedForms: String                     // plurals, conjugations
    var synonyms: String                         // comma-separated list
    var antonyms: String                         // comma-separated list
    var collocations: String                     // common phrases

    // Learning Progress
    var isLearned: Bool                          // user marked as learned
    var reviewCount: Int                         // number of reviews
    var lastReviewedDate: Date?                  // last review timestamp
    var createdAt: Date                          // database entry date

    // Spaced Repetition
    var isKnown: Bool = false                   // mastered word
    var learnedAt: Date?                         // when marked as known
    var repetitions: Int = 0                    // consecutive successes
}
```

#### Key Properties
- `word`: Unique identifier for the vocabulary entry
- `level`: CEFR proficiency level (A1-B2)
- `difficultyTier`: Computed property (1-4 based on CEFR)
- `isInReviewSystem`: Returns true if word is in SRS rotation

#### Methods
```swift
// Learning Progress
func markAsReviewed()           // Increment review count
func markAsKnown()             // Mark as mastered
func resetProgress()           // Reset all progress
func toggleLearned()           // Toggle learned status

// Spaced Repetition
func incrementRepetition()     // Increment for successful review
func resetKnownStatus()        // Return to unknown state
```

#### Computed Properties
```swift
var synonymsList: [String]     // Array of synonyms
var antonymsList: [String]     // Array of antonyms
var collocationsList: [String] // Array of collocations
var relatedFormsList: [String] // Array of related forms
var displayTitle: String       // "abandon (B2) - verb"
var isBeginnerLevel: Bool      // A1 or A2 level
```

---

### SentencePair

Represents Turkish-English sentence pairs for contextual learning.

```swift
struct SentencePair {
    let turkishId: Int
    let turkishText: String
    let englishId: Int
    let englishText: String
    let difficultyLevel: String    // Maps to CEFR levels

    var difficultyTier: Int        // 1-4 based on difficulty
}
```

---

### UserSettings

Manages user preferences and learning configuration.

```swift
@Model
final class UserSettings {
    // Learning Preferences
    var wordSelectionMode: WordSelectionMode  // .random, .sequential, .spacedRepetition
    var targetLevels: [String]               // ["A1", "A2", "B1", "B2"]
    var dailyGoal: Int                       // Daily word target
    var isAudioEnabled: Bool                // TTS setting

    // Progress Tracking
    var isLevelCompleted: [String: Bool]     // Level completion status
    var totalWordsPerLevel: [String: Int]    // Word counts by level
    var knownWordsPerLevel: [String: Int]    // Known words by level
}
```

#### Word Selection Modes
```swift
enum WordSelectionMode: String, CaseIterable {
    case random = "Random"
    case sequential = "Sequential"
    case spacedRepetition = "Spaced Repetition"
}
```

---

## ViewModels

### FlashcardViewModel

Manages the flashcard learning experience with gesture navigation and content loading.

```swift
@MainActor
class FlashcardViewModel: ObservableObject {
    // Published Properties
    @Published var currentWord: VocabularyWord?
    @Published var isFlipped: Bool = false
    @Published var exampleSentences: [SentencePair] = []
    @Published var currentPhoto: UIImage?
    @Published var isLoadingPhoto: Bool = false
    @Published var showTranslationInput: Bool = false
    @Published var userTranslationInput: String = ""
    @Published var translationValidationState: ValidationState
    @Published var translationValidationResult: ValidationResult?

    // Progress Tracking
    @Published var knownWordsCount: Int = 0
    @Published var totalWordsCount: Int = 0
    @Published var b2WordsCount: Int = 0
    @Published var showProgressAnimation: Bool = false
}
```

#### Key Methods
```swift
// Word Navigation
func loadNextWord() async               // Load next word with SRS
func nextWord() async                  // Swipe right gesture
func previousWord() async              // Swipe left gesture
func toggleFlip()                      // Tap to flip card

// Learning Actions
func markAsLearned()                   // Toggle learned status
func markCurrentWordAsKnown() async   // Swipe up gesture
func playWordAudio()                   // Play pronunciation

// Translation Input
func showTranslationInputField()       // Show input overlay
func submitTranslation() async         // Validate and submit
func clearTranslationInput()           // Clear current input

// Data Management
func loadUserSettings() async         // Load preferences
func updateKnownWordsCount() async     // Update progress
```

#### Translation Validation States
```swift
enum ValidationState {
    case none                         // Not started
    case typing                       // User is typing
    case validating                   // Checking answer
    case correct                      // Correct translation
    case incorrect                    // Wrong translation
}
```

---

### LearnedFlashcardViewModel

Manages the learned words view with filtering and search capabilities.

```swift
@MainActor
class LearnedFlashcardViewModel: ObservableObject {
    @Published var learnedWords: [VocabularyWord] = []
    @Published var filteredWords: [VocabularyWord] = []
    @Published var searchText: String = ""
    @Published var selectedLevel: String = "All"
    @Published var sortOrder: SortOrder = .alphabetical
}
```

---

## Services

### AudioManager

Handles text-to-speech playback for vocabulary words.

```swift
class AudioManager {
    static let shared = AudioManager()

    func play(word: String)           // Play pronunciation
    func stop()                       // Stop current playback
    func configure(language: String) // Set TTS language
}
```

### ImageService

Manages image fetching and caching for vocabulary words.

```swift
class ImageService {
    static let shared = ImageService()

    func fetchPhoto(for word: String) async -> UIImage?
    func fetchPhotoSafely(for word: String) async -> UIImage?
    func preloadImages(for words: [String]) async
}
```

### SubscriptionManager

Handles freemium model and in-app purchase logic.

```swift
class SubscriptionManager {
    static let shared = SubscriptionManager()

    var isPremiumActive: Bool
    var hasUsedFreeTrial: Bool
    var dailySwipesRemaining: Int

    // Methods
    func canMakeSwipe() -> Bool
    func recordSwipe()
    func getMaxSentencesPerWord() -> Int
    func getUnlockedLevels() -> [String]
}
```

### ODRManager

Manages On-Demand Resources for large asset downloads.

```swift
class ODRManager {
    static let shared = ODRManager()

    func downloadFullContent() async
    func checkFullContentAvailability() async -> Bool
    func getDownloadProgress() -> Double
}
```

---

## Database Management

### DatabaseManager

Handles hybrid database operations with SwiftData and SQLite.

```swift
@MainActor
class DatabaseManager {
    static let shared = DatabaseManager()

    // Setup
    func setupDatabasesIfNeeded() async throws
    func setupDatabasesWithODR() async throws

    // Import
    func importVocabularyToSwiftData(modelContext: ModelContext) async throws -> Int
    func importSentencesToSwiftData(modelContext: ModelContext, limit: Int, offset: Int) async throws -> Int

    // Queries
    func searchSentences(containing word: String, limit: Int) async throws -> [SentencePair]
    func searchSentencesWithFallback(containing word: String, limit: Int) async throws -> [SentencePair]
    func getRandomSentences(count: Int, level: String?) async throws -> [SentencePair]

    // Status
    func isDatabaseSetupComplete() -> Bool
    func isFullDatabaseSetupComplete() -> Bool
    func getDatabaseSizes() throws -> (vocabulary: Int64, sentences: Int64)
}
```

### SpacedRepetitionManager

Implements the SuperMemo-2 algorithm for optimal review scheduling.

```swift
class SpacedRepetitionManager {
    static func selectNextWord(
        from modelContext: ModelContext,
        excluding: [VocabularyWord],
        settings: UserSettings
    ) async -> VocabularyWord?

    static func calculateNextReview(
        for word: VocabularyWord,
        quality: Int
    ) -> Date

    static func updateWordProgress(
        word: VocabularyWord,
        quality: Int
    )
}
```

#### Algorithm Parameters
- **quality**: 0-5 rating of recall performance
- **easeFactor**: Adjusts based on performance
- **interval**: Days until next review
- **repetitions**: Number of successful recalls

---

## Configuration

### Config.swift

Global app configuration constants.

```swift
struct Config {
    // API Keys
    static let imageGenerationAPIKey = "YOUR_API_KEY"
    static let ttsAPIKey = "YOUR_TTS_API_KEY"

    // Database
    static let vocabularyDatabaseName = "vocabulary.db"
    static let sentencesDatabaseName = "sentences.db"

    // Learning Limits
    static let maxDailyFreeWords = 20
    static let maxSentencesPerWordFree = 3
    static let maxSentencesPerWordPremium = 10

    // UI Configuration
    static let imageCacheLimit = 50
    static let wordHistoryLimit = 50
    static let maxBatchSize = 500
}
```

### ContentConstants.swift

Content-related constants and configurations.

```swift
struct ContentConstants {
    static let ceferLevels = ["A1", "A2", "B1", "B2"]
    static let levelEmojis: [String: String] = [
        "A1": "🟢", "A2": "🔵", "B1": "🟠", "B2": "🔴"
    ]
    static let partsOfSpeech = [
        "noun", "verb", "adjective", "adverb",
        "preposition", "conjunction", "pronoun"
    ]
}
```

---

## View Components

### FlashcardView

Main flashcard learning interface with gesture support.

```swift
struct FlashcardView: View {
    @StateObject private var viewModel: FlashcardViewModel

    var body: some View {
        SwipeableCardStack {
            // Front side
            FlashcardFrontView(word: viewModel.currentWord)

            // Back side
            FlashcardBackView(word: viewModel.currentWord)
        }
        .onTapGesture {
            viewModel.toggleFlip()
        }
    }
}
```

### ProgressBarView

Visual progress indicator for learning completion.

```swift
struct ProgressBarView: View {
    let known: Int
    let total: Int
    let b2Count: Int

    var progress: Double {
        Double(known) / Double(total)
    }
}
```

### TranslationInputOverlay

Interactive input for user translations with validation.

```swift
struct TranslationInputOverlay: View {
    @ObservedObject var viewModel: FlashcardViewModel

    var body: some View {
        VStack {
            TextField("Enter translation...", text: $viewModel.userTranslationInput)

            Button("Submit") {
                viewModel.submitTranslation()
            }
            .disabled(viewModel.userTranslationInput.isEmpty)
        }
    }
}
```

---

## Error Handling

### Custom Error Types

```swift
enum DatabaseError: LocalizedError {
    case bundleFileNotFound(String)
    case databaseNotFound(String)
    case cannotOpenDatabase
    case queryPreparationFailed
    case documentsDirectoryNotFound
}

enum ValidationError: LocalizedError {
    case emptyInput
    case invalidFormat
    case translationNotFound
}
```

---

## Performance Optimizations

### Image Caching
- In-memory cache for recently used images
- Disk cache for persistent storage
- Preloading of upcoming word images

### Database Queries
- Batched imports to prevent memory issues
- Indexed queries for faster searches
- Direct SQLite for large datasets

### Content Loading
- ODR (On-Demand Resources) for large assets
- Progressive loading of sentences
- Background processing for non-critical operations

---

## Best Practices

1. **Async/Await**: Use structured concurrency for all async operations
2. **@MainActor**: Keep UI updates on the main thread
3. **Error Handling**: Implement proper error propagation
4. **Memory Management**: Monitor memory usage with large datasets
5. **Background Tasks**: Use TaskGroups for parallel operations

---

## Integration Examples

### Loading a Word with Content

```swift
func loadWordWithContext() async {
    await viewModel.loadNextWord()

    // Content is loaded automatically
    // - Photo: fetched and cached
    // - Examples: searched and filtered
    // - Audio: available on demand
}
```

### Handling User Translation

```swift
func handleTranslation() async {
    viewModel.showTranslationInputField()
    // User types...

    await viewModel.submitTranslation()
    // Result handled with animation
    // - Correct: mark as known, next word
    // - Incorrect: show answer, flip card
}
```

### Tracking Progress

```swift
func updateProgress() async {
    await viewModel.updateKnownWordsCount()
    await viewModel.updateTotalWordsCount()
    await viewModel.updateB2WordsCount()

    // Progress bar updates automatically
    // User settings are updated
    // Achievement checks run
}
```