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
    // MARK: - ODR Manager

    @StateObject private var odrManager = ODRManager.shared

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
                    print("🔥 PraxisEnApp.task started")
                    // Initialize ODR system and setup databases on first launch
                    await initializeAppOnFirstLaunch()
                    print("🔥 PraxisEnApp.task completed")
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - App Initialization

    @MainActor
    private func initializeAppOnFirstLaunch() async {
        print("🔥 initializeAppOnFirstLaunch started")

        do {
            // Step 1: Initialize ODR system
            print("🔥 Step 1: Initializing ODR system")
            await odrManager.initializeODR()
            print("🔥 ODR system initialized")

            // Step 2: Setup databases with ODR awareness
            print("🔥 Step 2: Checking database setup")
            let dbSetupComplete = DatabaseManager.shared.isDatabaseSetupComplete()
            print("🔥 Database setup complete: \(dbSetupComplete)")

            if !DatabaseManager.shared.isDatabaseSetupComplete() {
                print("🔥 Setting up databases with ODR")
                try await DatabaseManager.shared.setupDatabasesWithODR()
                print("🔥 Database setup with ODR completed")
            } else {
                print("🔥 Databases already set up")
                // Note: sentences.db is handled by ODR, no need to setupDatabasesIfNeeded()
            }

            // Step 3: Import vocabulary from SQLite to SwiftData
            print("🔥 Step 3: Importing vocabulary")
            let modelContext = sharedModelContainer.mainContext
            let descriptor = FetchDescriptor<VocabularyWord>()
            let existingCount = try modelContext.fetchCount(descriptor)
            print("🔥 Existing vocabulary count: \(existingCount)")

            if existingCount == 0 {
                print("📥 Importing vocabulary to SwiftData...")
                let importedCount = try await DatabaseManager.shared.importVocabularyToSwiftData(modelContext: modelContext)
                print("✅ Imported \(importedCount) words to SwiftData")
            } else {
                print("ℹ️ Vocabulary already imported (\(existingCount) words)")
            }

            // Step 4: Preload seed content for immediate availability
            print("🔥 Step 4: Preloading seed content")
            await preloadSeedContent()
            print("🔥 Seed content preloaded")

            // Step 5: Start silent background download if not complete
            print("🔥 Step 5: Checking ODR download")
            if !odrManager.checkFullContentAvailability() {
                print("🔥 Starting background download")
                Task {
                    do {
                        try await odrManager.requestFullContentDownload()
                    } catch {
                        // Silently handle download errors - user can continue with seed content
                        // Error is logged automatically in ODRManager
                    }
                }
            } else {
                print("🔥 Full content already available")
            }

        } catch {
            print("❌ initializeAppOnFirstLaunch error: \(error)")
            // Handle initialization errors gracefully
        }

        print("🔥 initializeAppOnFirstLaunch completed")
    }

    // MARK: - Seed Content Preloading

    private func preloadSeedContent() async {
        await withTaskGroup(of: Void.self) { group in
            // Get the proper 20 seed words from ODRManager
            let seedWords = Array(odrManager.getSeedWords())

            // Preload seed images
            group.addTask {
                // Preload all 20 seed word images for immediate display
                for seedWord in seedWords {
                    _ = await ImageService.shared.fetchPhotoSafely(for: seedWord)
                }
            }

            // Skip aggressive audio preloading to avoid HALC errors
            // Audio files will be loaded on-demand when user actually plays them
            // This prevents Core Audio HAL initialization issues in simulator
            group.addTask {
                // Just ensure audio session is configured without playing sounds
                // AudioManager already configures audio session in init
            }
        }
    }
}
