# PraxisEn Database Setup Guide

Complete guide for setting up the Oxford 3000 vocabulary and Turkish-English sentence databases for your iOS language learning app.

## 📊 Data Overview

### Generated Databases

| Database | Size | Records | Description |
|----------|------|---------|-------------|
| **vocabulary.db** | ~1 MB | 3,354 words | Oxford 3000 words with definitions, translations, CEFR levels |
| **sentences.db** | ~153 MB | 714,475 pairs | Turkish-English sentence pairs from Tatoeba corpus |

### CEFR Level Distribution

**Vocabulary:**
- 🟢 A1 (Beginner): 811 words (24.2%)
- 🔵 A2 (Elementary): 693 words (20.7%)
- 🟠 B1 (Intermediate): 585 words (17.4%)
- 🔴 B2 (Upper Intermediate): 1,265 words (37.7%)

**Sentences:**
- 🟢 A1: ~499,024 sentences (short, simple)
- 🔵 A2: ~204,122 sentences (moderate length)
- 🟠 B1: ~9,728 sentences (longer)
- 🔴 B2: ~1,601 sentences (complex)

## 🚀 Quick Start

### 1. Generate Databases

```bash
# Install Python dependencies
pip3 install pandas pdfplumber pypdf2

# Run the complete generation script
python3 generate_sqlite_databases.py
```

This will create:
- `vocabulary.db` - Vocabulary database
- `sentences.db` - Sentence pairs database

### 2. Add to Xcode Project

1. **Add database files to your Xcode project:**
   - Drag `vocabulary.db` and `sentences.db` into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to your app target

2. **Add to Build Phases:**
   - Go to Project Settings → Build Phases → Copy Bundle Resources
   - Ensure both `.db` files are listed

### 3. Add Swift Files

Add these files to your project:

```
PraxisEn/
├── Models/
│   ├── VocabularyWord.swift
│   └── SentencePair.swift
├── Helpers/
│   └── DatabaseManager.swift
└── PraxisEnApp.swift
```

### 4. Run Your App

On first launch, the app will automatically:
1. Copy databases from bundle to Documents directory
2. Set up SwiftData models
3. Ready to query!

## 📝 Data Processing Steps

### Step 1: Extract Word Levels from PDF

```bash
python3 parse_oxford_final.py
```

Output: `oxford3000_word_levels.csv` (2,928 words with CEFR levels)

### Step 2: Merge with Vocabulary CSV

```bash
python3 merge_vocabulary_data.py
```

Output: `vocabulary_with_levels.csv` (3,354 words with full metadata + levels)

### Step 3: Generate SQLite Databases

```bash
python3 generate_sqlite_databases.py
```

Output: `vocabulary.db` and `sentences.db`

## 💻 Usage in Swift

### Query Vocabulary

```swift
import SwiftData

// Query by level
@Query(filter: #Predicate<VocabularyWord> { $0.level == "A1" })
var beginnerWords: [VocabularyWord]

// Query by search term
@Query var allWords: [VocabularyWord]
var searchedWords = allWords.filter {
    $0.word.contains(searchTerm) ||
    $0.turkishTranslation.contains(searchTerm)
}

// Get random word
let randomWord = try await modelContext.fetch(
    FetchDescriptor<VocabularyWord>()
).randomElement()
```

### Search Sentences (Direct SQLite - Faster)

```swift
// Search for sentences containing a word
let sentences = try await DatabaseManager.shared.searchSentences(
    containing: "merhaba",
    limit: 50
)

// Get random sentences for practice
let randomSentences = try await DatabaseManager.shared.getRandomSentences(
    count: 10,
    level: "A1"
)
```

### Access Vocabulary Properties

```swift
let word = VocabularyWord.sample
 
```

### Track Learning Progress

```swift
// Mark word as learned
vocabularyWord.toggleLearned()

// Track reviews
vocabularyWord.markAsReviewed()

// Reset progress
vocabularyWord.resetProgress()
```

## 🗂️ Database Schema

### Vocabulary Table

```sql
CREATE TABLE vocabulary (
    id INTEGER PRIMARY KEY,
    word TEXT UNIQUE NOT NULL,
    level TEXT NOT NULL,                 -- A1, A2, B1, B2
    definition TEXT,
    turkish_translation TEXT,
    example_sentence TEXT,
    part_of_speech TEXT,
    related_forms TEXT,                  -- Comma-separated
    synonyms TEXT,                       -- Comma-separated
    antonyms TEXT,                       -- Comma-separated
    collocations TEXT,                   -- Comma-separated
    is_learned INTEGER DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    last_reviewed_date TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### Sentences Table

```sql
CREATE TABLE sentences (
    id INTEGER PRIMARY KEY,
    turkish_id INTEGER,                  -- Tatoeba sentence ID
    turkish_text TEXT NOT NULL,
    english_id INTEGER,                  -- Tatoeba sentence ID
    english_text TEXT NOT NULL,
    is_favorite INTEGER DEFAULT 0,
    difficulty_level TEXT,               -- A1, A2, B1, B2 (estimated)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

## 🎯 Use Cases

### 1. Vocabulary Flashcards

```swift
struct FlashcardView: View {
    @Query(filter: #Predicate<VocabularyWord> { !$0.isLearned })
    var unlearnedWords: [VocabularyWord]

    var body: some View {
        if let word = unlearnedWords.randomElement() {
            VStack {
                Text(word.word)
                    .font(.largeTitle)
                Text(word.turkishTranslation)
                    .font(.title2)
            }
        }
    }
}
```

### 2. Search Sentences for Context

```swift
func showWordInContext(word: String) async {
    let sentences = try await DatabaseManager.shared.searchSentences(
        containing: word,
        limit: 20
    )

    
}
```

### 3. Level-Based Learning

```swift
struct LevelSelector: View {
    @Query var words: [VocabularyWord]

    func wordCount(for level: String) -> Int {
        words.filter { $0.level == level }.count
    }

    var body: some View {
        List {
            NavigationLink("A1 (\(wordCount(for: "A1")) words)") {
                WordListView(level: "A1")
            }
            NavigationLink("A2 (\(wordCount(for: "A2")) words)") {
                WordListView(level: "A2")
            }
            // ...
        }
    }
}
```

### 4. Daily Random Words

```swift
func getDailyWords(count: Int = 10) async -> [VocabularyWord] {
    let descriptor = FetchDescriptor<VocabularyWord>(
        sortBy: [SortDescriptor(\.word)]
    )

    let allWords = try await modelContext.fetch(descriptor)

    // Use date-based seed for consistent daily selection
    let today = Calendar.current.startOfDay(for: Date())
    let seed = today.timeIntervalSince1970

    var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
    return allWords.shuffled(using: &rng).prefix(count).map { $0 }
}
```

## 🔍 Performance Tips

### 1. Use Direct SQLite for Large Queries

For searching through 714K sentences, direct SQLite queries are much faster than SwiftData:

```swift
// ✅ Fast: Direct SQLite
let results = try await DatabaseManager.shared.searchSentences(
    containing: "merhaba",
    limit: 50
)

// ❌ Slow: Loading all sentences to SwiftData
@Query var allSentences: [SentencePair]  // Don't do this!
```

### 2. Import Only Vocabulary to SwiftData

```swift
// ✅ Good: Import small vocabulary dataset (3K words)
try await DatabaseManager.shared.importVocabularyToSwiftData(modelContext: context)

// ❌ Avoid: Importing all 714K sentences takes too long
// Use direct SQLite queries instead
```

### 3. Index Your Queries

The databases come with indexes on:
- `word` column in vocabulary
- `level` column in vocabulary
- `turkish_text` and `english_text` in sentences
- Full-text search (FTS5) for sentences

## 📦 File Structure

```
PraxisEn/
├── Data/
│   ├── vocabulary.db                           # 1 MB
│   └── sentences.db                            # 153 MB
├── Models/
│   ├── VocabularyWord.swift                    # SwiftData model
│   └── SentencePair.swift                      # SwiftData model
├── Helpers/
│   └── DatabaseManager.swift                   # Import & query helper
├── Scripts/ (Python - build time)
│   ├── parse_oxford_final.py                   # PDF → CSV
│   ├── merge_vocabulary_data.py                # Merge CSVs
│   └── generate_sqlite_databases.py            # CSV → SQLite
└── Source Data/
    ├── The_Oxford_3000.pdf
    ├── oxford3000_vocabulary_with_collocations_and_definitions_datasets.csv
    └── Türkçe-İngilizce dillerindeki cümle eşleri - 2025-11-10.tsv
```

## 🎨 Suggested Features

1. **Spaced Repetition System** - Use `reviewCount` and `lastReviewedDate`
2. **Daily Challenges** - Random words/sentences based on level
3. **Progress Tracking** - Visualize `isLearned` percentage per level
4. **Favorite Sentences** - Toggle `isFavorite` for practice
5. **Context Search** - Find example sentences for vocabulary
6. **Collocation Practice** - Quiz on word combinations
7. **Difficulty Progression** - Unlock next level when current is 80% learned

## 🐛 Troubleshooting

### Database Not Found

```
Error: Database file 'vocabulary.db' not found in app bundle
```

**Solution:** Make sure databases are added to "Copy Bundle Resources" in Build Phases

### SwiftData Schema Mismatch

```
Error: Could not create ModelContainer
```

**Solution:** Delete app from simulator/device to reset SwiftData store

### Slow Sentence Search

**Solution:** Use `DatabaseManager.shared.searchSentences()` instead of SwiftData queries

## 📊 Statistics

- **Total Vocabulary**: 3,354 words
- **Total Sentences**: 714,475 pairs
- **Coverage**: Oxford 3000 core words (98% match rate)
- **Database Size**: ~154 MB total
- **First Launch Import**: <1 second (copy only)
- **Memory Footprint**: ~10-20 MB during queries

## 🤝 Credits

- **Oxford 3000**: Oxford University Press
- **Tatoeba Corpus**: Community-contributed translations
- **CEFR Levels**: Common European Framework of Reference for Languages

## 📄 License

The vocabulary data is from Oxford University Press under their terms.
The sentence pairs are from Tatoeba under CC BY 2.0 FR license.

---

**Built with ❤️ for language learners**

For questions or issues, check the Swift files for inline documentation.
