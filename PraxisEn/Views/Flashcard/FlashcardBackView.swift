import SwiftUI

struct FlashcardBackView: View {
    // MARK: - Properties

    let word: String
    let translation: String
    let definition: String
    let examples: [SentencePair]
    let synonyms: [String]
    let antonyms: [String]
    let collocations: [String]

    // MARK: - Body

    var body: some View {
        ZStack {
            // White background
            Color.white

            ScrollView(.vertical, showsIndicators: true) {
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
                            .fixedSize(horizontal: false, vertical: true)
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
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Synonyms
                    if !synonyms.isEmpty {
                        VStack(spacing: AppSpacing.sm) {
                            Text("Synonyms")
                                .font(AppTypography.captionText)
                                .foregroundColor(.textSecondary)

                            Text(synonyms.joined(separator: ", "))
                                .font(AppTypography.bodyText)
                                .foregroundColor(.info)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Antonyms
                    if !antonyms.isEmpty {
                        VStack(spacing: AppSpacing.sm) {
                            Text("Antonyms")
                                .font(AppTypography.captionText)
                                .foregroundColor(.textSecondary)

                            Text(antonyms.joined(separator: ", "))
                                .font(AppTypography.bodyText)
                                .foregroundColor(.error)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Collocations
                    if !collocations.isEmpty {
                        VStack(spacing: AppSpacing.sm) {
                            Text("Collocations")
                                .font(AppTypography.captionText)
                                .foregroundColor(.textSecondary)

                            Text(collocations.joined(separator: " • "))
                                .font(AppTypography.bodyText)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }

                    // Example sentences
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Examples")
                            .font(AppTypography.captionText)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !examples.isEmpty {
                            ForEach(examples.prefix(10), id: \.id) { example in
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(example.englishText)
                                        .font(AppTypography.example)
                                        .foregroundColor(.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Text(example.turkishText)
                                        .font(AppTypography.captionText)
                                        .foregroundColor(.textSecondary)
                                        .italic()
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, AppSpacing.xs)
                            }
                        } else {
                            // Show loading state when no examples available
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .textTertiary))
                                        .scaleEffect(0.8)

                                    Text("Example sentences loading...")
                                        .font(AppTypography.example)
                                        .foregroundColor(.textTertiary)
                                        .italic()
                                }
                                .padding(.vertical, AppSpacing.sm)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .frame(width: CardDimensions.width(for: UIScreen.main.bounds.width), height: CardDimensions.height(for: UIScreen.main.bounds.width))
        .cornerRadius(AppCornerRadius.card)
        .cardShadow()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // With all data
        FlashcardBackView(
            word: "Abandon",
            translation: "Terk etmek, bırakmak",
            definition: "To leave someone or something behind, typically forever",
            examples: SentencePair.samples,
            synonyms: ["desert", "leave", "forsake"],
            antonyms: ["keep", "maintain", "support"],
            collocations: ["abandon hope", "abandon a plan", "abandon ship"]
        )

        // Minimal data
        FlashcardBackView(
            word: "Beautiful",
            translation: "Güzel",
            definition: "Pleasing to the senses or mind",
            examples: [],
            synonyms: [],
            antonyms: [],
            collocations: []
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.creamBackground)
}
