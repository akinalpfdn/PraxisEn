import SwiftUI

struct ProgressBarView: View {
    // MARK: - Properties

    let current: Int
    let total: Int
    let showAnimation: Bool
    let isPremiumUser: Bool
    let b2WordCount: Int // Number of B2 words (locked for free users)
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    private var lockedProgress: Double {
        guard total > 0 else { return 0 }
        if isPremiumUser {
            return 0 // No locked content for premium users
        }
        // Free users: B2 words are locked (gray portion on right side)
        return Double(b2WordCount) / Double(total)
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = UIScreen.main.bounds.width
            let isSmallScreen = screenWidth <= 375 // iPhone SE and smaller
            let isMediumScreen = screenWidth <= 414
            
            ZStack(alignment: .topTrailing) {
                VStack(spacing: isSmallScreen ? 4 : 8) {
                    // Progress text
                    HStack {
                        Text("\(current)")
                            .font(.system(size: AppSpacing.responsiveFontSize(baseSize: 18, for: UIScreen.main.bounds.width), weight: .bold, design: .rounded))
                            .foregroundColor(.accentOrange)
                        
                        Text("/")
                            .font(.system(size: AppSpacing.responsiveFontSize(baseSize: 16, for: UIScreen.main.bounds.width), weight: .medium))
                            .foregroundColor(.textTertiary)
                        
                        Text("\(total)")
                            .font(.system(size: AppSpacing.responsiveFontSize(baseSize: 16, for: UIScreen.main.bounds.width), weight: .medium))
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                        
                        // Hide "words learned" on very small screens
                        if !isSmallScreen {
                            Text("words learned")
                                .font(.system(size: AppSpacing.responsiveFontSize(baseSize: 13, for: UIScreen.main.bounds.width), weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // Progress bar
                    GeometryReader { barGeometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: isSmallScreen ? 4 : 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: isSmallScreen ? 6 : 12)

                            // Learned words fill (green) - anchored to left
                            RoundedRectangle(cornerRadius: isSmallScreen ? 4 : 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.8, blue: 0.4),  // Light green
                                            Color(red: 0.2, green: 0.7, blue: 0.3)   // Darker green
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: barGeometry.size.width * progress, height: isSmallScreen ? 6 : 12)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                        }
                        .overlay {
                            // B2 locked words overlay (gray) - positioned on right side
                            if !isPremiumUser && lockedProgress > 0 {
                                HStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: isSmallScreen ? 4 : 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.gray.opacity(0.4),
                                                    Color.gray.opacity(0.6)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: barGeometry.size.width * lockedProgress,
                                            height: isSmallScreen ? 6 : 12
                                        )
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: lockedProgress)
                                }
                            }
                        }
                    }
                    .frame(height: isSmallScreen ? 6 : 12)
                }
                .padding(.horizontal, AppSpacing.responsivePadding(basePadding: 20, for: UIScreen.main.bounds.width))
                .padding(.vertical, AppSpacing.responsivePadding(basePadding: 16, for: UIScreen.main.bounds.width))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                )

                // +1 Animation popup
                if showAnimation {
                    Text("+1")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.accentOrange)
                        .offset(x: -16, y: -8)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showAnimation)
                }
            }
        }
    }
}
// MARK: - Preview

#Preview {
    ZStack {
        Color.creamBackground
            .ignoresSafeArea()

        VStack(spacing: 30) {
            // Free user - Low progress, B2 words locked
            ProgressBarView(
                current: 45,
                total: 3000,
                showAnimation: false,
                isPremiumUser: false,
                b2WordCount: 800 // Example: 800 B2 words
            )

            // Free user - Medium progress, B2 words locked
            ProgressBarView(
                current: 500,
                total: 3000,
                showAnimation: false,
                isPremiumUser: false,
                b2WordCount: 800 // Example: 800 B2 words
            )

            // Premium user - Full access, no B2 locked
            ProgressBarView(
                current: 2500,
                total: 3000,
                showAnimation: true,
                isPremiumUser: true,
                b2WordCount: 0 // No locked words
            )
        }
        .padding()
    }
}
