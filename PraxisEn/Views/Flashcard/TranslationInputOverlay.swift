import SwiftUI

/// A modal popup that presents the translation input interface
struct TranslationInputOverlay: View {

    // MARK: - Properties

    @Binding var userInput: String
    let validationState: ValidationState
    let validationResult: ValidationResult?
    let onSubmit: () -> Void
    let onClear: () -> Void
    let onHide: () -> Void
    let userStartedTyping: () -> Void

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        onHide()
                    }

                // Centered modal container
                VStack(spacing: 0) {
                    // Modal header
                    modalHeaderView

                    // Modal content
                    modalContentView
                        .background(Color.white)
                        .cornerRadius(AppCornerRadius.card)
                        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                }
                .frame(maxWidth: min(400, geometry.size.width - 40))
                .frame(maxHeight: min(300, geometry.size.height - 80))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipped()
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
    }

    // MARK: - Subviews

    private var modalHeaderView: some View {
        HStack {
            Text("")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)

            Spacer()

            // Close button
            Button(action: onHide) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(Color.creamSecondary)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    private var modalContentView: some View {
        VStack(spacing: AppSpacing.lg) {
            // Instructions
            modalInstructionView

            // Translation input
            TranslationInputView(
                userInput: $userInput,
                validationState: validationState,
                validationResult: validationResult,
                onSubmit: onSubmit,
                onClear: onClear
            )
            .onChange(of: userInput) { _, _ in
                userStartedTyping()
            }
 
 
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
    }

    private var modalInstructionView: some View {
        VStack(spacing: AppSpacing.md) {

            Text("Enter the Turkish Translation")
                .font(AppTypography.cardTitle)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text("Type the correct translation to mark this word as learned")
                .font(AppTypography.bodyText)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(.vertical, AppSpacing.md)
    }

}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.info)
            .cornerRadius(AppCornerRadius.button)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.info)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.info.opacity(0.1))
            .cornerRadius(AppCornerRadius.button)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var input: String = ""
        @State private var show: Bool = true

        var body: some View {
            ZStack {
                Color.creamBackground.ignoresSafeArea()

                if show {
                    TranslationInputOverlay(
                        userInput: $input,
                        validationState: .typing,
                        validationResult: nil,
                        onSubmit: {
                            //print("Submit")
                        },
                        onClear: {
                            input = ""
                        },
                        onHide: {
                            show = false
                        },
                        userStartedTyping: {
                            //print("Started typing")
                        }
                    )
                }
            }
        }
    }

    return PreviewWrapper()
}
