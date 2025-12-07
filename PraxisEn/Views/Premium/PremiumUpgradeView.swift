import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    
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
                    
                    // Restore Section
                    restoreSection
                    
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
                if purchaseManager.isLoading {
                    loadingOverlay
                }
            }
            .task {
                await loadProducts()
            }
        }
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
            
            VStack(spacing: AppSpacing.md) {
                // Yearly Plan (Recommended) - Clickable
                Button {
                    Task {
                        await subscribeToYearly()
                    }
                } label: {
                    yearlyPlanCard
                }
                .disabled(purchaseManager.isLoading || purchaseManager.yearlyPremiumProduct == nil)
                .buttonStyle(CardButtonStyle())
                
                // Monthly Plan - Clickable
                Button {
                    Task {
                        await subscribeToMonthly()
                    }
                } label: {
                    monthlyPlanCard
                }
                .disabled(purchaseManager.isLoading || purchaseManager.monthlyPremiumProduct == nil)
                .buttonStyle(CardButtonStyle())
            }
        }
    }
    
    private var yearlyPlanCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text("Premium Yearly")
                            .font(AppTypography.cardTitle)
                            .foregroundColor(.textPrimary)

                        if let yearlyProduct = purchaseManager.yearlyPremiumProduct,
                           let monthlyProduct = purchaseManager.monthlyPremiumProduct {
                            // Convert to Double for reliable calculation
                            let yearlyPrice = NSDecimalNumber(decimal: yearlyProduct.price).doubleValue
                            let monthlyPrice = NSDecimalNumber(decimal: monthlyProduct.price).doubleValue
                            let twelveMonthsPrice = monthlyPrice * 12
                            let discountAmount = twelveMonthsPrice - yearlyPrice
                            let discountPercentage = (discountAmount / twelveMonthsPrice) * 100
                            let discountInt = Int(round(discountPercentage))

                            Text("SAVE \(discountInt)%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.success)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("Best value, billed yearly")
                        .font(AppTypography.captionText)
                        .foregroundColor(.textTertiary)
                    
                    HStack(spacing: AppSpacing.xs) {
                        if let yearlyProduct = purchaseManager.yearlyPremiumProduct {
                            let monthlyPrice = yearlyProduct.price / 12
                            Text("£\(String(format: "%.2f", NSDecimalNumber(decimal: monthlyPrice).doubleValue))/mo")
                                .font(.system(size: AppTypography.headline, weight: .bold))
                                .foregroundColor(.textSecondary)

                            Text("£\(yearlyProduct.displayPrice)/year")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.accentOrange)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.lg)
            .background(Color.white)
            .cornerRadius(AppCornerRadius.card)
            .cardShadow()
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(Color.success, lineWidth: 2)
            )
            .overlay(
                VStack {
                    HStack {
                        Text("MOST POPULAR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.success)
                            .cornerRadius(8)
                        Spacer()
                        
                        if purchaseManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                    }
                    Spacer()
                }
                    .padding(.leading, AppSpacing.md)
                    .padding(.top, -8)
            )
        }
    }
    
    private var monthlyPlanCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Premium Monthly")
                        .font(AppTypography.cardTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Billed monthly, cancel anytime")
                        .font(AppTypography.captionText)
                        .foregroundColor(.textTertiary)
                    
                    if let monthlyProduct = purchaseManager.monthlyPremiumProduct {
                        Text(monthlyProduct.displayPrice)
                            .font(.system(size: AppTypography.headline, weight: .bold))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if purchaseManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentOrange))
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.lg)
            .background(Color.white)
            .cornerRadius(AppCornerRadius.card)
            .cardShadow()
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(Color.accentOrange, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Restore Section
    
    private var restoreSection: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(AppTypography.bodyText)
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .stroke(Color.textSecondary, lineWidth: 1)
                )
        }
        .disabled(purchaseManager.isLoading)
    }
    
    // MARK: - Legal Links Section
    
    private var legalLinksSection: some View {
        VStack(spacing: AppSpacing.sm) {
             
            
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
        //print("🔄 PremiumUpgradeView: Starting to load products...")
        //print("🔄 PurchaseManager isLoading: \(purchaseManager.isLoading)")
        //print("🔄 PurchaseManager products count: \(purchaseManager.products.count)")
        
        do {
            try await purchaseManager.loadProducts()
            
            // Check button states after loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                //print("📊 Button state check:")
                //print("   - isLoading: \(purchaseManager.isLoading)")
                //print("   - monthlyProduct available: \(purchaseManager.monthlyPremiumProduct != nil)")
                //print("   - yearlyProduct available: \(purchaseManager.yearlyPremiumProduct != nil)")
                //print("   - monthly button disabled: \(purchaseManager.isLoading || purchaseManager.monthlyPremiumProduct == nil)")
                //print("   - yearly button disabled: \(purchaseManager.isLoading || purchaseManager.yearlyPremiumProduct == nil)")
            }
        } catch {
            // Handle error silently or show error
            //print("❌ PremiumUpgradeView: Failed to load products: \(error)")
        }
    }
    
    private func subscribeToYearly() async {
        guard let product = purchaseManager.yearlyPremiumProduct else { return }
        
        do {
            _ = try await purchaseManager.purchasePremium(product)
            // Success will be handled by the subscription manager
            dismiss()
        } catch {
            // Handle purchase error
            //print("Yearly purchase failed: \(error)")
        }
    }
    
    private func subscribeToMonthly() async {
        guard let product = purchaseManager.monthlyPremiumProduct else { return }
        
        do {
            _ = try await purchaseManager.purchasePremium(product)
            // Success will be handled by the subscription manager
            dismiss()
        } catch {
            // Handle purchase error
            //print("Monthly purchase failed: \(error)")
        }
    }
    
    private func restorePurchases() async {
        do {
            try await purchaseManager.restorePurchases()
        } catch {
            // Handle restore error silently
        }
    }
    
    // MARK: - Card Button Style
    
    struct CardButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
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
}
// MARK: - Preview

#Preview {
    PremiumUpgradeView()
}
