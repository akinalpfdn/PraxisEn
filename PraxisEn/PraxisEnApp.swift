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
                    // Initialize ODR system and setup databases on first launch
                    await initializeAppOnFirstLaunch()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - App Initialization

    @MainActor
    private func initializeAppOnFirstLaunch() async {
        do {
            // Step 1: Initialize ODR system
            await odrManager.initializeODR()

            // Step 2: Setup databases with ODR awareness
            if !DatabaseManager.shared.isDatabaseSetupComplete() {
                try await DatabaseManager.shared.setupDatabasesWithODR()
            } else {
                // Note: sentences.db is handled by ODR, no need to setupDatabasesIfNeeded()
            }

            // Step 3: Import vocabulary from SQLite to SwiftData
            let modelContext = sharedModelContainer.mainContext
            let descriptor = FetchDescriptor<VocabularyWord>()
            let existingCount = try modelContext.fetchCount(descriptor)

            if existingCount == 0 {
                let importedCount = try await DatabaseManager.shared.importVocabularyToSwiftData(modelContext: modelContext)
            }

            // Step 4: Preload seed content for immediate availability
            await preloadSeedContent()

            // Step 5: Start silent background download if not complete
            if await !odrManager.checkFullContentAvailability() {
                Task {
                    do {
                        try await odrManager.requestFullContentDownload()
                    } catch {
                        // Silently handle download errors - user can continue with seed content
                        // Error is logged automatically in ODRManager
                    }
                }
            }

        } catch {
            // Handle initialization errors gracefully
        }
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
