import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @State private var settings: UserSettings?
    @State private var isLoading = true
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if isLoading {
                        ProgressView("Loading settings...")
                            .font(AppTypography.bodyText)
                            .foregroundColor(.textSecondary)
                            .padding(.top, 50)
                    } else if let settings = settings {
                        settingsContent(settings: settings)
                    } else {
                        noSettingsView()
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(Color.creamBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadSettings()
            }
            .alert("Reset All Progress", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset Everything", role: .destructive) {
                    performFullReset()
                }
            } message: {
                Text("This will permanently delete all your learning progress:\n\n• Reset all word learning status\n• Clear learned words history\n• Restart from A1 in progressive mode\n\nThis action cannot be undone.")
            }
        }
    }

    // MARK: - Settings Content

    private func settingsContent(settings: UserSettings) -> some View {
        VStack(spacing: AppSpacing.xl) {
            // Learning Mode Section
            learningModeSection(settings: settings)

            // Removed progress section - now only in StatsView

            // Actions Section
            actionsSection(settings: settings)

            Spacer(minLength: 20)
        }
    }

    private func learningModeSection(settings: UserSettings) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Learning Mode")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            VStack(spacing: AppSpacing.md) {
                ForEach(UserSettings.WordSelectionMode.allCases, id: \.self) { mode in
                    modeButton(
                        mode: mode,
                        isSelected: settings.wordSelectionMode == mode
                    ) {
                        updateSettings(mode: mode)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppCornerRadius.card)
        .cardShadow()
    }

    // Progress section removed - now only in StatsView

    private func actionsSection(settings: UserSettings) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Actions")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            VStack(spacing: AppSpacing.sm) {
                actionButton(
                    title: "Reset Progress",
                    subtitle: "Clear all learning progress and restart from A1",
                    iconName: "arrow.clockwise",
                    color: .error
                ) {
                    showResetConfirmation = true
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppCornerRadius.card)
        .cardShadow()
    }

    // MARK: - Helper Views

    private func modeButton(mode: UserSettings.WordSelectionMode, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(mode.displayName)
                            .font(AppTypography.bodyText)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .accentOrange : .textTertiary)
                            .font(.system(size: 20))
                    }

                    Text(mode.description)
                        .font(AppTypography.captionText)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(AppSpacing.md)
            .background(isSelected ? Color.accentOrange.opacity(0.1) : Color.clear)
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(isSelected ? Color.accentOrange : Color.creamDark, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func levelProgressCard(level: String, settings: UserSettings) -> some View {
        let progress = settings.progress(for: level)
        let isCompleted = settings.isLevelCompleted[level] ?? false
        let isCurrentLevel = settings.currentLevel == level && settings.wordSelectionMode == .progressiveByLevel

        return HStack(spacing: AppSpacing.md) {
            // Level indicator
            Text(levelEmoji(for: level))
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("Level \(level)")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    if isCurrentLevel {
                        Text("Current")
                            .font(AppTypography.captionText)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.accentOrange)
                            .cornerRadius(AppCornerRadius.small)
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.creamDark)
                                .frame(height: 8)
                                .cornerRadius(4)

                            Rectangle()
                                .fill(isCompleted ? Color.success : Color.accentOrange)
                                .frame(width: geometry.size.width * progress, height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)

                    // Progress text
                    Text("\(Int(progress * 100))%")
                        .font(AppTypography.captionText)
                        .foregroundColor(.textSecondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.creamBackground)
        .cornerRadius(AppCornerRadius.medium)
        .opacity(isCompleted ? 0.7 : 1.0)
    }

    private func actionButton(title: String, subtitle: String, iconName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: iconName)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.bodyText)
                        .foregroundColor(.textPrimary)

                    Text(subtitle)
                        .font(AppTypography.captionText)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(AppSpacing.md)
            .background(color.opacity(0.1))
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Methods

    private func levelEmoji(for level: String) -> String {
        switch level {
        case "A1": return "🟢"
        case "A2": return "🔵"
        case "B1": return "🟠"
        case "B2": return "🔴"
        default: return "⚪️"
        }
    }

    private func noSettingsView() -> some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "gear")
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)

            Text("No Settings Found")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            Text("Initializing your learning preferences...")
                .font(AppTypography.bodyText)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Button("Create Settings") {
                Task {
                    await createSettings()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top, 50)
    }

    // MARK: - Data Management

    private func loadSettings() async {
        await MainActor.run {
            isLoading = true
        }

        // If no settings exist, create default ones
        if userSettings.isEmpty {
            await createSettings()
        } else {
            await MainActor.run {
                settings = userSettings.first
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func createSettings() async {
        let newSettings = UserSettings()
        modelContext.insert(newSettings)

        do {
            try modelContext.save()
            await MainActor.run {
                settings = newSettings
            }
            //print("✅ Created default user settings")
        } catch {
            //print("❌ Error creating settings: \(error)")
        }
    }

    private func updateSettings(mode: UserSettings.WordSelectionMode) {
        guard var settings = settings else { return }

        settings.wordSelectionMode = mode
        settings.updatedAt = Date()

        // If switching to progressive mode, reset to A1 if all levels are completed
        if mode == .progressiveByLevel && settings.allLevelsCompleted {
            settings.resetProgress()
        }

        do {
            try modelContext.save()
            DispatchQueue.main.async {
                self.settings = settings
            }
            //print("✅ Updated learning mode: \(mode.displayName)")
        } catch {
            //print("❌ Error updating settings: \(error)")
        }
    }

    // Old resetProgress function removed - replaced with performFullReset

    // MARK: - Reset Functionality

    private func performFullReset() {
        guard let settings = settings else { return }

        // Reset all VocabularyWord records
        do {
            let descriptor = FetchDescriptor<VocabularyWord>()
            let allWords = try modelContext.fetch(descriptor)

            for word in allWords {
                word.isKnown = false
                word.repetitions = 0
                word.reviewCount = 0
                word.lastReviewedDate = nil
                word.isLearned = false
            }

            try modelContext.save()

            // Reset user settings
            settings.resetProgress()
            try modelContext.save()

            self.settings = settings

            //print("🔄 Successfully reset all learning progress")
        } catch {
            //print("❌ Error resetting progress: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            SettingsView()
        }
    }

    return PreviewWrapper()
}
