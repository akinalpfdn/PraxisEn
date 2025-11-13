//
//  ContentView.swift
//  PraxisEn
//
//  Created by Akinalp Fidan on 10.11.2025.
//

import SwiftUI
import SwiftData

enum NavigationDestination: Hashable {
    case stats
    case learnedWords
    case settings
    case learnedFlashcard(wordID: String, allLearnedWordIDs: [String])
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FlashcardViewModel?
    @State private var navigationPath: [NavigationDestination] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                Color.creamBackground
                    .ignoresSafeArea()

                if let viewModel = viewModel {
                    FlashcardContentView(
                        viewModel: viewModel,
                        navigationPath: $navigationPath
                    )
                } else {
                    // Initializing ViewModel
                    ProgressView("Initializing...")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .stats:
                    StatsView()
                case .learnedWords:
                    LearnedWordsView()
                case .settings:
                    Text("Settings - Coming Soon")
                        .navigationTitle("Settings")
                case .learnedFlashcard(let wordID, let allLearnedWordIDs):
                    let vm = LearnedFlashcardViewModel(
                        modelContext: modelContext,
                        wordID: wordID,
                        allLearnedWordIDs: allLearnedWordIDs
                    )
                    LearnedFlashcardView(viewModel: vm)
                }
            }
        }
        .task {
            // Initialize ViewModel with correct context
            let vm = FlashcardViewModel(modelContext: modelContext)
            viewModel = vm

            // Load first word using spaced repetition
            await vm.loadNextWord()
            await vm.updateKnownWordsCount()
        }

    }
}

// MARK: - Flashcard Content View

struct FlashcardContentView: View {
    @ObservedObject var viewModel: FlashcardViewModel
    @Binding var navigationPath: [NavigationDestination]
    @State private var showMenuDropdown = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header
            headerView
                .zIndex(1.0)

           

            // Flashcard
            if let word = viewModel.currentWord {
                SwipeableCardStack(
                    currentCard: FlashcardCardData(
                        word: word.word.capitalized,
                        level: word.level,
                        translation: word.turkishTranslation,
                        definition: word.definition,
                        photo: viewModel.currentPhoto,
                        isLoadingPhoto: viewModel.isLoadingPhoto,
                        examples: viewModel.exampleSentences,
                        synonyms: word.synonymsList,
                        antonyms: word.antonymsList,
                        collocations: word.collocationsList,
                        isFlipped: viewModel.isFlipped
                    ),
                    nextCard: viewModel.nextWordPreview.map { next in
                        FlashcardCardData(
                            word: next.word.capitalized,
                            level: next.level,
                            translation: next.turkishTranslation,
                            definition: next.definition,
                            photo: viewModel.nextWordPreviewPhoto,
                            isLoadingPhoto: false,
                            examples: [],
                            synonyms: next.synonymsList,
                            antonyms: next.antonymsList,
                            collocations: next.collocationsList,
                            isFlipped: false
                        )
                    },
                    previousCard: viewModel.previousWordPreview.map { prev in
                        FlashcardCardData(
                            word: prev.word.capitalized,
                            level: prev.level,
                            translation: prev.turkishTranslation,
                            definition: prev.definition,
                            photo: viewModel.previousWordPreviewPhoto,
                            isLoadingPhoto: false,
                            examples: [],
                            synonyms: prev.synonymsList,
                            antonyms: prev.antonymsList,
                            collocations: prev.collocationsList,
                            isFlipped: false
                        )
                    },
                    onSwipeLeft: {
                        Task {
                            await viewModel.nextWord()
                        }
                    },
                    onSwipeRight: {
                        Task {
                            await viewModel.previousWord()
                        }
                    },
                    onTap: {
                        viewModel.toggleFlip()
                    },
                    onSwipeUp: {
                        Task {
                            await viewModel.markCurrentWordAsKnown()
                        }
                    },
                    onPlayAudio: {
                        viewModel.playWordAudio()
                    }
                )
            } else {
                // Loading initial word
                ProgressView("Loading word...")
                    .font(AppTypography.bodyText)
                    .foregroundColor(.textSecondary)
            }

            // Bottom hint
            hintView

            // Progress bar
            ProgressBarView(
                current: viewModel.knownWordsCount,
                total: viewModel.totalWordsCount,
                showAnimation: false  // We show animation separately now
            )
            .padding(.bottom, AppSpacing.md)


        }
        .padding(AppSpacing.lg)
        .overlay(
            GeometryReader { geometry in
                if viewModel.showProgressAnimation {
                    SuccessAnimationView()
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * 0.8  // 60% down from top
                        )
                        .transition(.opacity)
                }
            }
        )
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PraxisEn")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Learn English Vocabulary")
                    .font(AppTypography.captionText)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Stats or settings button could go here
            Image(systemName: "person.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.accentOrange)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showMenuDropdown.toggle()
                    }
                }
        }
        .overlay(alignment: .topTrailing) {
            if showMenuDropdown {
                VStack(spacing: 0) {
                    MenuButton(icon: "chart.bar.fill", title: "Stats") {
                        showMenuDropdown = false
                        navigationPath.append(.stats)
                    }

                    Divider()

                    MenuButton(icon: "checkmark.circle.fill", title: "Learned Words") {
                        showMenuDropdown = false
                        navigationPath.append(.learnedWords)
                    }

                    Divider()

                    MenuButton(icon: "gearshape.fill", title: "Settings") {
                        showMenuDropdown = false
                        navigationPath.append(.settings)
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.15), radius: 10)
                .padding(.top, 50)
                .padding(.trailing, 10)
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
        }
    }

    private var hintView: some View {
        VStack(){
            // Tap hint
            HStack(spacing: 6) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentOrange)

                Text("Swipe Up to mark as known")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            HStack(spacing: AppSpacing.lg) {
                // Swipe left hint
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentOrange)
                    
                    Text("Swipe")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                
                // Circular divider
                Circle()
                    .fill(Color.textTertiary.opacity(0.3))
                    .frame(width: 4, height: 4)
                
                // Tap hint
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentOrange)
                    
                    Text("Tap to flip")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                
                // Circular divider
                Circle()
                    .fill(Color.textTertiary.opacity(0.3))
                    .frame(width: 4, height: 4)
                
                // Swipe right hint
                HStack(spacing: 6) {
                    Text("Swipe")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentOrange)
                }
            }.padding(.vertical, 8)
            
        }
        .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.4))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
    }
}

// MARK: - ContentView Original (Unused - keeping for reference)

extension ContentView {}

// MARK: - Preview Helper

extension ModelContainer {
    static var preview: ModelContainer {
        let schema = Schema([VocabularyWord.self, SentencePair.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        // Add sample data
        let context = container.mainContext
        let sampleWord = VocabularyWord.sample
        context.insert(sampleWord)

        return container
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
}

struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.accentOrange)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(minWidth: 200)
    }
}
