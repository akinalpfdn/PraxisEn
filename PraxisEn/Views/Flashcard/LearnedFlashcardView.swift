//
//  LearnedFlashcardView.swift
//  PraxisEn
//
//  Created by Akinalp Fidan on 13.11.2025.
//

import SwiftUI
import SwiftData

struct LearnedFlashcardView: View {
    @ObservedObject private var viewModel: LearnedFlashcardViewModel

    init(viewModel: LearnedFlashcardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Color.creamBackground.ignoresSafeArea()
            
            VStack(spacing: AppSpacing.lg) {
                if let word = viewModel.currentWord {
                    SwipeableCardStack(
                        currentCard: FlashcardCardData(
                            word: word.word.capitalized,
                            level: word.level,
                            translation: word.turkishTranslation,
                            definition: word.definition,
                            photo: viewModel.currentPhoto,
                            isLoadingPhoto: viewModel.isLoadingPhoto,
                            examples: viewModel.exampleSentences,
                            synonyms: word.synonymsList,
                            antonyms: word.antonymsList,
                            collocations: word.collocationsList,
                            isFlipped: viewModel.isFlipped
                        ),
                        nextCard: viewModel.nextWordPreview.map { next in
                            FlashcardCardData(
                                word: next.word.capitalized,
                                level: next.level,
                                translation: next.turkishTranslation,
                                definition: next.definition,
                                photo: viewModel.nextWordPreviewPhoto,
                                isLoadingPhoto: false,
                                examples: [],
                                synonyms: next.synonymsList,
                                antonyms: next.antonymsList,
                                collocations: next.collocationsList,
                                isFlipped: false
                            )
                        },
                        previousCard: viewModel.previousWordPreview.map { prev in
                            FlashcardCardData(
                                word: prev.word.capitalized,
                                level: prev.level,
                                translation: prev.turkishTranslation,
                                definition: prev.definition,
                                photo: viewModel.previousWordPreviewPhoto,
                                isLoadingPhoto: false,
                                examples: [],
                                synonyms: prev.synonymsList,
                                antonyms: prev.antonymsList,
                                collocations: prev.collocationsList,
                                isFlipped: false
                            )
                        },
                        onSwipeLeft: {
                            Task { await viewModel.nextWord() }
                        },
                        onSwipeRight: {
                            Task { await viewModel.previousWord() }
                        },
                        onTap: {
                            viewModel.toggleFlip()
                        },
                        onSwipeUp: {}, // Swipe up is disabled
                        onPlayAudio: {
                            viewModel.playWordAudio()
                        }
                    )
                } else {
                    ProgressView("Loading Word...")
                }
                
                hintView
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle(viewModel.currentWord?.word.capitalized ?? "Word")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var hintView: some View {
        HStack(spacing: AppSpacing.lg) {
            // Swipe left hint
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentOrange)
                
                Text("Swipe")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            
            Circle().fill(Color.textTertiary.opacity(0.3)).frame(width: 4, height: 4)
            
            // Tap hint
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentOrange)
                
                Text("Tap to flip")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            
            Circle().fill(Color.textTertiary.opacity(0.3)).frame(width: 4, height: 4)
            
            // Swipe right hint
            HStack(spacing: 6) {
                Text("Swipe")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentOrange)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.4))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}