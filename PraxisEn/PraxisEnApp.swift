//
//  PraxisEnApp.swift
//  PraxisEn
//
//  Created by Akinalp Fidan on 10.11.2025.
//

import SwiftUI
import SwiftData

@main
struct PraxisEnApp: App {
    // MARK: - SwiftData Container

    var sharedModelContainer: ModelContainer = {
        // Configure SwiftData schema with our models
        let schema = Schema([
            VocabularyWord.self,
            SentencePair.self,
            UserSettings.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            ////print("✅ SwiftData ModelContainer initialized")
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Setup databases on first launch BEFORE any other operations
                    await setupDatabasesOnFirstLaunch()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Database Setup

    @MainActor
    private func setupDatabasesOnFirstLaunch() async {
        do {
            // Step 1: Copy SQLite databases from bundle to Documents
            if !DatabaseManager.shared.isDatabaseSetupComplete() {
                ////print("🚀 First launch detected - setting up databases...")
                try await DatabaseManager.shared.setupDatabasesIfNeeded()

                let sizes = try DatabaseManager.shared.getDatabaseSizes()
                let vocabMB = Double(sizes.vocabulary) / 1_048_576
                let sentencesMB = Double(sizes.sentences) / 1_048_576
               // //print("📊 Database sizes:")
                ////print("   - Vocabulary: \(String(format: "%.2f", vocabMB)) MB")
               // //print("   - Sentences: \(String(format: "%.2f", sentencesMB)) MB")
            } else {
               // //print("ℹ️  Databases already set up")
            }

            // Step 2: Import vocabulary from SQLite to SwiftData
            let modelContext = sharedModelContainer.mainContext

            // Check if already imported
            let descriptor = FetchDescriptor<VocabularyWord>()
            let existingCount = try modelContext.fetchCount(descriptor)

            if existingCount == 0 {
               // //print("📥 Importing vocabulary to SwiftData...")
                let importedCount = try await DatabaseManager.shared.importVocabularyToSwiftData(modelContext: modelContext)
              //  //print("✅ Imported \(importedCount) words to SwiftData")
            } else {
              //  //print("ℹ️  Vocabulary already imported (\(existingCount) words)")
            }

        } catch {
           // //print("❌ Database setup failed: \(error.localizedDescription)")
        }
    }
}
