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
                // If databases already set up, check if sentences need to be imported after ODR
                if odrManager.checkFullContentAvailability() {
                    try await DatabaseManager.shared.setupDatabasesIfNeeded()
                }
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
            if !odrManager.checkFullContentAvailability() {
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
            // Preload seed images
            group.addTask {
                // Preload common seed word images for immediate display
                let seedWords = ["hello", "yes", "no", "thank", "please", "water", "food"]
                for seedWord in seedWords {
                    _ = await ImageService.shared.fetchPhotoSafely(for: seedWord)
                }
            }

            // Preload seed audio
            group.addTask {
                // Note: AudioManager.play is synchronous, no need for await
                let seedWords = ["hello", "yes", "no", "thank", "please", "water", "food"]
                for seedWord in seedWords {
                    AudioManager.shared.play(word: seedWord)
                    // Immediately stop to just cache the audio
                    AudioManager.shared.stop()
                }
            }
        }
    }
}
