import Foundation
import SwiftData
import SQLite3

/// Manages database initialization, importing, and setup for the app
@MainActor
class DatabaseManager {
    // MARK: - Singleton

    static let shared = DatabaseManager()

    private init() {}

    // MARK: - Database Setup

    /// Sets up the database on first launch by copying from bundle to Documents
    func setupDatabasesIfNeeded() async throws {
        let vocabularySetup = try await setupVocabularyDatabase()
        let sentencesSetup = try await setupSentencesDatabase()

        print("📚 Database setup completed:")
        print("  - Vocabulary: \(vocabularySetup ? "✅ Initialized" : "ℹ️  Already exists")")
        print("  - Sentences: \(sentencesSetup ? "✅ Initialized" : "ℹ️  Already exists")")
    }

    /// Copies vocabulary.db from bundle to Documents if not already present
    private func setupVocabularyDatabase() async throws -> Bool {
        let fileName = "vocabulary.db"
        let documentsURL = try getDocumentsDirectory()
        let destinationURL = documentsURL.appendingPathComponent(fileName)

        // Check if already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return false // Already set up
        }

        // Copy from bundle
        guard let bundleURL = Bundle.main.url(forResource: "vocabulary", withExtension: "db") else {
            throw DatabaseError.bundleFileNotFound(fileName)
        }

        try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
        print("✅ Copied \(fileName) to Documents directory")

        return true
    }

    /// Copies sentences.db from bundle to Documents if not already present
    private func setupSentencesDatabase() async throws -> Bool {
        let fileName = "sentences.db"
        let documentsURL = try getDocumentsDirectory()
        let destinationURL = documentsURL.appendingPathComponent(fileName)

        // Check if already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return false // Already set up
        }

        // Copy from bundle
        guard let bundleURL = Bundle.main.url(forResource: "sentences", withExtension: "db") else {
            throw DatabaseError.bundleFileNotFound(fileName)
        }

        try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
        print("✅ Copied \(fileName) to Documents directory")

        return true
    }

    // MARK: - Data Import

    /// Imports vocabulary data from SQLite into SwiftData
    func importVocabularyToSwiftData(modelContext: ModelContext) async throws -> Int {
        let documentsURL = try getDocumentsDirectory()
        let dbURL = documentsURL.appendingPathComponent("vocabulary.db")

        guard FileManager.default.fileExists(atPath: dbURL.path) else {
            throw DatabaseError.databaseNotFound("vocabulary.db")
        }

        var db: OpaquePointer?
        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
            throw DatabaseError.cannotOpenDatabase
        }
        defer { sqlite3_close(db) }

        // Check if data already imported
        let descriptor = FetchDescriptor<VocabularyWord>()
        let existingCount = try modelContext.fetchCount(descriptor)

        if existingCount > 0 {
            print("ℹ️  Vocabulary already imported (\(existingCount) words)")
            return existingCount
        }

        // Query all vocabulary
        let query = "SELECT word, level, definition, turkish_translation, example_sentence, part_of_speech, related_forms, synonyms, antonyms, collocations FROM vocabulary"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryPreparationFailed
        }
        defer { sqlite3_finalize(statement) }

        var importedCount = 0

        while sqlite3_step(statement) == SQLITE_ROW {
            let word = String(cString: sqlite3_column_text(statement, 0))
            let level = String(cString: sqlite3_column_text(statement, 1))
            let definition = String(cString: sqlite3_column_text(statement, 2))
            let turkishTranslation = String(cString: sqlite3_column_text(statement, 3))
            let exampleSentence = String(cString: sqlite3_column_text(statement, 4))
            let partOfSpeech = String(cString: sqlite3_column_text(statement, 5))
            let relatedForms = String(cString: sqlite3_column_text(statement, 6))
            let synonyms = String(cString: sqlite3_column_text(statement, 7))
            let antonyms = String(cString: sqlite3_column_text(statement, 8))
            let collocations = String(cString: sqlite3_column_text(statement, 9))

            let vocabularyWord = VocabularyWord(
                word: word,
                level: level,
                definition: definition,
                turkishTranslation: turkishTranslation,
                exampleSentence: exampleSentence,
                partOfSpeech: partOfSpeech,
                relatedForms: relatedForms,
                synonyms: synonyms,
                antonyms: antonyms,
                collocations: collocations
            )

            modelContext.insert(vocabularyWord)
            importedCount += 1

            // Save in batches
            if importedCount % 500 == 0 {
                try modelContext.save()
            }
        }

        // Final save
        try modelContext.save()

        print("✅ Imported \(importedCount) vocabulary words to SwiftData")
        return importedCount
    }

    /// Imports sentence pairs from SQLite into SwiftData (with pagination support)
    func importSentencesToSwiftData(
        modelContext: ModelContext,
        limit: Int = 10000,
        offset: Int = 0
    ) async throws -> Int {
        let documentsURL = try getDocumentsDirectory()
        let dbURL = documentsURL.appendingPathComponent("sentences.db")

        guard FileManager.default.fileExists(atPath: dbURL.path) else {
            throw DatabaseError.databaseNotFound("sentences.db")
        }

        var db: OpaquePointer?
        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
            throw DatabaseError.cannotOpenDatabase
        }
        defer { sqlite3_close(db) }

        // Query sentences with pagination
        let query = """
            SELECT turkish_id, turkish_text, english_id, english_text, difficulty_level
            FROM sentences
            LIMIT \(limit) OFFSET \(offset)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryPreparationFailed
        }
        defer { sqlite3_finalize(statement) }

        var importedCount = 0

        while sqlite3_step(statement) == SQLITE_ROW {
            let turkishId = Int(sqlite3_column_int(statement, 0))
            let turkishText = String(cString: sqlite3_column_text(statement, 1))
            let englishId = Int(sqlite3_column_int(statement, 2))
            let englishText = String(cString: sqlite3_column_text(statement, 3))
            let difficultyLevel = String(cString: sqlite3_column_text(statement, 4))

            let sentencePair = SentencePair(
                turkishId: turkishId,
                turkishText: turkishText,
                englishId: englishId,
                englishText: englishText,
                difficultyLevel: difficultyLevel
            )

            modelContext.insert(sentencePair)
            importedCount += 1

            // Save in batches
            if importedCount % 1000 == 0 {
                try modelContext.save()
            }
        }

        // Final save
        try modelContext.save()

        print("✅ Imported \(importedCount) sentence pairs to SwiftData")
        return importedCount
    }

    // MARK: - Database Queries (Direct SQLite)

    /// Searches for sentences containing a word directly from SQLite (faster than SwiftData for large datasets)
    func searchSentences(
        containing word: String,
        limit: Int = 50
    ) async throws -> [SentencePair] {
        let documentsURL = try getDocumentsDirectory()
        let dbURL = documentsURL.appendingPathComponent("sentences.db")

        print("🗄️ Opening database at: \(dbURL.path)")

        var db: OpaquePointer?
        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
            print("❌ Failed to open database")
            throw DatabaseError.cannotOpenDatabase
        }
        defer { sqlite3_close(db) }

        // Search only in English text (fetch more results, will filter in Swift)
        let query = """
            SELECT turkish_id, turkish_text, english_id, english_text, difficulty_level
            FROM sentences
            WHERE english_text LIKE ? COLLATE NOCASE
            LIMIT ?
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryPreparationFailed
        }
        defer { sqlite3_finalize(statement) }

        let searchPattern = "%\(word)%"
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, (searchPattern as NSString).utf8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(limit * 5)) // Fetch more for filtering

        print("🔎 Searching English text with pattern: '\(searchPattern)'")

        var allResults: [SentencePair] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            let turkishId = Int(sqlite3_column_int(statement, 0))
            let turkishText = String(cString: sqlite3_column_text(statement, 1))
            let englishId = Int(sqlite3_column_int(statement, 2))
            let englishText = String(cString: sqlite3_column_text(statement, 3))
            let difficultyLevel = String(cString: sqlite3_column_text(statement, 4))

            allResults.append(SentencePair(
                turkishId: turkishId,
                turkishText: turkishText,
                englishId: englishId,
                englishText: englishText,
                difficultyLevel: difficultyLevel
            ))
        }

        print("📥 SQL returned \(allResults.count) sentences, filtering for whole word matches...")

        // Filter for whole word matches using Swift regex
        let wordPattern = try! NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b", options: .caseInsensitive)
        let results = allResults.filter { sentence in
            let range = NSRange(sentence.englishText.startIndex..., in: sentence.englishText)
            return wordPattern.firstMatch(in: sentence.englishText, range: range) != nil
        }.prefix(limit)

        print("✅ Found \(results.count) whole-word matches for '\(word)'")
        return Array(results)
    }

    /// Gets random sentences for practice
    func getRandomSentences(count: Int = 10, level: String? = nil) async throws -> [SentencePair] {
        let documentsURL = try getDocumentsDirectory()
        let dbURL = documentsURL.appendingPathComponent("sentences.db")

        var db: OpaquePointer?
        guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
            throw DatabaseError.cannotOpenDatabase
        }
        defer { sqlite3_close(db) }

        var query = """
            SELECT turkish_id, turkish_text, english_id, english_text, difficulty_level
            FROM sentences
        """

        if let level = level {
            query += " WHERE difficulty_level = '\(level)'"
        }

        query += " ORDER BY RANDOM() LIMIT \(count)"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryPreparationFailed
        }
        defer { sqlite3_finalize(statement) }

        var results: [SentencePair] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            let turkishId = Int(sqlite3_column_int(statement, 0))
            let turkishText = String(cString: sqlite3_column_text(statement, 1))
            let englishId = Int(sqlite3_column_int(statement, 2))
            let englishText = String(cString: sqlite3_column_text(statement, 3))
            let difficultyLevel = String(cString: sqlite3_column_text(statement, 4))

            results.append(SentencePair(
                turkishId: turkishId,
                turkishText: turkishText,
                englishId: englishId,
                englishText: englishText,
                difficultyLevel: difficultyLevel
            ))
        }

        return results
    }

    // MARK: - Helper Methods

    private func getDocumentsDirectory() throws -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw DatabaseError.documentsDirectoryNotFound
        }
        return documentsURL
    }

    /// Checks if databases are properly set up
    func isDatabaseSetupComplete() -> Bool {
        guard let documentsURL = try? getDocumentsDirectory() else { return false }

        let vocabularyExists = FileManager.default.fileExists(
            atPath: documentsURL.appendingPathComponent("vocabulary.db").path
        )
        let sentencesExist = FileManager.default.fileExists(
            atPath: documentsURL.appendingPathComponent("sentences.db").path
        )

        return vocabularyExists && sentencesExist
    }

    /// Gets database file sizes
    func getDatabaseSizes() throws -> (vocabulary: Int64, sentences: Int64) {
        let documentsURL = try getDocumentsDirectory()

        let vocabURL = documentsURL.appendingPathComponent("vocabulary.db")
        let sentencesURL = documentsURL.appendingPathComponent("sentences.db")

        let vocabSize = try FileManager.default.attributesOfItem(atPath: vocabURL.path)[.size] as? Int64 ?? 0
        let sentencesSize = try FileManager.default.attributesOfItem(atPath: sentencesURL.path)[.size] as? Int64 ?? 0

        return (vocabSize, sentencesSize)
    }
}

// MARK: - Error Types

enum DatabaseError: LocalizedError {
    case bundleFileNotFound(String)
    case databaseNotFound(String)
    case cannotOpenDatabase
    case queryPreparationFailed
    case documentsDirectoryNotFound

    var errorDescription: String? {
        switch self {
        case .bundleFileNotFound(let fileName):
            return "Database file '\(fileName)' not found in app bundle"
        case .databaseNotFound(let fileName):
            return "Database '\(fileName)' not found in Documents directory"
        case .cannotOpenDatabase:
            return "Failed to open SQLite database"
        case .queryPreparationFailed:
            return "Failed to prepare SQL query"
        case .documentsDirectoryNotFound:
            return "Documents directory not accessible"
        }
    }
}
