import SwiftUI

struct FlashcardView: View {
    // MARK: - Properties

    let word: String
    let level: String
    let translation: String
    let definition: String
    let photo: UIImage?
    let isLoadingPhoto: Bool
    let examples: [SentencePair]
    let synonyms: [String]
    let antonyms: [String]
    let collocations: [String]
    let isFlipped: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Back side
            FlashcardBackView(
                word: word,
                translation: translation,
                definition: definition,
                examples: examples,
                synonyms: synonyms,
                antonyms: antonyms,
                collocations: collocations
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )

            // Front side
            FlashcardFrontView(
                word: word,
                level: level,
                photo: photo,
                isLoadingPhoto: isLoadingPhoto
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? -180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .onTapGesture {
            withAnimation(AppAnimation.flip) {
                onTap()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Front side
        FlashcardView(
            word: "Abandon",
            level: "B2",
            translation: "Terk etmek",
            definition: "To leave behind",
            photo: UIImage(systemName: "photo"),
            isLoadingPhoto: false,
            examples: SentencePair.samples,
            synonyms: ["desert", "leave"],
            antonyms: ["keep", "support"],
            collocations: ["abandon hope", "abandon ship"],
            isFlipped: false,
            onTap: {}
        )

        // Back side
        FlashcardView(
            word: "Beautiful",
            level: "A1",
            translation: "Güzel",
            definition: "Pleasing to the senses",
            photo: nil,
            isLoadingPhoto: false,
            examples: [],
            synonyms: [],
            antonyms: [],
            collocations: [],
            isFlipped: true,
            onTap: {}
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.creamBackground)
}
