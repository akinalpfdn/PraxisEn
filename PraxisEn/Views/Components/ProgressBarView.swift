import SwiftUI

struct ProgressBarView: View {
    // MARK: - Properties

    let current: Int
    let total: Int
    let showAnimation: Bool

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                // Progress text
                HStack {
                    Text("\(current)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.accentOrange)

                    Text("/")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textTertiary)

                    Text("\(total)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textSecondary)

                    Spacer()

                    Text("words learned")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 12)

                        // Progress fill with gradient
                        RoundedRectangle(cornerRadius: 8)
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
                            .frame(width: geometry.size.width * progress, height: 12)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                    }
                }
                .frame(height: 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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

// MARK: - Preview

#Preview {
    ZStack {
        Color.creamBackground
            .ignoresSafeArea()

        VStack(spacing: 30) {
            // Low progress
            ProgressBarView(
                current: 45,
                total: 3000,
                showAnimation: false
            )

            // Medium progress
            ProgressBarView(
                current: 850,
                total: 3000,
                showAnimation: false
            )

            // High progress with animation
            ProgressBarView(
                current: 2500,
                total: 3000,
                showAnimation: true
            )
        }
        .padding()
    }
}
