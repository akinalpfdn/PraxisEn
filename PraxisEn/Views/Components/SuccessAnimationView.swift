import SwiftUI

struct SuccessAnimationView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -30
    @State private var particles: [Particle] = []

    var body: some View {
        ZStack {
            // Main +1 text with glow
            Text("+1")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.9, blue: 0.3),  // Bright green
                            Color(red: 0.1, green: 0.7, blue: 0.2)   // Dark green
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.green.opacity(0.6), radius: 20, x: 0, y: 0)
                .shadow(color: Color.green.opacity(0.4), radius: 40, x: 0, y: 0)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)

            // Particles (confetti/firework effect)
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            // Main animation (2x duration)
            withAnimation(.spring(response: 1.2, dampingFraction: 0.5)) {
                scale = 1.2
                opacity = 1
                rotation = 0
            }

            // Bounce back (2x delay and duration)
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4)) {
                scale = 1.0
            }

            // Fade out (2x duration and delay)
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                opacity = 0
            }

            // Create particles
            createParticles()
        }
    }

    private func createParticles() {
        let colors: [Color] = [
            .green,
            .yellow,
            .orange,
            Color(red: 0.2, green: 0.9, blue: 0.3),
            Color(red: 1.0, green: 0.8, blue: 0.0)
        ]

        // Create 30 particles in all directions
        for i in 0..<30 {
            let angle = Double(i) * (360.0 / 30.0) * .pi / 180.0
            let distance: CGFloat = CGFloat.random(in: 80...150)
            let size: CGFloat = CGFloat.random(in: 4...12)

            let particle = Particle(
                id: UUID(),
                x: 0,
                y: 0,
                color: colors.randomElement() ?? .green,
                size: size,
                opacity: 1.0
            )

            particles.append(particle)

            // Animate particle (2x duration and delay range)
            let index = particles.count - 1
            withAnimation(.easeOut(duration: 1.6).delay(Double.random(in: 0...0.2))) {
                particles[index].x = cos(angle) * distance
                particles[index].y = sin(angle) * distance
                particles[index].opacity = 0
            }
        }
    }
}

struct Particle: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    var opacity: Double
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.creamBackground
            .ignoresSafeArea()

        SuccessAnimationView()
    }
}
