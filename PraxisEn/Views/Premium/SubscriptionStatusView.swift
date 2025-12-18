import SwiftUI

struct SubscriptionStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var subscriptionInfo: SubscriptionStatus?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Status Header
                    statusHeaderSection

                    // Plan Details
                    planDetailsSection

                    // Usage Statistics
                    usageStatsSection

                    // Management Actions
                    managementActionsSection

                    Spacer(minLength: 50)
                }
                .padding(AppSpacing.lg)
            }
            .background(Color.creamBackground)
            .navigationTitle("Subscription Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTypography.bodyText)
                    .foregroundColor(.accentOrange)
                }
            }
            .task {
                await loadSubscriptionInfo()
            }
        }
    }

    // MARK: - Status Header

    private var statusHeaderSection: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentOrange)

            Text("Premium Active")
                .font(.system(size: AppTypography.title1, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            Text("Enjoy unlimited access to all features")
                .font(AppTypography.bodyText)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
        }
        .padding(.top, AppSpacing.lg)
    }

    // MARK: - Plan Details

    private var planDetailsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("Plan Details")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            VStack(spacing: AppSpacing.md) {
                StatusRow(
                    icon: "crown.fill",
                    title: "Subscription Type",
                    value: "Premium Monthly",
                    iconColor: .accentOrange
                )

                if let expirationDate = subscriptionInfo?.expirationDate {
                    StatusRow(
                        icon: "calendar",
                        title: "Renewal Date",
                        value: formatExpirationDate(expirationDate),
                        iconColor: .info
                    )
                }

                StatusRow(
                    icon: "play.circle.fill",
                    title: "Auto-Renewal",
                    value: "Enabled",
                    iconColor: .success
                )
            }
            .padding(AppSpacing.lg)
            .background(Color.white)
            .cornerRadius(AppCornerRadius.card)
            .cardShadow()
        }
    }

    // MARK: - Usage Statistics

    private var usageStatsSection: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("Usage Statistics")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            let swipeInfo = SubscriptionManager.shared.getDailySwipeInfo()
            VStack(spacing: AppSpacing.md) {
                StatusRow(
                    icon: "arrow.up.circle.fill",
                    title: "Daily Swipes",
                    value: "Unlimited",
                    iconColor: .success
                )

                StatusRow(
                    icon: "books.vertical.fill",
                    title: "Available Levels",
                    value: "All Levels (A1-B2)",
                    iconColor: .success
                )

                StatusRow(
                    icon: "doc.text.fill",
                    title: "Example Sentences",
                    value: "10 per word",
                    iconColor: .success
                )

                StatusRow(
                    icon: "bookmark.fill",
                    title: "Learned Words History",
                    value: "Complete access",
                    iconColor: .success
                )
            }
            .padding(AppSpacing.lg)
            .background(Color.white)
            .cornerRadius(AppCornerRadius.card)
            .cardShadow()
        }
    }

    // MARK: - Management Actions

    private var managementActionsSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Manage Subscription Button
            Button {
                manageSubscription()
            } label: {
                HStack {
                    Image(systemName: "gear")
                        .font(.system(size: 16))

                    Text("Manage Subscription")
                        .font(AppTypography.bodyText)
                        .fontWeight(.medium)
                }
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Color.creamSecondary)
                .cornerRadius(AppCornerRadius.medium)
            }

            // Cancel Subscription Button
            Button {
                cancelSubscription()
            } label: {
                Text("Cancel Subscription")
                    .font(AppTypography.bodyText)
                    .foregroundColor(.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.error.opacity(0.1))
                    .cornerRadius(AppCornerRadius.medium)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadSubscriptionInfo() async {
        subscriptionInfo = await purchaseManager.getSubscriptionInfo()
    }

    private func formatExpirationDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func manageSubscription() {
        // Open App Store subscription management
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    private func cancelSubscription() {
        // Open App Store subscription management for cancellation
        manageSubscription()
    }
}

// MARK: - Status Row Component

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.bodyText)
                    .foregroundColor(.textPrimary)

                Text(value)
                    .font(AppTypography.captionText)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionStatusView()
}