import SwiftUI

struct FlashcardBackView: View {
    // MARK: - Properties

    let word: String
    let translation: String
    let definition: String
    let examples: [SentencePair]

    // MARK: - Body

    var body: some View {
        ZStack {
            // White background
            Color.white

            VStack(spacing: AppSpacing.lg) {
                // Word at top
                Text(word)
                    .font(AppTypography.cardTitle)
                    .foregroundColor(.textSecondary)
                    .padding(.top, AppSpacing.xl)

                Divider()
                    .padding(.horizontal, AppSpacing.lg)

                // Translation
                VStack(spacing: AppSpacing.sm) {
                    Text("Turkish Translation")
                        .font(AppTypography.captionText)
                        .foregroundColor(.textSecondary)

                    Text(translation)
                        .font(AppTypography.translation)
                        .foregroundColor(.accentOrange)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.lg)

                // Definition
                if !definition.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Text("Definition")
                            .font(AppTypography.captionText)
                            .foregroundColor(.textSecondary)

                        Text(definition)
                            .font(AppTypography.bodyText)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                Spacer()

                // Example sentences
                if !examples.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Examples")
                            .font(AppTypography.captionText)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(examples.prefix(2), id: \.id) { example in
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(example.englishText)
                                    .font(AppTypography.example)
                                    .foregroundColor(.textPrimary)

                                Text(example.turkishText)
                                    .font(AppTypography.captionText)
                                    .foregroundColor(.textSecondary)
                                    .italic()
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .frame(width: CardDimensions.width, height: CardDimensions.height)
        .cornerRadius(AppCornerRadius.card)
        .cardShadow()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // With examples
        FlashcardBackView(
            word: "Abandon",
            translation: "Terk etmek, bırakmak",
            definition: "To leave someone or something behind, typically forever",
            examples: SentencePair.samples
        )

        // Without examples
        FlashcardBackView(
            word: "Beautiful",
            translation: "Güzel",
            definition: "Pleasing to the senses or mind",
            examples: []
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.creamBackground)
}
