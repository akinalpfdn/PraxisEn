import SwiftUI

struct FlashcardFrontView: View {
    // MARK: - Properties

    let word: String
    let level: String
    let photo: UIImage?
    let isLoadingPhoto: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background image or white placeholder
            if let photo = photo, !isLoadingPhoto {
                // Photo loaded - show with gradient overlay
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: CardDimensions.width, height: CardDimensions.height)
                    .clipped()

                // Gradient overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                // Loading or no photo yet
                placeholderView
            }

            // Content overlay
            VStack {
                Spacer()

                // Word display
                Text(word)
                    .font(AppTypography.wordDisplay)
                    .foregroundColor(photo != nil && !isLoadingPhoto ? .white : .textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xl)
            }
        }
        .frame(width: CardDimensions.width, height: CardDimensions.height)
        .cornerRadius(AppCornerRadius.card)
        .cardShadow()
    }

    // MARK: - Subviews

    private var placeholderView: some View {
        ZStack {
            // White background (matching main card)
            Color.white

            if isLoadingPhoto {
                // Loading indicator
                VStack(spacing: AppSpacing.md) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentOrange))
                        .scaleEffect(1.5)

                    Text("Loading photo...")
                        .font(AppTypography.captionText)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }

    private var levelBadge: some View {
        HStack(spacing: AppSpacing.xs) {
            // Level emoji only
            Text(levelEmoji)
                .font(.system(size: 20))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(.thinMaterial)
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var levelEmoji: String {
        switch level {
        case "A1": return "🟢"
        case "A2": return "🔵"
        case "B1": return "🟠"
        case "B2": return "🔴"
        default: return "⚪️"
        }
    }
}

// MARK: - Blur View Helper

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // With photo
        FlashcardFrontView(
            word: "Abandon",
            level: "B2",
            photo: UIImage(systemName: "photo"),
            isLoadingPhoto: false
        )

        // Loading state
        FlashcardFrontView(
            word: "Learning",
            level: "A1",
            photo: nil,
            isLoadingPhoto: true
        )

        // Placeholder state
        FlashcardFrontView(
            word: "Beautiful",
            level: "A2",
            photo: nil,
            isLoadingPhoto: false
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.creamBackground)
}
