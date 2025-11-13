//
//  LearnedFlashcardViewModel.swift
//  PraxisEn
//
//  Created by Akinalp Fidan on 13.11.2025.
//

import SwiftUI
import SwiftData
@_implementationOnly internal import Combine

@MainActor
class LearnedFlashcardViewModel: ObservableObject {
    @Published var currentWord: VocabularyWord?
    @Published var isFlipped: Bool = false
    @Published var currentPhoto: UIImage?
    @Published var isLoadingPhoto: Bool = false
    @Published var exampleSentences: [SentencePair] = []

    // Preview words for background cards
    @Published var nextWordPreview: VocabularyWord?
    @Published var previousWordPreview: VocabularyWord?
    @Published var nextWordPreviewPhoto: UIImage?
    @Published var previousWordPreviewPhoto: UIImage?

    private var allLearnedWords: [VocabularyWord] = []
    private var currentIndex: Int = 0
    
    private let modelContext: ModelContext
    private let unsplashService = UnsplashService()
    private let databaseManager = DatabaseManager.shared
    private let audioManager = AudioManager.shared

    init(modelContext: ModelContext, wordID: String, allLearnedWordIDs: [String]) {
        self.modelContext = modelContext

        // Fetch all learned words based on the provided IDs
        let predicate = #Predicate<VocabularyWord> { word in
            allLearnedWordIDs.contains(word.word)
        }
        let descriptor = FetchDescriptor<VocabularyWord>(predicate: predicate, sortBy: [SortDescriptor(\.word)])

        do {
            let fetchedWords = try modelContext.fetch(descriptor)
            // Shuffle the words for random flashcard order
            self.allLearnedWords = fetchedWords.shuffled()
        } catch {
            print("Failed to fetch learned words: \(error)")
            self.allLearnedWords = []
        }

        // Find the starting index and word (search in shuffled array)
        if let startingIndex = allLearnedWords.firstIndex(where: { $0.word == wordID }) {
            self.currentIndex = startingIndex
            self.currentWord = allLearnedWords[startingIndex]
        } else if !allLearnedWords.isEmpty {
            self.currentIndex = 0
            self.currentWord = allLearnedWords[0]
        }
        
        // Load initial data
        Task {
            await loadPhotoForCurrentWord()
            await loadExamplesForCurrentWord()
            await updatePreviews()
        }
    }

    // MARK: - Public Methods

    func nextWord() async {
        guard !allLearnedWords.isEmpty else { return }
        currentIndex = (currentIndex + 1) % allLearnedWords.count
        updateCurrentWord()
        await loadDependencies()
    }

    func previousWord() async {
        guard !allLearnedWords.isEmpty else { return }
        currentIndex = (currentIndex - 1 + allLearnedWords.count) % allLearnedWords.count
        updateCurrentWord()
        await loadDependencies()
    }

    func toggleFlip() {
        isFlipped.toggle()
    }
    
    func playWordAudio() {
        guard let word = currentWord?.word else { return }
        audioManager.play(word: word)
    }

    // MARK: - Private Helpers

    private func updateCurrentWord() {
        guard currentIndex < allLearnedWords.count else { return }
        currentWord = allLearnedWords[currentIndex]
        isFlipped = false
    }
    
    private func loadDependencies() async {
        await loadPhotoForCurrentWord()
        await loadExamplesForCurrentWord()
        await updatePreviews()
    }

    private func loadPhotoForCurrentWord() async {
        isLoadingPhoto = true
        currentPhoto = nil
        
        guard let word = currentWord?.word else {
            isLoadingPhoto = false
            return
        }
        
        do {
            let image = try await unsplashService.fetchPhoto(for: word)
            self.currentPhoto = image
        } catch {
            print("Failed to fetch image for \(word): \(error)")
        }
        
        isLoadingPhoto = false
    }

    private func loadExamplesForCurrentWord() async {
        guard let word = currentWord?.word else {
            self.exampleSentences = []
            return
        }
        // This method does not exist on DatabaseManager.
        // The original FlashcardViewModel must have a different way of fetching sentences.
        // Let's look at DatabaseManager.swift again. It has `searchSentences(containing:limit:)`.
        // I will use that.
        do {
            self.exampleSentences = try await databaseManager.searchSentences(containing: word, limit: 3)
        } catch {
            self.exampleSentences = []
            print("Failed to fetch sentences for \(word): \(error)")
        }
    }

    /// Update next and previous word previews for background cards
    private func updatePreviews() async {
        guard !allLearnedWords.isEmpty else {
            nextWordPreview = nil
            previousWordPreview = nil
            nextWordPreviewPhoto = nil
            previousWordPreviewPhoto = nil
            return
        }

        // Calculate next index (wraps around)
        let nextIndex = (currentIndex + 1) % allLearnedWords.count
        nextWordPreview = allLearnedWords[nextIndex]

        // Calculate previous index (wraps around)
        let previousIndex = (currentIndex - 1 + allLearnedWords.count) % allLearnedWords.count
        previousWordPreview = allLearnedWords[previousIndex]

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
    }
}
