import SwiftUI

struct SwipeableCardStack: View {
    // MARK: - Properties

    let currentCard: FlashcardCardData
    let nextCard: FlashcardCardData?
    let previousCard: FlashcardCardData?
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onTap: () -> Void 
    let onSwipeUp: () -> Void

    @State private var offset: CGFloat = 0 
    @State private var verticalOffset: CGFloat = 0
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 100 
    private let swipeUpThreshold: CGFloat = -100
    private let stackOffset: CGFloat = 10
    private let stackScale: CGFloat = 0.95

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background card (next or previous based on swipe direction)
            if offset < 0, let next = nextCard {
                // Swiping left - show next card behind
                backgroundCard(for: next)
                    .scaleEffect(stackScale + (1 - stackScale) * abs(offset) / 200)
                    .offset(x: stackOffset - abs(offset) / 10)
                    .opacity(0.5 + 0.5 * abs(offset) / 200)
            } else if offset > 0, let previous = previousCard {
                // Swiping right - show previous card behind
                backgroundCard(for: previous)
                    .scaleEffect(stackScale + (1 - stackScale) * abs(offset) / 200)
                    .offset(x: -stackOffset + abs(offset) / 10)
                    .opacity(0.5 + 0.5 * abs(offset) / 200)
            } else if verticalOffset < 0, let next = nextCard {
                // Swiping up - show next card behind
                backgroundCard(for: next)
                    .scaleEffect(stackScale + (1 - stackScale) * abs(verticalOffset) / 200)
                    .offset(y: stackOffset - abs(verticalOffset) / 10)
                    .opacity(0.5 + 0.5 * abs(verticalOffset) / 200)
            }
            
            // Current card
            FlashcardView(
                word: currentCard.word,
                level: currentCard.level,
                translation: currentCard.translation,
                definition: currentCard.definition,
                photo: currentCard.photo,
                isLoadingPhoto: currentCard.isLoadingPhoto,
                examples: currentCard.examples,
                synonyms: currentCard.synonyms,
                antonyms: currentCard.antonyms,
                collocations: currentCard.collocations,
                isFlipped: currentCard.isFlipped,
                onTap: onTap
            )
            .offset(x: offset, y: verticalOffset)
            .rotationEffect(.degrees(Double(offset) / 20))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height
                        
                        // Vertical swipe (only on FRONT side and upward)
                        if verticalAmount < 0 && !currentCard.isFlipped && abs(verticalAmount) > abs(horizontalAmount) {
                            verticalOffset = verticalAmount
                            isDragging = true
                        }
                        // Horizontal swipe
                        else if abs(horizontalAmount) > abs(verticalAmount) {
                            offset = horizontalAmount
                            isDragging = true
                        }
                    }
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height
                        
                        // Swipe up (from FRONT side only)
                        if verticalAmount < swipeUpThreshold && !currentCard.isFlipped {
                            withAnimation(.easeOut(duration: 0.3)) {
                                verticalOffset = -1000
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipeUp()
                                verticalOffset = 0
                            }
                            return
                        }
                        
                        // Only respond to horizontal swipes
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            if abs(horizontalAmount) > swipeThreshold {
                                // Swipe completed
                                if horizontalAmount < 0 {
                                    // Swipe left - next word
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        offset = -500
                                    }
                                    
                                    // Wait for animation to complete before updating
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        onSwipeLeft()
                                        // Reset offset without animation (card is off-screen)
                                        offset = 0
                                    }
                                } else {
                                    // Swipe right - previous word
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        offset = 500
                                    }
                                    
                                    // Wait for animation to complete before updating
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        onSwipeRight()
                                        // Reset offset without animation (card is off-screen)
                                        offset = 0
                                    }
                                }
                            } else {
                                // Swipe cancelled - return to center
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = 0
                                }
                            }
                        } else {
                            // Vertical swipe - return to center
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = 0
                                verticalOffset = 0
                            }
                            
                            isDragging = false
                        }
                        
                    }
        )}
    }

    // MARK: - Background Card

    private func backgroundCard(for data: FlashcardCardData) -> some View {
        FlashcardView(
            word: data.word,
            level: data.level,
            translation: data.translation,
            definition: data.definition,
            photo: data.photo,
            isLoadingPhoto: data.isLoadingPhoto,
            examples: data.examples,
            synonyms: data.synonyms,
            antonyms: data.antonyms,
            collocations: data.collocations,
            isFlipped: data.isFlipped,
            onTap: {}
        )
        .allowsHitTesting(false)
    }
}

// MARK: - Card Data Model

struct FlashcardCardData {
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
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.creamBackground
            .ignoresSafeArea()

        SwipeableCardStack(
            currentCard: FlashcardCardData(
                word: "Abandon",
                level: "B2",
                translation: "Terk etmek",
                definition: "To leave behind",
                photo: UIImage(systemName: "photo"),
                isLoadingPhoto: false,
                examples: SentencePair.samples,
                synonyms: ["desert", "leave"],
                antonyms: ["keep", "support"],
                collocations: ["abandon hope"],
                isFlipped: false
            ),
            nextCard: FlashcardCardData(
                word: "Beautiful",
                level: "A1",
                translation: "Güzel",
                definition: "Pleasing to see",
                photo: nil,
                isLoadingPhoto: false,
                examples: [],
                synonyms: [],
                antonyms: [],
                collocations: [],
                isFlipped: false
            ),
            previousCard: FlashcardCardData(
                word: "Challenge",
                level: "B1",
                translation: "Meydan okuma",
                definition: "A difficult task",
                photo: nil,
                isLoadingPhoto: false,
                examples: [],
                synonyms: [],
                antonyms: [],
                collocations: [],
                isFlipped: false
            ),
            onSwipeLeft: {},
            onSwipeRight: {},
            onTap: {},
            onSwipeUp: {}
        )
        .padding()
    }
}
