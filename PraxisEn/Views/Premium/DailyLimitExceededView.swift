import SwiftUI

struct DailyLimitExceededView: View {
    @Binding var isPresented: Bool
    @State private var showUpgradeView = false
    @State private var timeUntilReset: String = ""

    var body: some View {
        ZStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Icon Section
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "hourglass.tophalf.filled")
                        .font(.system(size: 50))
                        .foregroundColor(.warning)

                    Text("Daily Limit Reached")
                        .font(.system(size: AppTypography.title1, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("You've reached your daily limit of 30 card advances")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil) // Allows text to wrap to multiple lines
                        .padding(.horizontal, AppSpacing.md)
                }

                Spacer()

                // Limit Info
                limitInfoCard

                Spacer()

                // Action Buttons
                VStack(spacing: AppSpacing.md) {
                    // Upgrade Button
                    Button {
                        showUpgradeView = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))

                            Text("Upgrade to Premium")
                                .font(AppTypography.bodyText)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.accentOrange)
                        .cornerRadius(AppCornerRadius.medium)
                        .buttonShadow()
                    }

                    // Wait Until Tomorrow Button
                    VStack(spacing: AppSpacing.xs) {
                        Text("Wait Until Tomorrow")
                            .font(AppTypography.bodyText)
                            .foregroundColor(.textSecondary)

                        if !timeUntilReset.isEmpty {
                            Text(timeUntilReset)
                                .font(AppTypography.captionText)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.creamSecondary)
                    .cornerRadius(AppCornerRadius.medium)
                    .onTapGesture {
                        isPresented = false
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer(minLength: 20)
            }
            .padding(AppSpacing.lg)
            .background(Color.creamBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                    .font(AppTypography.bodyText)
                    .foregroundColor(.accentOrange)
                }
            }
        }
        .fullScreenCover(isPresented: $showUpgradeView) {
            PremiumUpgradeView()
        }
        .onAppear {
            startCountdownTimer()
        }
    }

    // MARK: - Countdown Timer

    private func startCountdownTimer() {
        updateCountdown()

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateCountdown()
        }
    }

    private func updateCountdown() {
        let now = Date()
        let calendar = Calendar.current

        // Get midnight of next day
        var tomorrow = Date()
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: now) {
            tomorrow = nextDay
        }

        let startOfTomorrow = calendar.startOfDay(for: tomorrow)

        let components = calendar.dateComponents([.hour, .minute, .second], from: now, to: startOfTomorrow)

        if let hours = components.hour, let minutes = components.minute, let seconds = components.second {
            if hours > 0 {
                timeUntilReset = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                timeUntilReset = String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }

    // MARK: - Limit Info Card

    private var limitInfoCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Free Tier Limits")
                        .font(AppTypography.cardTitle)
                        .foregroundColor(.textPrimary)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        LimitRow(icon: "arrow.up.circle.fill", text: "30 daily card advances")
                        LimitRow(icon: "books.vertical.fill", text: "A1-B1 levels only")
                        LimitRow(icon: "doc.text.fill", text: "3 example sentences")
                        LimitRow(icon: "bookmark.fill", text: "Last 50 learned words")
                    }
                }

                Spacer()

                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.textTertiary)

                    Text("Limited")
                        .font(AppTypography.captionText)
                        .foregroundColor(.textTertiary)
                        .fontWeight(.medium)
                }
            }
            .padding(AppSpacing.lg)
            .background(Color.white)
            .cornerRadius(AppCornerRadius.card)
            .cardShadow()
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

// MARK: - Limit Row Component

struct LimitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.textTertiary)
                .frame(width: 20)

            Text(text)
                .font(AppTypography.captionText)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    DailyLimitExceededView(isPresented: .constant(true))
}