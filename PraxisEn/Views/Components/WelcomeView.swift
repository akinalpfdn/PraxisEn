//
//  WelcomeView.swift
//  PraxisEn
//
//  Created by Gemini on 12.07.2025.
//

import SwiftUI

struct WelcomeView: View {
    // MARK: - Properties
    
    // Action to execute when the user finishes the onboarding
    var onDismiss: () -> Void
    
    @State private var currentPage = 0
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            // Background
            Color.creamBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header / Skip Button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Atla") {
                            completeOnboarding()
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal)
                    }
                }
                .frame(height: 50)
                
                // Content Pager
                TabView(selection: $currentPage) {
                    welcomePage
                        .tag(0)
                    
                    navigationPage
                        .tag(1)
                    
                    flipPage
                        .tag(2)
                    
                    masteryPage
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom Controls
                VStack(spacing: 20) {
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.accentOrange : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    // Action Button
                    Button(action: {
                        if currentPage < totalPages - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        Text(currentPage == totalPages - 1 ? "Başla" : "Devam Et")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.accentOrange)
                            .cornerRadius(16)
                            .shadow(color: .accentOrange.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    private func completeOnboarding() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Haptic feedback for completion
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)

        onDismiss()
    }
    
    // MARK: - Page 1: Intro
    
    var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo / Icon placeholder
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 10)
                
                Image(systemName: "character.book.closed.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentOrange)
            }
            .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                Text("PraxisEn'e Hoş Geldin")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("İngilizce kelime dağarcığını geliştirmenin en pratik ve kalıcı yolu.")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Page 2: Navigation (Swipe Left/Right)
    
    var navigationPage: some View {
        OnboardingTemplateView(
            title: "Kelimeler Arasında Gezin",
            description: "Sıradaki kelimeye geçmek için sola, bir önceki kelimeye dönmek için sağa kaydır.",
            animationView: AnyView(SwipeAnimationView())
        )
    }
    
    // MARK: - Page 3: Flip (Tap)
    
    var flipPage: some View {
        OnboardingTemplateView(
            title: "Detayları Keşfet",
            description: "Kelimenin anlamını, Türkçe çevirisini ve örnek cümleleri görmek için karta dokun.",
            animationView: AnyView(TapAnimationView())
        )
    }
    
    // MARK: - Page 4: Mastery (Swipe Up)
    
    var masteryPage: some View {
        OnboardingTemplateView(
            title: "Öğrendiklerini Pekiştir",
            description: "Kelimeyi biliyor musun? Kartı yukarı kaydır, anlamını yaz ve öğrendiğini kanıtla.",
            animationView: AnyView(SwipeUpAnimationView())
        )
    }
}

// MARK: - Subcomponents

/// Standard template for onboarding pages to ensure consistent layout
struct OnboardingTemplateView: View {
    let title: String
    let description: String
    let animationView: AnyView
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animation Container
            ZStack {
                // Mock Card Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 260, height: 340)
                    .shadow(color: .black.opacity(0.05), radius: 15)
                
                // Dynamic Animation Content
                animationView
            }
            .padding(.bottom, 20)
            
            // Text Content
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Animations

/// Simulates Horizontal Swiping
struct SwipeAnimationView: View {
    @State private var offset: CGFloat = 0
    @State private var handOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dummy Card Content
            VStack(spacing: 10) {
                Text("Achieve")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("B1")
                    .font(.caption)
                    .padding(6)
                    .background(Color.accentOrange.opacity(0.2))
                    .cornerRadius(8)
            }
            .offset(x: offset)
            
            // Hand Icon
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentOrange)
                .offset(x: 20 + offset, y: 80)
                .opacity(handOpacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                // Sequence simulation using keyframes logic via animation delays
                animateSwipe()
            }
        }
    }
    
    func animateSwipe() {
        // Simple loop animation logic
        let baseAnimation = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)
        
        withAnimation(baseAnimation) {
            offset = -100
            handOpacity = 1
        }
    }
}

/// Simulates Tapping/Flipping
struct TapAnimationView: View {
    @State private var isFlipped = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            if isFlipped {
                VStack(spacing: 8) {
                    Text("Başarmak")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.accentOrange)
                    Text("to succeed in finishing something")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // Counteract parent rotation
            } else {
                Text("Achieve")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            
            // Tap indicator
            Circle()
                .stroke(Color.accentOrange, lineWidth: 2)
                .frame(width: 50, height: 50)
                .scaleEffect(scale)
                .opacity(2 - scale)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .onAppear {
            let flipAnimation = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: false)
            
            withAnimation(flipAnimation) {
                // Simulate tap sequence
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    withAnimation(.spring()) {
                        isFlipped.toggle()
                    }
                    // Reset scale for ripple effect
                    scale = 1.0
                    withAnimation(.easeOut(duration: 0.5)) {
                        scale = 1.5
                    }
                }
            }
        }
    }
}

/// Simulates Vertical Swipe (Mark as Known)
struct SwipeUpAnimationView: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            VStack {
                Text("Awesome")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                    .opacity(offset < -50 ? 1 : 0) // Show checkmark when swiped up
            }
            .offset(y: offset)
            .opacity(opacity)
            
            // Arrow indicator
            VStack {
                Image(systemName: "arrow.up")
                    .font(.title)
                    .foregroundColor(.accentOrange)
                    .offset(y: offset - 20)
                    .opacity(0.5)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                offset = -150
                opacity = 0
            }
        }
    }
}

 
