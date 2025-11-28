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
    @State private var isDatabaseReady: Bool = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                Color.creamBackground
                    .ignoresSafeArea()

                if !isDatabaseReady {
                    // Setting up database
                    ProgressView("Initializing...")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.textSecondary)
                } else if let viewModel = viewModel {
                    FlashcardContentView(
                        viewModel: viewModel,
                        navigationPath: $navigationPath
                    )
                } else {
                    // Initializing ViewModel
                    ProgressView("Loading...")
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
                    SettingsView()
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
            print("🚀 ContentView.task started")

            // Wait for database to be ready before proceeding
            print("🚀 Waiting for database setup...")
            while !DatabaseManager.shared.isDatabaseSetupComplete() {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }

            print("🚀 Database setup complete, setting isDatabaseReady = true")
            // Small delay to ensure all database operations are complete
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            await MainActor.run {
                isDatabaseReady = true
            }

            print("🚀 Initializing ViewModel")
            // Initialize ViewModel with correct context
            let vm = FlashcardViewModel(modelContext: modelContext)
            viewModel = vm

            print("🚀 Loading user settings")
            // Load user settings first
            await vm.loadUserSettings()

            print("🚀 Loading first word")
            // Load first word using spaced repetition with settings
            await vm.loadNextWord()
            await vm.updateKnownWordsCount()
            await vm.updateTotalWordsCount()

            print("🚀 ContentView.task completed")
        }

    }
}

// MARK: - Flashcard Content View


struct FlashcardContentView: View {
    @ObservedObject var viewModel: FlashcardViewModel
    @Binding var navigationPath: [NavigationDestination]
    @State private var showMenuDropdown = false

    var body: some View {
        GeometryReader { geometry in
            // Determine if device is small (like iPhone SE) to adjust spacing
            let isSmallScreen = geometry.size.height < 700
            
            VStack(spacing: 0) { // Zero spacing here, we control it with Spacers and padding
                // Header
                headerView
                    .zIndex(1.0)
                    .padding(.top, isSmallScreen ? 0 : 10) // Add top breathing room on big screens

                // Dynamic spacer: pushes content apart on big screens, keeps it tight on small ones
                Spacer(minLength: isSmallScreen ? 10 : 20)

                // Flashcard Area
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
                                await handleSwipeUp()
                            }
                        },
                        onPlayAudio: {
                            viewModel.playWordAudio()
                        }
                    )
                    // Limit card height on massive screens so it doesn't look stretched
                    .frame(maxHeight: isSmallScreen ? .infinity : geometry.size.height * 0.65)
                    
                } else {
                    // Loading initial word
                    ProgressView("Loading word...")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.textSecondary)
                        .frame(maxHeight: .infinity)
                }

                // Dynamic spacer: pushes footer to bottom
                Spacer(minLength: isSmallScreen ? 10 : 30)

                // Bottom section
                VStack(spacing: isSmallScreen ? 4 : 16) { // More space between hint and progress on big screens
                    // Hint
                    hintView

                    // Progress bar
                    ProgressBarView(
                        current: viewModel.knownWordsCount,
                        total: viewModel.totalWordsCount,
                        showAnimation: false
                    )
                }
                .padding(.bottom, isSmallScreen ? 8 : 20) // Extra bottom padding on safe area for big screens
            }
            .padding(AppSpacing.lg)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(
                // Translation Input Modal (full-screen overlay)
                Group {
                    if viewModel.showTranslationInput {
                        TranslationInputOverlay(
                            userInput: $viewModel.userTranslationInput,
                            validationState: viewModel.translationValidationState,
                            validationResult: viewModel.translationValidationResult,
                            onSubmit: {
                                Task {
                                    await viewModel.submitTranslation()
                                }
                            },
                            onClear: {
                                viewModel.clearTranslationInput()
                            },
                            onHide: {
                                viewModel.hideTranslationInputField()
                            },
                            userStartedTyping: {
                                viewModel.userStartedTypingTranslation()
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                        .zIndex(1000)
                    }
                }
            )
            .overlay(
                // Success Animation
                Group {
                    if viewModel.showProgressAnimation {
                        SuccessAnimationView()
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height * 0.8
                            )
                            .transition(.opacity)
                    }
                }
            )
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PraxisEn")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }

            Spacer()

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

    // MARK: - Helper Methods

    private func handleSwipeUp() async {
        if viewModel.userHasSeenBackOfCard() {
            await viewModel.markCurrentWordAsKnown()
        } else {
            viewModel.showTranslationInputField()
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

                Text("Tap")
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
            }.padding(.vertical, 1)
           
        }
        .padding(.vertical, 1)
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
