# PraxisEn iOS to Kotlin/Android Port Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Technology Stack Mapping](#technology-stack-mapping)
3. [Project Structure](#project-structure)
4. [Core Component Migration](#core-component-migration)
5. [Data Layer Implementation](#data-layer-implementation)
6. [UI Layer Migration](#ui-layer-migration)
7. [Business Logic Porting](#business-logic-porting)
8. [Services Integration](#services-integration)
9. [Testing Strategy](#testing-strategy)
10. [Deployment Considerations](#deployment-considerations)

---

## Architecture Overview

### iOS Architecture (Current)
```
SwiftUI + MVVM
├── SwiftData (Core Data) for vocabulary
├── SQLite for sentence corpus
├── StoreKit for subscriptions
├── AVFoundation for TTS
└── CloudKit for sync
```

### Android Architecture (Target)
```
Jetpack Compose + MVVM
├── Room Database for vocabulary
├── SQLite for sentence corpus
├── Google Play Billing for subscriptions
├── Android TTS Engine
└── Firebase/Wearable for sync
```

---

## Technology Stack Mapping

### Core Frameworks

| iOS (Swift) | Android (Kotlin) | Purpose |
|--------------|------------------|---------|
| SwiftUI | Jetpack Compose | Modern declarative UI |
| SwiftData | Room + SQLite | Local persistence |
| Combine | Kotlin Coroutines + Flow | Reactive programming |
| StoreKit | Google Play Billing | In-app purchases |
| AVFoundation | Android TTS API | Text-to-speech |
| CloudKit | Firebase Firestore | Cloud sync |
| Core Animation | Compose Animation | UI animations |
| ImageIO | Coil/Glide | Image loading |
| Core Location | Location Services | Location features |

### Dependencies Translation

| iOS | Android Kotlin |
|-----|----------------|
| `ObservableObject` | `ViewModel` + `StateFlow` |
| `@Published` | `MutableStateFlow` |
| `@State` | `mutableStateOf` |
| `@Query` | `@Query` (Room) |
| `async/await` | `suspend` functions |
| `Task` | `CoroutineScope` |
| `Timer` | `CoroutineTimer` |

---

## Project Structure

### Recommended Android Project Structure

```
app/
├── src/main/java/com/praxisen/
│   ├── data/                     # Data layer
│   │   ├── database/            # Room entities & DAOs
│   │   │   ├── entity/
│   │   │   │   ├── VocabularyWord.kt
│   │   │   │   ├── SentencePair.kt
│   │   │   │   └── UserSettings.kt
│   │   │   ├── dao/
│   │   │   │   ├── VocabularyDao.kt
│   │   │   │   ├── SentenceDao.kt
│   │   │   │   └── UserSettingsDao.kt
│   │   │   └── AppDatabase.kt
│   │   ├── repository/
│   │   │   ├── VocabularyRepository.kt
│   │   │   ├── SentenceRepository.kt
│   │   │   └── UserRepository.kt
│   │   └── remote/              # API services
│   │       ├── ApiService.kt
│   │       └── dto/
│   ├── domain/                  # Business logic
│   │   ├── model/
│   │   │   ├── VocabularyWord.kt
│   │   │   ├── SentencePair.kt
│   │   │   └── UserSettings.kt
│   │   ├── usecase/
│   │   │   ├── GetNextWordUseCase.kt
│   │   │   ├── MarkAsKnownUseCase.kt
│   │   │   └── GetLearningStatsUseCase.kt
│   │   └── repository/
│   │       ├── IVocabularyRepository.kt
│   │       ├── ISentenceRepository.kt
│   │       └── IUserRepository.kt
│   ├── presentation/            # UI layer
│   │   ├── ui/
│   │   │   ├── flashcard/
│   │   │   │   ├── FlashcardScreen.kt
│   │   │   │   ├── FlashcardViewModel.kt
│   │   │   │   └── components/
│   │   │   ├── stats/
│   │   │   ├── settings/
│   │   │   └── premium/
│   │   └── theme/
│   │       ├── Color.kt
│   │       ├── Theme.kt
│   │       └── Type.kt
│   ├── service/                 # Android services
│   │   ├── audio/AudioService.kt
│   │   ├── billing/BillingService.kt
│   │   ├── image/ImageService.kt
│   │   └── sync/SyncService.kt
│   ├── util/
│   │   ├── SpacedRepetitionManager.kt
│   │   ├── DatabaseManager.kt
│   │   └── Extensions.kt
│   └── di/                      # Dependency Injection
│       ├── DatabaseModule.kt
│       ├── NetworkModule.kt
│       └── RepositoryModule.kt
├── src/test/                    # Unit tests
├── src/androidTest/             # Integration tests
└── build.gradle.kts             # Gradle build file
```

---

## Core Component Migration

### 1. Data Models

#### iOS (Swift) - VocabularyWord
```swift
@Model
final class VocabularyWord {
    @Attribute(.unique) var word: String
    var level: String
    var turkishTranslation: String
    var isLearned: Bool
    var repetitions: Int
    var lastReviewedDate: Date?
}
```

#### Android (Kotlin) - VocabularyWord
```kotlin
@Entity(tableName = "vocabulary_words")
data class VocabularyWord(
    @PrimaryKey
    val word: String,

    @ColumnInfo(name = "level")
    val level: String,

    @ColumnInfo(name = "turkish_translation")
    val turkishTranslation: String,

    @ColumnInfo(name = "definition")
    val definition: String,

    @ColumnInfo(name = "is_learned")
    var isLearned: Boolean = false,

    @ColumnInfo(name = "repetitions")
    var repetitions: Int = 0,

    @ColumnInfo(name = "last_reviewed_date")
    var lastReviewedDate: Long? = null,

    @ColumnInfo(name = "is_known")
    var isKnown: Boolean = false,

    @ColumnInfo(name = "learned_at")
    var learnedAt: Long? = null,

    @ColumnInfo(name = "created_at")
    val createdAt: Long = System.currentTimeMillis()
) {
    // Helper properties
    val hasBeenReviewed: Boolean
        get() = repetitions > 0

    val difficultyTier: Int
        get() = when (level) {
            "A1" -> 1
            "A2" -> 2
            "B1" -> 3
            "B2" -> 4
            else -> 4
        }

    val isBeginnerLevel: Boolean
        get() = level in listOf("A1", "A2")
}
```

### 2. Room Database Setup

#### Database Entity with Relationships
```kotlin
@Entity(
    tableName = "vocabulary_words",
    indices = [
        Index(value = ["level"]),
        Index(value = ["is_known"]),
        Index(value = ["repetitions"])
    ]
)
data class VocabularyWord(
    // ... fields from above
)

@Entity(
    tableName = "sentence_pairs",
    foreignKeys = [
        ForeignKey(
            entity = VocabularyWord::class,
            parentColumns = ["word"],
            childColumns = ["related_word"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class SentencePair(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    val turkishId: Int,
    val turkishText: String,
    val englishId: Int,
    val englishText: String,
    val difficultyLevel: String,

    @ColumnInfo(name = "related_word")
    val relatedWord: String?
)
```

#### DAO Implementation
```kotlin
@Dao
interface VocabularyDao {
    @Query("SELECT * FROM vocabulary_words")
    suspend fun getAllWords(): List<VocabularyWord>

    @Query("SELECT * FROM vocabulary_words WHERE word = :word")
    suspend fun getWord(word: String): VocabularyWord?

    @Query("""
        SELECT * FROM vocabulary_words
        WHERE is_known = 0
        AND repetitions = 0
        AND level IN (:levels)
        ORDER BY RANDOM()
        LIMIT 1
    """)
    suspend fun getRandomNewWord(levels: List<String>): VocabularyWord?

    @Query("""
        SELECT * FROM vocabulary_words
        WHERE is_known = 0
        AND repetitions > 0
        AND level IN (:levels)
        ORDER BY repetitions ASC, last_reviewed_date ASC
        LIMIT 1
    """)
    suspend fun getReviewWord(levels: List<String>): VocabularyWord?

    @Update
    suspend fun updateWord(word: VocabularyWord)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(words: List<VocabularyWord>)

    @Query("SELECT COUNT(*) FROM vocabulary_words WHERE is_known = 1")
    suspend fun getKnownWordsCount(): Int

    @Query("SELECT COUNT(*) FROM vocabulary_words")
    suspend fun getTotalWordsCount(): Int
}
```

### 3. Repository Pattern

```kotlin
interface IVocabularyRepository {
    suspend fun getNextWord(excluding: List<String>, settings: UserSettings): VocabularyWord?
    suspend fun updateWord(word: VocabularyWord)
    suspend fun getKnownWordsCount(): Int
    suspend fun getTotalWordsCount(): Int
    fun getWordStream(): Flow<List<VocabularyWord>>
}

@Singleton
class VocabularyRepository @Inject constructor(
    private val vocabularyDao: VocabularyDao,
    private val spacedRepetitionManager: SpacedRepetitionManager,
    private val externalDb: ExternalSentenceDatabase
) : IVocabularyRepository {

    override suspend fun getNextWord(
        excluding: List<String>,
        settings: UserSettings
    ): VocabularyWord? {
        val targetLevels = settings.getTargetLevels()

        return spacedRepetitionManager.selectNextWordWithSettings(
            vocabularyDao = vocabularyDao,
            excluding = excluding,
            settings = settings,
            targetLevels = targetLevels
        )
    }

    override suspend fun updateWord(word: VocabularyWord) {
        vocabularyDao.updateWord(word)
    }

    override fun getWordStream(): Flow<List<VocabularyWord>> {
        return vocabularyDao.getAllWordsStream()
            .map { words -> words.sortedBy { it.word } }
            .flowOn(Dispatchers.IO)
    }
}
```

---

## Data Layer Implementation

### 1. Hybrid Database Architecture

#### Room Database (Vocabulary)
```kotlin
@Database(
    entities = [
        VocabularyWord::class,
        SentencePair::class,
        UserSettings::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun vocabularyDao(): VocabularyDao
    abstract fun sentenceDao(): SentenceDao
    abstract fun userSettingsDao(): UserSettingsDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "praxisen_database"
                )
                .addCallback(DatabaseCallback())
                .build()
                INSTANCE = instance
                instance
            }
        }
    }

    private class DatabaseCallback : RoomDatabase.Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            // Import data from bundled databases
            DatabaseInitializer.initialize(db)
        }
    }
}
```

#### Direct SQLite Access (Large Dataset)
```kotlin
class ExternalSentenceDatabase @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var database: SQLiteDatabase? = null

    suspend fun initialize() = withContext(Dispatchers.IO) {
        val dbFile = File(context.filesDir, "sentences.db")

        if (!dbFile.exists()) {
            // Copy from assets
            copyDatabaseFromAssets(dbFile)
        }

        database = SQLiteDatabase.openDatabase(
            dbFile.path,
            null,
            SQLiteDatabase.OPEN_READONLY
        )
    }

    suspend fun searchSentences(
        containing: String,
        limit: Int = 50
    ): List<SentencePair> = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext emptyList()

        val cursor = db.query(
            "sentences",
            arrayOf("turkish_id", "turkish_text", "english_id", "english_text", "difficulty_level"),
            "english_text LIKE ?",
            arrayOf("%$containing%"),
            null,
            null,
            "RANDOM()",
            limit.toString()
        )

        cursor.use { c ->
            generateSequence {
                if (c.moveToNext()) {
                    SentencePair(
                        turkishId = c.getInt(0),
                        turkishText = c.getString(1),
                        englishId = c.getInt(2),
                        englishText = c.getString(3),
                        difficultyLevel = c.getString(4)
                    )
                } else null
            }.toList()
        }
    }

    private suspend fun copyDatabaseFromAssets(destination: File) {
        context.assets.open("sentences.db").use { input ->
            destination.outputStream().use { output ->
                input.copyTo(output)
            }
        }
    }
}
```

### 2. Dependency Injection Setup (Hilt)

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "praxisen_database"
        ).build()
    }

    @Provides
    fun provideVocabularyDao(database: AppDatabase): VocabularyDao {
        return database.vocabularyDao()
    }

    @Provides
    @Singleton
    fun provideExternalSentenceDatabase(@ApplicationContext context: Context): ExternalSentenceDatabase {
        return ExternalSentenceDatabase(context).apply {
            runBlocking { initialize() }
        }
    }
}

@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {

    @Provides
    @Singleton
    fun provideVocabularyRepository(
        vocabularyDao: VocabularyDao,
        spacedRepetitionManager: SpacedRepetitionManager,
        externalDb: ExternalSentenceDatabase
    ): IVocabularyRepository {
        return VocabularyRepository(vocabularyDao, spacedRepetitionManager, externalDb)
    }
}
```

---

## UI Layer Migration

### 1. ViewModel Implementation

```kotlin
@HiltViewModel
class FlashcardViewModel @Inject constructor(
    private val vocabularyRepository: IVocabularyRepository,
    private val imageService: ImageService,
    private val audioService: AudioService,
    private val subscriptionManager: SubscriptionManager,
    private val translationValidator: TranslationValidator
) : ViewModel() {

    // StateFlow for reactive UI
    private val _uiState = MutableStateFlow(FlashcardUiState())
    val uiState: StateFlow<FlashcardUiState> = _uiState.asStateFlow()

    // Current word
    private val _currentWord = MutableStateFlow<VocabularyWord?>(null)
    val currentWord: StateFlow<VocabularyWord?> = _currentWord.asStateFlow()

    // Navigation history
    private val wordHistory = mutableListOf<VocabularyWord>()
    private var currentIndex = -1

    init {
        loadUserSettings()
        loadNextWord()
    }

    fun loadNextWord() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            val settings = subscriptionManager.getUserSettings()
            val nextWord = vocabularyRepository.getNextWord(
                excluding = wordHistory.takeLast(10).map { it.word },
                settings = settings
            )

            nextWord?.let { word ->
                _currentWord.value = word
                addToHistory(word)
                loadWordContent(word)
                updateProgress()
            }

            _uiState.update { it.copy(isLoading = false) }
        }
    }

    fun flipCard() {
        _uiState.update {
            it.copy(
                isFlipped = !it.isFlipped,
                hasSeenBack = !it.isFlipped
            )
        }
    }

    fun markAsKnown() {
        viewModelScope.launch {
            val word = _currentWord.value ?: return@launch
            val updatedWord = word.copy(
                isKnown = true,
                learnedAt = System.currentTimeMillis(),
                repetitions = 0
            )

            vocabularyRepository.updateWord(updatedWord)

            _uiState.update {
                it.copy(
                    showSuccessAnimation = true
                )
            }

            // Hide animation after delay
            delay(1400)
            _uiState.update { it.copy(showSuccessAnimation = false) }

            loadNextWord()
        }
    }

    private fun loadWordContent(word: VocabularyWord) {
        viewModelScope.launch {
            // Load image
            launch {
                val image = imageService.fetchImage(word.word)
                _uiState.update { it.copy(currentImage = image) }
            }

            // Load sentences
            launch {
                val sentences = imageService.fetchSentences(word.word, limit = 10)
                _uiState.update { it.copy(exampleSentences = sentences) }
            }
        }
    }

    private fun addToHistory(word: VocabularyWord) {
        // Remove words after current index
        if (currentIndex < wordHistory.size - 1) {
            wordHistory.subList(currentIndex + 1, wordHistory.size).clear()
        }

        wordHistory.add(word)
        currentIndex = wordHistory.size - 1

        // Limit history size
        if (wordHistory.size > 50) {
            wordHistory.removeFirst()
            currentIndex--
        }
    }
}

data class FlashcardUiState(
    val isLoading: Boolean = false,
    val isFlipped: Boolean = false,
    val hasSeenBack: Boolean = false,
    val currentImage: Bitmap? = null,
    val exampleSentences: List<SentencePair> = emptyList(),
    val showTranslationInput: Boolean = false,
    val translationInput: String = "",
    val translationValidationState: ValidationState = ValidationState.None,
    val showSuccessAnimation: Boolean = false,
    val knownWordsCount: Int = 0,
    val totalWordsCount: Int = 0,
    val b2WordsCount: Int = 0
)

enum class ValidationState {
    None,
    Typing,
    Validating,
    Correct,
    Incorrect
}
```

### 2. Compose UI Implementation

```kotlin
@Composable
fun FlashcardScreen(
    viewModel: FlashcardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val currentWord by viewModel.currentWord.collectAsState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Progress Bar
        ProgressBar(
            known = uiState.knownWordsCount,
            total = uiState.totalWordsCount,
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .align(Alignment.TopCenter)
        )

        // Flashcard
        Flashcard(
            word = currentWord,
            isFlipped = uiState.isFlipped,
            image = uiState.currentImage,
            sentences = uiState.exampleSentences,
            onFlip = { viewModel.flipCard() },
            onMarkAsKnown = { viewModel.markAsKnown() },
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.Center)
        )

        // Translation Input Overlay
        if (uiState.showTranslationInput) {
            TranslationInputOverlay(
                input = uiState.translationInput,
                validationState = uiState.translationValidationState,
                onInputChange = { /* update input */ },
                onSubmit = { /* submit translation */ },
                onDismiss = { /* dismiss */ },
                modifier = Modifier.fillMaxSize()
            )
        }

        // Success Animation
        if (uiState.showSuccessAnimation) {
            SuccessAnimation(
                modifier = Modifier.align(Alignment.Center)
            )
        }

        // Loading Indicator
        if (uiState.isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center)
            )
        }
    }
}

@Composable
fun Flashcard(
    word: VocabularyWord?,
    isFlipped: Boolean,
    image: Bitmap?,
    sentences: List<SentencePair>,
    onFlip: () -> Unit,
    onMarkAsKnown: () -> Unit,
    modifier: Modifier = Modifier
) {
    var rotationY by remember { mutableStateOf(0f) }

    LaunchedEffect(isFlipped) {
        rotationY = if (isFlipped) 180f else 0f
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(0.7f)
            .graphicsLayer {
                rotationY = rotationY
                cameraDistance = 12f * density
            }
            .pointerInput(Unit) {
                detectTapGestures { onFlip() }
            }
    ) {
        Card(
            modifier = Modifier.fillMaxSize(),
            elevation = CardDefaults.cardElevation(8.dp),
            shape = RoundedCornerShape(16.dp)
        ) {
            if (abs(rotationY) < 90f) {
                // Front of card
                FlashcardFront(
                    word = word,
                    image = image,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                // Back of card (rotated)
                FlashcardBack(
                    word = word,
                    sentences = sentences,
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer { rotationY = 180f }
                )
            }
        }
    }
}
```

---

## Business Logic Porting

### 1. Spaced Repetition Manager

```kotlin
@Singleton
class SpacedRepetitionManager @Inject constructor() {

    suspend fun selectNextWordWithSettings(
        vocabularyDao: VocabularyDao,
        excluding: List<String>,
        settings: UserSettings,
        targetLevels: List<String>
    ): VocabularyWord? {
        val stats = getReviewStats(vocabularyDao)
        val shouldShowNew = shouldSelectNewWord(stats.wordsInReview)

        return if (shouldShowNew) {
            selectNewWord(vocabularyDao, excluding, targetLevels)
        } else {
            selectReviewWord(vocabularyDao, excluding, targetLevels)
        }
    }

    private suspend fun shouldSelectNewWord(wordsInReview: Int): Boolean {
        return when {
            wordsInReview <= 10 -> true  // 100% new
            wordsInReview <= 20 -> Random.nextFloat() < 0.6f  // 60% new
            wordsInReview <= 50 -> Random.nextFloat() < 0.3f  // 30% new
            else -> false  // 0% new, only reviews
        }
    }

    private suspend fun selectNewWord(
        vocabularyDao: VocabularyDao,
        excluding: List<String>,
        targetLevels: List<String>
    ): VocabularyWord? {
        for (level in targetLevels) {
            val word = vocabularyDao.getRandomNewWord(level)
            if (word != null && word.word !in excluding) {
                return word
            }
        }
        return null
    }

    private suspend fun selectReviewWord(
        vocabularyDao: VocabularyDao,
        excluding: List<String>,
        targetLevels: List<String>
    ): VocabularyWord? {
        // Get words grouped by repetition count
        val reviewWords = vocabularyDao.getReviewWordsByRepetition(targetLevels)
        val recentWords = excluding.toSet()

        reviewWords.entries
            .sortedBy { it.key }
            .forEach { (_, words) ->
                val available = words.filter { it.word !in recentWords }

                if (available.isNotEmpty()) {
                    // Sort by last reviewed date (oldest first)
                    val sortedByTime = available.sortedByOrNull { it.lastReviewedDate }

                    // Add randomness
                    return if (sortedByTime?.size ?: 0 > 3 && Random.nextFloat() < 0.7f) {
                        // Pick from oldest 25%
                        val topQuartile = max(1, (sortedByTime?.size ?: 0) / 4)
                        sortedByTime?.take(topQuartile)?.random()
                    } else {
                        available.random()
                    }
                }
            }

        return null
    }

    fun calculateNextReview(word: VocabularyWord, quality: Int): Date {
        // SuperMemo-2 algorithm implementation
        var easeFactor = word.easeFactor
        var interval = word.interval
        var repetitions = word.repetitions

        if (quality >= 3) {
            repetitions++
            if (repetitions == 1) {
                interval = 1
            } else if (repetitions == 2) {
                interval = 6
            } else {
                interval = (interval * easeFactor).toInt()
            }
        } else {
            repetitions = 0
            interval = 1
        }

        easeFactor = easeFactor + (0.1f - (5 - quality) * (0.08f + (5 - quality) * 0.02f))
        easeFactor = max(1.3f, easeFactor)

        // Calculate next review date
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, interval)

        return calendar.time
    }
}
```

### 2. Subscription Manager

```kotlin
@Singleton
class SubscriptionManager @Inject constructor(
    private val billingClient: BillingClient,
    private val userRepository: IUserRepository,
    @ApplicationScope private val coroutineScope: CoroutineScope
) {
    private val _subscriptionState = MutableStateFlow(SubscriptionState())
    val subscriptionState: StateFlow<SubscriptionState> = _subscriptionState.asStateFlow()

    companion object {
        private const val FREE_TIER_SWIPE_LIMIT = 30
        private const val FREE_TIER_SENTENCE_LIMIT = 3
        private const val PREMIUM_TIER_SENTENCE_LIMIT = 10
        private val FREE_LEVELS = listOf("A1", "A2", "B1")
        private val ALL_LEVELS = listOf("A1", "A2", "B1", "B2")
    }

    init {
        setupBillingClient()
    }

    private fun setupBillingClient() {
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    queryPurchases()
                    querySkuDetails()
                }
            }

            override fun onBillingServiceDisconnected() {
                // Attempt to reconnect
            }
        })
    }

    fun canMakeSwipe(): Boolean {
        val state = _subscriptionState.value

        // Premium users have unlimited swipes
        if (state.isPremiumActive) return true

        // Check if we need to reset daily counter
        updateDailySwipeCount()

        return state.dailySwipesUsed < FREE_TIER_SWIPE_LIMIT
    }

    fun recordSwipe() {
        if (!_subscriptionState.value.isPremiumActive) {
            updateDailySwipeCount()

            val currentSwipes = _subscriptionState.value.dailySwipesUsed
            if (currentSwipes < FREE_TIER_SWIPE_LIMIT) {
                _subscriptionState.update {
                    it.copy(
                        dailySwipesUsed = currentSwipes + 1,
                        dailySwipesRemaining = max(0, FREE_TIER_SWIPE_LIMIT - currentSwipes - 1)
                    )
                }

                // Persist to database
                coroutineScope.launch {
                    userRepository.updateDailySwipes(currentSwipes + 1)
                }
            }
        }
    }

    fun isLevelUnlocked(level: String): Boolean {
        val state = _subscriptionState.value
        return if (state.isPremiumActive) {
            ALL_LEVELS.contains(level)
        } else {
            FREE_LEVELS.contains(level)
        }
    }

    fun getMaxSentencesPerWord(): Int {
        return if (_subscriptionState.value.isPremiumActive) {
            PREMIUM_TIER_SENTENCE_LIMIT
        } else {
            FREE_TIER_SENTENCE_LIMIT
        }
    }

    private fun updateDailySwipeCount() {
        val state = _subscriptionState.value
        val now = System.currentTimeMillis()
        val lastReset = state.lastSwipeResetDate

        if (!isSameDay(lastReset, now)) {
            _subscriptionState.update {
                it.copy(
                    dailySwipesUsed = 0,
                    dailySwipesRemaining = FREE_TIER_SWIPE_LIMIT,
                    lastSwipeResetDate = now
                )
            }
        }
    }

    private fun isSameDay(timestamp1: Long, timestamp2: Long): Boolean {
        val cal1 = Calendar.getInstance().apply { timeInMillis = timestamp1 }
        val cal2 = Calendar.getInstance().apply { timeInMillis = timestamp2 }

        return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
                cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
    }
}

data class SubscriptionState(
    val isPremiumActive: Boolean = false,
    val subscriptionTier: SubscriptionTier = SubscriptionTier.FREE,
    val dailySwipesUsed: Int = 0,
    val dailySwipesRemaining: Int = 30,
    val lastSwipeResetDate: Long = System.currentTimeMillis(),
    val subscriptionExpirationDate: Long? = null
)

enum class SubscriptionTier {
    FREE, PREMIUM
}
```

---

## Services Integration

### 1. Audio Service (TTS)

```kotlin
@Singleton
class AudioService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val textToSpeech = TextToSpeech(context) { status ->
        if (status == TextToSpeech.SUCCESS) {
            // Configure TTS
            textToSpeech.language = Locale.US
            textToSpeech.setSpeechRate(0.9f)
        }
    }

    fun playWord(word: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            textToSpeech.speak(
                word,
                TextToSpeech.QUEUE_ADD,
                null,
                "word_${word.hashCode()}"
            )
        } else {
            textToSpeech.speak(word, TextToSpeech.QUEUE_ADD, null)
        }
    }

    fun stop() {
        textToSpeech.stop()
    }

    fun setLanguage(locale: Locale) {
        textToSpeech.language = locale
    }

    fun setSpeechRate(rate: Float) {
        textToSpeech.setSpeechRate(rate.coerceIn(0.5f, 2.0f))
    }
}
```

### 2. Image Service with Caching

```kotlin
@Singleton
class ImageService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val imageCache = LruCache<String, Bitmap>(50)
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    suspend fun fetchImage(word: String): Bitmap? = withContext(Dispatchers.IO) {
        // Check cache first
        imageCache.get(word)?.let { return@withContext it }

        // Check local storage
        getLocalImage(word)?.let { bitmap ->
            imageCache.put(word, bitmap)
            return@withContext bitmap
        }

        // Fetch from API
        try {
            val url = "https://api.example.com/images?word=${URLEncoder.encode(word, "UTF-8")}"
            val bitmap = downloadImage(url)

            bitmap?.let {
                // Cache and save locally
                imageCache.put(word, it)
                saveImageLocally(word, it)
            }

            bitmap
        } catch (e: Exception) {
            null
        }
    }

    private suspend fun downloadImage(url: String): Bitmap? = withContext(Dispatchers.IO) {
        try {
            val connection = URL(url).openConnection() as HttpURLConnection
            connection.doInput = true
            connection.connect()

            val inputStream = connection.inputStream
            BitmapFactory.decodeStream(inputStream)
        } catch (e: Exception) {
            null
        }
    }

    private fun getLocalImage(word: String): Bitmap? {
        val file = File(context.filesDir, "images/${word.hashCode()}.jpg")
        return if (file.exists()) {
            BitmapFactory.decodeFile(file.absolutePath)
        } else null
    }

    private fun saveImageLocally(word: String, bitmap: Bitmap) {
        val imagesDir = File(context.filesDir, "images")
        if (!imagesDir.exists()) {
            imagesDir.mkdirs()
        }

        val file = File(imagesDir, "${word.hashCode()}.jpg")
        try {
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
            }
        } catch (e: Exception) {
            Log.e("ImageService", "Failed to save image", e)
        }
    }

    fun preloadImages(words: List<String>) {
        coroutineScope.launch {
            words.forEach { word ->
                fetchImage(word)
            }
        }
    }

    fun clearCache() {
        imageCache.evictAll()
    }
}
```

### 3. Billing Service (Google Play Billing)

```kotlin
@Singleton
class BillingService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val subscriptionManager: SubscriptionManager
) : PurchasesUpdatedListener {

    private lateinit var billingClient: BillingClient
    private val _skuDetails = MutableStateFlow<List<SkuDetails>>(emptyList())
    val skuDetails: StateFlow<List<SkuDetails>> = _skuDetails.asStateFlow()

    companion object {
        const val PREMIUM_MONTHLY = "premium_monthly"
        const val PREMIUM_YEARLY = "premium_yearly"
    }

    fun initialize() {
        billingClient = BillingClient.newBuilder(context)
            .setListener(this)
            .enablePendingPurchases()
            .build()

        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    querySkuDetails()
                    queryPurchases()
                }
            }

            override fun onBillingServiceDisconnected() {
                // Handle disconnection
            }
        })
    }

    override fun onPurchasesUpdated(
        billingResult: BillingResult,
        purchases: MutableList<Purchase>?
    ) {
        when (billingResult.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    handlePurchase(purchase)
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                // Handle cancellation
            }
            else -> {
                // Handle other errors
            }
        }
    }

    fun purchasePremium(activity: Activity, skuDetails: SkuDetails) {
        val flowParams = BillingFlowParams.newBuilder()
            .setSkuDetails(skuDetails)
            .build()

        billingClient.launchBillingFlow(activity, flowParams)
    }

    private fun handlePurchase(purchase: Purchase) {
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
            if (!purchase.isAcknowledged) {
                val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
                    .setPurchaseToken(purchase.purchaseToken)
                    .build()

                billingClient.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
                    if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                        // Purchase acknowledged, activate premium
                        subscriptionManager.activatePremiumSubscription(purchase)
                    }
                }
            } else {
                // Already acknowledged
                subscriptionManager.activatePremiumSubscription(purchase)
            }
        }
    }

    private fun querySkuDetails() {
        val params = SkuDetailsParams.newBuilder()
            .setSkusList(listOf(PREMIUM_MONTHLY, PREMIUM_YEARLY))
            .setType(BillingClient.SkuType.SUBS)
            .build()

        billingClient.querySkuDetailsAsync(params) { billingResult, skuDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                _skuDetails.value = skuDetailsList ?: emptyList()
            }
        }
    }

    private fun queryPurchases() {
        val purchasesResult = billingClient.queryPurchases(BillingClient.SkuType.SUBS)
        val purchases = purchasesResult.purchasesList

        purchases?.forEach { purchase ->
            if (purchase.isAutoRenewing) {
                subscriptionManager.activatePremiumSubscription(purchase)
            }
        }
    }
}
```

---

## Testing Strategy

### 1. Unit Tests

```kotlin
@RunWith(MockitoJUnitRunner::class)
class FlashcardViewModelTest {

    @Mock
    private lateinit var vocabularyRepository: IVocabularyRepository

    @Mock
    private lateinit var imageService: ImageService

    @Mock
    private lateinit var subscriptionManager: SubscriptionManager

    private lateinit var viewModel: FlashcardViewModel

    @Before
    fun setup() {
        viewModel = FlashcardViewModel(
            vocabularyRepository,
            imageService,
            AudioService(ApplicationProvider.getApplicationContext()),
            subscriptionManager,
            TranslationValidator()
        )
    }

    @Test
    fun `loadNextWord should update current word`() = runTest {
        // Given
        val word = VocabularyWord(
            word = "test",
            level = "A1",
            turkishTranslation = "deneme"
        )
        `when`(vocabularyRepository.getNextWord(any(), any())).thenReturn(word)

        // When
        viewModel.loadNextWord()

        // Then
        assertEquals(word, viewModel.currentWord.value)
    }

    @Test
    fun `flipCard should update UI state`() {
        // When
        viewModel.flipCard()

        // Then
        assertTrue(viewModel.uiState.value.isFlipped)
    }

    @Test
    fun `markAsKnown should update word and load next`() = runTest {
        // Given
        val word = VocabularyWord(
            word = "test",
            level = "A1",
            turkishTranslation = "deneme"
        )
        viewModel.loadWord(word)

        // When
        viewModel.markAsKnown()

        // Then
        verify(vocabularyRepository).updateWord(argThat { isKnown })
    }
}
```

### 2. UI Tests (Compose)

```kotlin
@RunWith(AndroidJUnit4::class)
class FlashcardScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun flashcard_displaysWord() {
        val word = VocabularyWord(
            word = "hello",
            level = "A1",
            turkishTranslation = "merhaba"
        )

        composeTestRule.setContent {
            FlashcardScreen(
                viewModel = FlashcardViewModel(
                    vocabularyRepository = mockk(),
                    imageService = mockk(),
                    audioService = mockk(),
                    subscriptionManager = mockk(),
                    translationValidator = TranslationValidator()
                ).apply {
                    _currentWord.value = word
                }
            )
        }

        composeTestRule.onNodeWithText("hello").assertIsDisplayed()
    }

    @Test
    fun clickingFlashcard_flipsCard() {
        composeTestRule.setContent {
            FlashcardScreen(
                viewModel = mockk(relaxed = true)
            )
        }

        composeTestRule
            .onNodeWithTag("flashcard")
            .performClick()

        verify { viewModel.flipCard() }
    }
}
```

---

## Deployment Considerations

### 1. Gradle Configuration

```kotlin
// app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("kotlin-kapt")
    id("dagger.hilt.android.plugin")
    id("kotlin-parcelize")
}

android {
    namespace = "com.praxisen"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.praxisen"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Compose BOM
    implementation(platform("androidx.compose:compose-bom:2023.10.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")

    // Activity Compose
    implementation("androidx.activity:activity-compose:1.8.1")

    // Navigation Compose
    implementation("androidx.navigation:navigation-compose:2.7.5")

    // ViewModel Compose
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.48.1")
    kapt("com.google.dagger:hilt-compiler:2.48.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")

    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Billing
    implementation("com.android.billingclient:billing:6.1.0")

    // Image Loading
    implementation("io.coil-kt:coil-compose:2.5.0")

    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.7.0")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.1.0")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")

    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")

    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
```

### 2. ProGuard Rules

```proguard
# Keep Room entities
-keep class com.praxisen.data.database.entity.** { *; }

# Keep Hilt generated classes
-keep class dagger.hilt.** { *; }
-keep class * extends dagger.hilt.android.HiltAndroidApp

# Keep Billing classes
-keep class com.android.billingclient.api.** { *; }

# Keep serialization classes
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Keep coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
```

### 3. Release Checklist

- [ ] Configure signing keys
- [ ] Set up Google Play Console
- [ ] Create app listings with screenshots
- [ ] Prepare store description
- [ ] Set up in-app purchase products
- [ ] Configure privacy policy
- [ ] Test release build thoroughly
- [ ] Enable code shrinking and obfuscation
- [ ] Verify all permissions are declared
- [ ] Test on multiple devices/API levels
- [ ] Prepare promotional materials
- [ ] Set up crash reporting (Firebase Crashlytics)
- [ ] Configure analytics (Firebase Analytics)

---

## Performance Optimizations

### 1. Database Optimizations

```kotlin
// Use indexes for frequently queried columns
@Entity(
    tableName = "vocabulary_words",
    indices = [
        Index(value = ["word"], unique = true),
        Index(value = ["level"]),
        Index(value = ["is_known", "repetitions"]),
        Index(value = ["last_reviewed_date"])
    ]
)

// Batch operations
suspend fun updateWordsBatch(words: List<VocabularyWord>) {
    database.withTransaction {
        words.forEach { word ->
            vocabularyDao.updateWord(word)
        }
    }
}

// Use Flow for reactive updates
@Query("SELECT * FROM vocabulary_words WHERE is_known = 1")
fun getKnownWordsFlow(): Flow<List<VocabularyWord>>
```

### 2. Image Loading Optimizations

```kotlin
// Configure Coil for optimal performance
@Composable
fun rememberImageLoader(): ImageLoader {
    val context = LocalContext.current
    return remember {
        ImageLoader.Builder(context)
            .memoryCache {
                MemoryCache.Builder(context)
                    .maxSizePercent(0.25)
                    .build()
            }
            .diskCache {
                DiskCache.Builder()
                    .directory(context.cacheDir.resolve("image_cache"))
                    .maxSizeBytes(100L * 1024 * 1024) // 100MB
                    .build()
            }
            .respectCacheHeaders(false)
            .build()
    }
}
```

### 3. Compose Performance

```kotlin
// Use remember for expensive calculations
@Composable
fun FlashcardFront(
    word: VocabularyWord,
    modifier: Modifier = Modifier
) {
    val formattedDate = remember(word.lastReviewedDate) {
        word.lastReviewedDate?.let {
            SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
                .format(Date(it))
        }
    }

    // Use derivedStateOf for expensive state calculations
    val displayText by remember {
        derivedStateOf {
            "${word.word} (${word.level})"
        }
    }

    Text(
        text = displayText,
        modifier = modifier
    )
}

// Use LazyColumn for lists
@Composable
fun WordList(
    words: List<VocabularyWord>,
    modifier: Modifier = Modifier
) {
    LazyColumn(modifier = modifier) {
        items(
            count = words.size,
            key = { index -> words[index].word }
        ) { index ->
            WordItem(word = words[index])
        }
    }
}
```

---

## Migration Checklist

### Phase 1: Foundation (Week 1-2)
- [ ] Set up Android project structure
- [ ] Configure dependencies (Hilt, Room, Compose)
- [ ] Create data models (Entities)
- [ ] Set up database with Room
- [ ] Implement basic repository pattern
- [ ] Create dependency injection modules

### Phase 2: Core Features (Week 3-4)
- [ ] Implement Spaced Repetition algorithm
- [ ] Create ViewModel for flashcards
- [ ] Build Compose UI for flashcard screen
- [ ] Implement basic navigation
- [ ] Add gesture handling (swipe, tap)
- [ ] Integrate image loading service

### Phase 3: Advanced Features (Week 5-6)
- [ ] Implement subscription system
- [ ] Add Google Play Billing
- [ ] Create settings screen
- [ ] Implement stats tracking
- [ ] Add audio/TTS functionality
- [ ] Create premium features

### Phase 4: Polish & Testing (Week 7-8)
- [ ] Write unit and integration tests
- [ ] Optimize performance
- [ ] Add animations and transitions
- [ ] Implement error handling
- [ ] Add crash reporting
- [ ] Prepare for release

### Phase 5: Launch (Week 9-10)
- [ ] Final testing on multiple devices
- [ ] Prepare store listing
- [ ] Create promotional materials
- [ ] Submit to Google Play Store
- [ ] Monitor initial feedback
- [ ] Plan v1.1 features

This comprehensive guide provides everything needed to successfully port the PraxisEn iOS app to Android using Kotlin and modern Android development practices.