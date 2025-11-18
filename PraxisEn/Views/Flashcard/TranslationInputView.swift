import SwiftUI

/// A custom translation input field for active recall learning
struct TranslationInputView: View {

    // MARK: - Properties

    @Binding var userInput: String
    @State private var isFocused: Bool = false
    @FocusState private var isFieldFocused: Bool

    let validationState: ValidationState
    let validationResult: ValidationResult?
    let onSubmit: () -> Void
    let onClear: () -> Void

    // MARK: - Computed Properties

    private var inputFieldColor: Color {
        switch validationState {
        case .none, .typing:
            return .textPrimary
        case .validating:
            return .textSecondary
        case .correct:
            return .success
        case .incorrect:
            return .error
        }
    }

    private var borderColor: Color {
        switch validationState {
        case .none, .typing:
            return isFieldFocused ? .info : .textTertiary
        case .validating:
            return .accentOrange
        case .correct:
            return .success
        case .incorrect:
            return .error
        }
    }

    private var showValidationMessage: Bool {
        validationState == .correct || validationState == .incorrect
    }

    private var validationMessage: String {
        guard let result = validationResult else { return "" }
        return result.message
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Input field container
            HStack(spacing: 12) {
                // Text input field
                TextField(
                    "Enter Turkish translation...",
                    text: $userInput,
                    axis: .vertical
                )
                .focused($isFieldFocused)
                .textFieldStyle(CustomTextFieldStyle(
                    textColor: inputFieldColor,
                    borderColor: borderColor
                ))
                .keyboardType(.default)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    handleSubmit()
                }

                // Clear button
                if !userInput.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textTertiary)
                            .font(.system(size: 20))
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Submit button
                Button(action: handleSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(userInput.isEmpty ? .textTertiary : .info)
                        .font(.system(size: 24))
                }
                .disabled(userInput.isEmpty || validationState == .validating)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(borderColor, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            // Validation message with animation
            if showValidationMessage {
                HStack(spacing: 8) {
                    Image(systemName: validationState == .correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(validationState == .correct ? .success : .error)

                    Text(validationMessage)
                        .font(AppTypography.bodyText)
                        .foregroundColor(validationState == .correct ? .success : .error)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }

            // Loading indicator
            if validationState == .validating {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .info))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: validationState)
        .animation(.easeInOut(duration: 0.2), value: isFieldFocused)
    }

    // MARK: - Private Methods

    private func handleSubmit() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSubmit()
    }
}

// MARK: - Custom TextField Style

struct CustomTextFieldStyle: TextFieldStyle {
    let textColor: Color
    let borderColor: Color

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppTypography.translation)
            .foregroundColor(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.clear)
    }
}

// MARK: - Validation State Enum

enum ValidationState {
    case none        // No input yet
    case typing      // User is currently typing
    case validating  // Checking answer
    case correct     // Correct answer
    case incorrect   // Wrong answer
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var input: String = ""
        @State private var state: ValidationState = .typing

        var body: some View {
            VStack(spacing: 32) {
                TranslationInputView(
                    userInput: $input,
                    validationState: state,
                    validationResult: ValidationResult(
                        isCorrect: state == .correct,
                        confidence: 0.9,
                        feedback: .minorTypo
                    ),
                    onSubmit: {
                        state = .correct
                    },
                    onClear: {
                        input = ""
                        state = .typing
                    }
                )
                .padding()
                .background(Color.creamBackground)

                HStack(spacing: 12) {
                    Button("Typing") { state = .typing }
                    Button("Validating") { state = .validating }
                    Button("Correct") { state = .correct }
                    Button("Incorrect") { state = .incorrect }
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}