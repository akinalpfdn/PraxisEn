import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stats: ReviewStats?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let stats = stats {
                    StatCard(
                        title: "Words Learned",
                        value: "\(stats.knownWords)",
                        icon: "checkmark.circle.fill",
                        color: .success
                    )

                    StatCard(
                        title: "In Review",
                        value: "\(stats.wordsInReview)",
                        icon: "arrow.clockwise.circle.fill",
                        color: .accentOrange
                    )

                    
                    StatCard(
                        title: "Total Words",
                        value: "\(stats.totalWords)",
                        icon: "book.fill",
                        color: .textSecondary
                    )
                } else {
                    ProgressView("Loading stats...")
                }
            }
            .padding()
        }
        .background(Color.creamBackground.ignoresSafeArea())
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            stats = await SpacedRepetitionManager.getReviewStats(from: modelContext)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}
