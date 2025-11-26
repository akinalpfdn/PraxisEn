import SwiftUI

struct FlashcardFrontView: View {
    // MARK: - Properties

    let word: String
    let level: String
    let photo: UIImage?
    let isLoadingPhoto: Bool
    let onPlayAudio: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Always show white background first
            Color.white

            // Show photo if loaded (no loading spinner - load silently in background)
            if let photo = photo {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: CardDimensions.width, height: CardDimensions.height)
                    .clipped()
                    .opacity(0.7)  // Light background effect
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }

            // Speaker button (top-right)
            VStack {
                HStack {
                    Spacer()

                    Button(action: onPlayAudio) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentOrange)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                            )
                    }
                    .padding(.top, AppSpacing.md)
                    .padding(.trailing, AppSpacing.md)

                   // Spacer()
                }

                Spacer()
            }

            // Content overlay - always visible
            VStack {
                Spacer()

                // Word display with dynamic font size
                Text(word)
                    .font(.system(size: dynamicFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)

                Spacer()
                    .frame(height: AppSpacing.xl)
            }
        }
        .frame(width: CardDimensions.width, height: CardDimensions.height)
        .cornerRadius(AppCornerRadius.card)
        .cardShadow()
        .id("\(word)-\(photo != nil)")  // Force refresh when photo changes
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

    /// Dynamic font size based on word length
    private var dynamicFontSize: CGFloat {
        let wordLength = word.count

        switch wordLength {
        case 0...9:
            return 48  // Large font for short words
        case 10...12:
            return 40  // Medium font for medium words 
        default:
            return 32 // Smallest font for very long words
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
            isLoadingPhoto: false,
            onPlayAudio: { //print("Play audio")
            }
        )

        // Loading state
        FlashcardFrontView(
            word: "Learning",
            level: "A1",
            photo: nil,
            isLoadingPhoto: true,
            onPlayAudio: { //print("Play audio")
            }
        )

        // Placeholder state
        FlashcardFrontView(
            word: "Beautiful",
            level: "A2",
            photo: nil,
            isLoadingPhoto: false,
            onPlayAudio: { //print("Play audio")
            }
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.creamBackground)
}
