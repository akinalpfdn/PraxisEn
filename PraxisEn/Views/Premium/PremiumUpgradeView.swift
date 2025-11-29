import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header Section
                    headerSection

                    // Features Comparison
                    featuresSection

                    // Pricing Section
                    pricingSection

                    // CTA Buttons
                    actionButtonsSection

                    // Legal Links
                    legalLinksSection

                    Spacer(minLength: 50)
                }
                .padding(AppSpacing.lg)
            }
            .background(Color.creamBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(AppTypography.bodyText)
                    .foregroundColor(.accentOrange)
                }
            }
            .overlay {
                if isLoading {
                    loadingOverlay
                }
            }
            .task {
                await loadProducts()
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Premium Icon
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentOrange)
                .padding(.bottom, AppSpacing.sm)

            // Title
            Text("Unlock Premium")
                .font(.system(size: AppTypography.title1, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Get unlimited access to all features and accelerate your vocabulary learning journey")
                .font(AppTypography.bodyText)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
        }
        .padding(.top, AppSpacing.lg)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("What You'll Get")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)
                .padding(.bottom, AppSpacing.sm)

            VStack(spacing: AppSpacing.md) {
                FeatureRow(
                    icon: "books.vertical.fill",
                    title: "All Learning Levels",
                    description: "Access to A1, A2, B1, and B2 levels",
                    includedInFree: false
                )

                FeatureRow(
                    icon: "doc.text.fill",
                    title: "10 Example Sentences",
                    description: "More context for better understanding",
                    includedInFree: false
                )

                FeatureRow(
                    icon: "arrow.up.circle.fill",
                    title: "Unlimited Daily Swipes",
                    description: "Practice without daily limits",
                    includedInFree: false
                )

                FeatureRow(
                    icon: "bookmark.fill",
                    title: "Complete Learned Words",
                    description: "Access to all your learned vocabulary",
                    includedInFree: false
                )
            }
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("Choose Your Plan")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            // Premium Plan Card
            VStack(spacing: AppSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Premium Monthly")
                            .font(AppTypography.cardTitle)
                            .foregroundColor(.textPrimary)

                        Text("Billed monthly, cancel anytime")
                            .font(AppTypography.captionText)
                            .foregroundColor(.textTertiary)
                    }

                    Spacer()

                    Text("£4.99/mo")
                        .font(.system(size: AppTypography.headline, weight: .bold))
                        .foregroundColor(.accentOrange)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.lg)
                .background(Color.white)
                .cornerRadius(AppCornerRadius.card)
                .cardShadow()
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.card)
                        .stroke(Color.accentOrange, lineWidth: 2)
                )
            }
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Subscribe Button
            Button {
                Task {
                    await subscribeToPremium()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Subscribe to Premium")
                            .font(AppTypography.bodyText)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Color.accentOrange)
                .cornerRadius(AppCornerRadius.medium)
                .buttonShadow()
            }
            .disabled(isLoading || purchaseManager.monthlyPremiumProduct == nil)

            // Restore Purchases Button
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(AppTypography.bodyText)
                    .foregroundColor(.accentOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.creamSecondary)
                    .cornerRadius(AppCornerRadius.medium)
            }
            .disabled(isLoading)
        }
    }

    // MARK: - Legal Links Section

    private var legalLinksSection: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.lg) {
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    .font(AppTypography.captionText)
                    .foregroundColor(.accentOrange)

                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    .font(AppTypography.captionText)
                    .foregroundColor(.accentOrange)
            }

            Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                .font(AppTypography.captionText)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: AppSpacing.md) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentOrange))
                        .scaleEffect(1.5)

                    Text("Processing...")
                        .font(AppTypography.bodyText)
                        .foregroundColor(.white)
                }
                .padding(AppSpacing.xl)
                .background(Color.white)
                .cornerRadius(AppCornerRadius.card)
                .cardShadow()
            }
    }

    // MARK: - Actions

    private func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await purchaseManager.loadProducts()
        } catch {
            // Handle error silently or show error
            print("Failed to load products: \(error)")
        }
    }

    private func subscribeToPremium() async {
        guard let product = purchaseManager.monthlyPremiumProduct else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await purchaseManager.purchasePremium(product)
            // Success will be handled by the subscription manager
            dismiss()
        } catch {
            // Handle purchase error
            print("Purchase failed: \(error)")
        }
    }

    private func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await purchaseManager.restorePurchases()
        } catch {
            // Handle restore error
            print("Restore failed: \(error)")
        }
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let includedInFree: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(includedInFree ? .success : .accentOrange)
                .frame(width: 30, height: 30)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.bodyText)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(AppTypography.captionText)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            
        }
        .padding(AppSpacing.md)
        .background(Color.white)
        .cornerRadius(AppCornerRadius.medium)
        .cardShadow()
    }
}

// MARK: - Preview

#Preview {
    PremiumUpgradeView()
}
