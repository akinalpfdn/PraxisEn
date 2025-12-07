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

    // Comprehensive loading state management
    @State private var initializationState: InitializationState = .loading
    @State private var errorMessage: String?

    // Onboarding state
    @State private var showWelcomeView = false

    enum InitializationState {
        case loading
        case databaseSetup
        case contentLoading
        case ready
        case error(String)
    }
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                Color.creamBackground
                    .ignoresSafeArea()

                if showWelcomeView {
                    WelcomeView {
                        completeWelcomeOnboarding()
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.1)),
                        removal: .opacity.combined(with: .scale(scale: 0.9))
                    ))
                } else {
                    switch initializationState {
                    case .loading:
                        loadingView("Initializing...")

                    case .databaseSetup:
                        loadingView("Setting up database...")

                    case .contentLoading:
                        loadingView("Loading content...")

                    case .ready:
                        if let viewModel = viewModel {
                            FlashcardContentView(
                                viewModel: viewModel,
                                navigationPath: $navigationPath
                            )
                        } else {
                            errorView("Failed to initialize content")
                        }

                    case .error(let message):
                        errorView(message)
                    }
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
            await initializeApp()
            checkOnboardingStatus()
        }
        .animation(.easeInOut(duration: 0.4), value: showWelcomeView)

    }

    // MARK: - Loading Views

    private func loadingView(_ message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.accentOrange)

            Text(message)
                .font(AppTypography.bodyText)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.error)

            Text("Something went wrong")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            Text(message)
                .font(AppTypography.bodyText)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await initializeApp()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }

    // MARK: - Onboarding Logic

    private func checkOnboardingStatus() {
        if !OnboardingManager.shared.hasCompletedOnboarding {
            showWelcomeView = true
        }
    }

    private func completeWelcomeOnboarding() {
        OnboardingManager.shared.markOnboardingCompleted()

        withAnimation(.easeInOut(duration: 0.4)) {
            showWelcomeView = false
        }
    }

    // MARK: - Initialization Logic

    @MainActor
    private func initializeApp() async {
        //print("🚀 Starting fast offline initialization...")

        do {
            // Phase 1: Quick Database Check (should be immediate for offline)
            initializationState = .databaseSetup
            //print("📁 Checking database...")

            try await setupDatabaseFast()

            // Phase 2: Initialize Services in Background (don't block)
            //print("💳 Initializing services...")
            await setupServicesFast()

            // Phase 3: Load Content (fast for offline)
            initializationState = .contentLoading
            //print("📚 Loading content...")

            try await setupContentFast()

            // Phase 4: Ready
            initializationState = .ready
            //print("✅ Fast initialization complete!")

        } catch {
            let errorMsg = "Initialization failed: \(error.localizedDescription)"
            //print("❌ \(errorMsg)")
            errorMessage = errorMsg
            initializationState = .error(errorMsg)
        }
    }

    private func setupDatabaseFast() async throws {
        //print("🔧 Initializing database setup...")

        do {
            // ALWAYS trigger database setup to ensure sentences are set up
            try await DatabaseManager.shared.setupDatabasesIfNeeded()
            //print("✅ Database setup completed")
        } catch {
            //print("⚠️ Database setup failed: \(error)")
            // Don't throw error - continue with limited functionality
        }

        // Check final status
        if DatabaseManager.shared.isDatabaseSetupComplete() {
            //print("✅ Database ready")
        } else {
            //print("⚠️ Database setup incomplete, proceeding anyway...")
        }
    }

    private func setupServicesFast() async {
        // Initialize subscription managers (quick sync operation)
        SubscriptionManager.shared.configure(with: modelContext)

        // Load products in background - don't wait for this
        Task {
            do {
                try await PurchaseManager.shared.loadProducts()
                await PurchaseManager.shared.checkSubscriptionStatus()
                //print("✅ Subscription services ready")
            } catch {
                //print("⚠️ Subscription setup failed, but continuing: \(error)")
            }
        }
    }

    private func setupContentFast() async throws {
        // Initialize ViewModel (immediate)
        let vm = FlashcardViewModel(modelContext: modelContext)
        viewModel = vm

        // Load user settings (should be fast for offline)
        await vm.loadUserSettings()

        // ⚡ CRITICAL FIX: Only load first word AFTER userSettings is confirmed loaded
        // Retry mechanism to ensure settings are available before trying to load a word
        var retryCount = 0
        let maxRetries = 3

        while vm.userSettings == nil && retryCount < maxRetries {
            //print("⚠️ User settings not loaded yet, retrying... (\(retryCount + 1)/\(maxRetries))")
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
            await vm.loadUserSettings()
            retryCount += 1
        }

        // Final check - if still no settings, create default ones inline
        if vm.userSettings == nil {
            //print("🔧 Creating default settings inline to ensure word loading works")
            // This ensures we always have settings for word loading
            await vm.loadUserSettings()
        }

        // Now load the first word with confidence that settings exist
        //print("🔄 Loading first word...")
        await vm.loadNextWord()

        // If still no word after all this, load a seed word directly as fallback
        if vm.currentWord == nil {
            //print("🚨 Fallback: Loading seed word directly")
            await loadSeedWordFallback(viewModel: vm)
        }

        // Update progress counts (quick operations)
        await vm.updateKnownWordsCount()
        await vm.updateTotalWordsCount()
        await vm.updateB2WordsCount()

        //print("✅ Content loading complete")
    }

    /// Fallback method to load a seed word directly if normal word loading fails
    private func loadSeedWordFallback(viewModel: FlashcardViewModel) async {
        do {
            let descriptor = FetchDescriptor<VocabularyWord>()
            let words = try modelContext.fetch(descriptor)

            // Prefer A1 words as fallback, then any word
            let fallbackWord = words.first { $0.level == "A1" } ?? words.first

            if let word = fallbackWord {
                //print("🎯 Loaded fallback word: \(word.word)")
                viewModel.currentWord = word
                viewModel.isFlipped = false

                // Call public methods to load associated content
                await viewModel.loadContentForCurrentWord()
            } else {
                //print("❌ No words available in database at all")
            }
        } catch {
            //print("❌ Failed to load fallback word: \(error)")
        }
    }

    // MARK: - Error Types

    enum AppError: LocalizedError {
        case databaseTimeout
        case contentLoadTimeout
        case viewModelCreationFailed

        var errorDescription: String? {
            switch self {
            case .databaseTimeout:
                return "Database setup took too long. Please restart the app."
            case .contentLoadTimeout:
                return "Loading content took too long. Please check your connection."
            case .viewModelCreationFailed:
                return "Failed to initialize the app interface."
            }
        }
    }
}

// MARK: - Flashcard Content View


struct FlashcardContentView: View {
    @ObservedObject var viewModel: FlashcardViewModel
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Binding var navigationPath: [NavigationDestination]
    @State private var showMenuDropdown = false

    var body: some View {
        GeometryReader { geometry in
            mainContent(geometry: geometry)
                .overlay(overlaysContainer(geometry: geometry))
        }
    }

    // MARK: - Main Content

    private func mainContent(geometry: GeometryProxy) -> some View {
        let isSmallScreen = geometry.size.height < 700

        return VStack(spacing: 0) {
            headerView
                .zIndex(1.0)
                .padding(.top, isSmallScreen ? 0 : 10)

            Spacer(minLength: isSmallScreen ? 10 : 20)

            flashcardArea(geometry: geometry, isSmallScreen: isSmallScreen)

            Spacer(minLength: isSmallScreen ? 10 : 30)

            bottomSection(isSmallScreen: isSmallScreen)
        }
        .padding(AppSpacing.lg)
        .frame(width: geometry.size.width, height: geometry.size.height)
    }

    // MARK: - Flashcard Area

    @ViewBuilder
    private func flashcardArea(geometry: GeometryProxy, isSmallScreen: Bool) -> some View {
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
            .frame(maxHeight: isSmallScreen ? .infinity : geometry.size.height * 0.65)
        } else {
            ProgressView("Loading word...")
                .font(AppTypography.bodyText)
                .foregroundColor(.textSecondary)
                .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Bottom Section

    private func bottomSection(isSmallScreen: Bool) -> some View {
        VStack(spacing: isSmallScreen ? 4 : 16) {
            hintView

            ProgressBarView(
                current: viewModel.knownWordsCount,
                total: viewModel.totalWordsCount,
                showAnimation: false,
                isPremiumUser: subscriptionManager.isPremiumActive,
                b2WordCount: subscriptionManager.isPremiumActive ? 0 : viewModel.b2WordsCount
            )
        }
        .padding(.bottom, isSmallScreen ? 8 : 20)
    }

    // MARK: - Overlays Container

    @ViewBuilder
    private func overlaysContainer(geometry: GeometryProxy) -> some View {
        translationInputOverlay
        successAnimationOverlay(geometry: geometry)
        dailyLimitAlertOverlay
        levelRestrictionAlertOverlay
    }

    // MARK: - Individual Overlays

    @ViewBuilder
    private var translationInputOverlay: some View {
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

    @ViewBuilder
    private func successAnimationOverlay(geometry: GeometryProxy) -> some View {
        if viewModel.showProgressAnimation {
            SuccessAnimationView()
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height * 0.8
                )
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var dailyLimitAlertOverlay: some View {
        if viewModel.showDailyLimitAlert {
            DailyLimitExceededView(isPresented: Binding(
                get: { viewModel.showDailyLimitAlert },
                set: { viewModel.showDailyLimitAlert = $0 }
            ))
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
            .zIndex(1000)
        }
    }

    @ViewBuilder
    private var levelRestrictionAlertOverlay: some View {
        if viewModel.showLevelRestrictionAlert {
            LevelRestrictionView(isPresented: $viewModel.showLevelRestrictionAlert, blockedLevel: getBlockedLevel())
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
                .zIndex(1000)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppSpacing.xs) {
                    Text("PraxisEn")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    if subscriptionManager.isPremiumActive {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.accentOrange)
                    }
                }
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

    private func getBlockedLevel() -> String {
        // This is only shown when user has completed all free levels
        // So the blocked level is always B2
        return "B2"
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
