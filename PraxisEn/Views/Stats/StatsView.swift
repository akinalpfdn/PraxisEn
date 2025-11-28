import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @State private var stats: ReviewStats?
    @State private var settings: UserSettings?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let stats = stats, let settings = settings {
                    // Learning Mode Card
                    learningModeCard(settings: settings)

                    // Overall Stats Cards
                    StatCard(
                        title: "Words Learned",
                        value: "\(stats.knownWords)",
                        icon: "checkmark.circle.fill",
                        color: .success
                    )

                    StatCard(
                        title: "In Review",
                        value: "\(stats.wordsInReview)",
                        icon: "arrow.clockwise.circle.fill",
                        color: .accentOrange
                    )

                    StatCard(
                        title: "Total Words",
                        value: "\(stats.totalWords)",
                        icon: "book.fill",
                        color: .textSecondary
                    )

                    // Level Progress Section
                    levelProgressSection(settings: settings)

                    Spacer(minLength: 20)
                } else {
                    ProgressView("Loading stats...")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding()
        }
        .background(Color.creamBackground.ignoresSafeArea())
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadData()
        }
    }

    // MARK: - Helper Views

    private func learningModeCard(settings: UserSettings) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Learning Mode")
                    .font(AppTypography.bodyText)
                    .foregroundColor(.textSecondary)

                Spacer()

                if settings.wordSelectionMode == .progressiveByLevel {
                    Text("Level \(settings.currentLevel)")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.accentOrange)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.accentOrange.opacity(0.1))
                        .cornerRadius(AppCornerRadius.small)
                }
            }

            Text(settings.wordSelectionMode.displayName)
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            Text(settings.wordSelectionMode.description)
                .font(AppTypography.captionText)
                .foregroundColor(.textSecondary)
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppCornerRadius.card)
        .cardShadow()
    }

    private func levelProgressSection(settings: UserSettings) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Level Progress")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            VStack(spacing: AppSpacing.sm) {
                levelProgressRow(
                    level: "A1",
                    settings: settings,
                    isCurrent: settings.currentLevel == "A1" && settings.wordSelectionMode == .progressiveByLevel
                )
                levelProgressRow(
                    level: "A2",
                    settings: settings,
                    isCurrent: settings.currentLevel == "A2" && settings.wordSelectionMode == .progressiveByLevel
                )
                levelProgressRow(
                    level: "B1",
                    settings: settings,
                    isCurrent: settings.currentLevel == "B1" && settings.wordSelectionMode == .progressiveByLevel
                )
                levelProgressRow(
                    level: "B2",
                    settings: settings,
                    isCurrent: settings.currentLevel == "B2" && settings.wordSelectionMode == .progressiveByLevel
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppCornerRadius.card)
        .cardShadow()
    }

    private func levelProgressRow(level: String, settings: UserSettings, isCurrent: Bool) -> some View {
        let progress = settings.progress(for: level)
        let isCompleted = settings.isLevelCompleted[level] ?? false

        return HStack(spacing: AppSpacing.md) {
            // Level indicator
            Text(levelEmoji(for: level))
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("Level \(level)")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    if isCurrent {
                        Text("Current")
                            .font(AppTypography.captionText)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.accentOrange)
                            .cornerRadius(AppCornerRadius.small)
                    } else if isCompleted {
                        Text("Completed ✓")
                            .font(AppTypography.captionText)
                            .foregroundColor(.success)
                    }
                }

                // Progress bar
                HStack(spacing: AppSpacing.sm) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.creamDark)
                                .frame(height: 6)
                                .cornerRadius(3)

                            Rectangle()
                                .fill(isCompleted ? Color.success : Color.accentOrange)
                                .frame(width: geometry.size.width * progress, height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)

                    // Progress text
                    Text("\(Int(progress * 100))%")
                        .font(AppTypography.captionText)
                        .foregroundColor(.textSecondary)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
        .opacity(isCompleted ? 0.7 : 1.0)
    }

    private func levelEmoji(for level: String) -> String {
        return ""//no need for a emoji
        
    }

    // MARK: - Data Loading

    private func loadData() async {
        // Load stats
        stats = await SpacedRepetitionManager.getReviewStats(from: modelContext)

        // Load settings
        if let firstSettings = userSettings.first {
            settings = firstSettings
            // Update progress when stats view appears
            await updateSettingsProgress(firstSettings)
        }
    }

    private func updateSettingsProgress(_ settings: UserSettings) async {
        // Calculate word counts per level (similar logic as in FlashcardViewModel)
        let descriptor = FetchDescriptor<VocabularyWord>()
        let allWords = (try? modelContext.fetch(descriptor)) ?? []

        var totalWordsByLevel: [String: Int] = [:]
        var knownWordsByLevel: [String: Int] = [:]

        // Initialize counters
        for level in ["A1", "A2", "B1", "B2"] {
            totalWordsByLevel[level] = 0
            knownWordsByLevel[level] = 0
        }

        // Count words by level
        for word in allWords {
            if let levelCount = totalWordsByLevel[word.level] {
                totalWordsByLevel[word.level] = levelCount + 1
            }

            if word.isKnown {
                if let knownCount = knownWordsByLevel[word.level] {
                    knownWordsByLevel[word.level] = knownCount + 1
                }
            }
        }

        // Update settings with new counts
        settings.updateWordCounts(totalWords: totalWordsByLevel, knownWords: knownWordsByLevel)

        do {
            try modelContext.save()
        } catch {
            //print("❌ Error updating settings progress: \(error)")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}
