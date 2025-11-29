import SwiftUI

struct LevelRestrictionView: View {
    @Binding var isPresented: Bool
    let blockedLevel: String
    @State private var showUpgradeView = false

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Main content
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                // Icon Section
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.warning)

                    Text("Level \(blockedLevel) Locked")
                        .font(.system(size: AppTypography.title1, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Access to \(blockedLevel) level requires a Premium subscription")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.md)
                }

                Spacer()

                // Level Info
                levelInfoCard

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

                            Text("Unlock All Levels")
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

                    // Stay in Current Level Button
                    Button {
                        isPresented = false
                    } label: {
                        Text("Stay in Current Level")
                            .font(AppTypography.bodyText)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(Color.creamSecondary)
                            .cornerRadius(AppCornerRadius.medium)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer(minLength: 20)
            }
            .padding(AppSpacing.lg)
            .background(Color.white)
            .cornerRadius(AppCornerRadius.card)
            .cardShadow()
            .padding(AppSpacing.lg)
            .fullScreenCover(isPresented: $showUpgradeView) {
                PremiumUpgradeView()
            }
        }
    }

    // MARK: - Level Info Card

    private var levelInfoCard: some View {
        VStack(spacing: AppSpacing.md) {
            Text("What You'll Unlock")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            VStack(spacing: AppSpacing.sm) {
                LevelFeatureRow(
                    icon: "lock.open.fill",
                    title: "All Levels",
                    description: "Access to A1, A2, B1, and B2"
                )

                LevelFeatureRow(
                    icon: "doc.text.fill",
                    title: "More Sentences",
                    description: "10 example sentences per word"
                )

                LevelFeatureRow(
                    icon: "bookmark.fill",
                    title: "Full History",
                    description: "Complete learned words access"
                )

                LevelFeatureRow(
                    icon: "arrow.up.circle.fill",
                    title: "Unlimited Swipes",
                    description: "Practice without daily limits"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.white)
        .cornerRadius(AppCornerRadius.medium)
        .cardShadow()
    }
}

// MARK: - Level Feature Row Component

struct LevelFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentOrange)
                .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.captionText)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(AppTypography.captionText)
                    .foregroundColor(.textTertiary)
            }

            Spacer()

            // Premium indicator
            Image(systemName: "crown.fill")
                .font(.system(size: 12))
                .foregroundColor(.accentOrange)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Preview

#Preview {
    LevelRestrictionView(isPresented: .constant(true), blockedLevel: "B2")
}