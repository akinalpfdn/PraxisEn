import SwiftUI

// MARK: - Typography

struct AppTypography {
    // MARK: - Font Sizes

    static let largeTitle: CGFloat = 34
    static let title1: CGFloat = 28
    static let title2: CGFloat = 22
    static let title3: CGFloat = 20
    static let headline: CGFloat = 17
    static let body: CGFloat = 17
    static let callout: CGFloat = 16
    static let subheadline: CGFloat = 15
    static let footnote: CGFloat = 13
    static let caption: CGFloat = 12

    // MARK: - Font Weights

    static let bold: Font.Weight = .bold
    static let semibold: Font.Weight = .semibold
    static let medium: Font.Weight = .medium
    static let regular: Font.Weight = .regular
    static let light: Font.Weight = .light

    // MARK: - Predefined Styles

    /// Large word display (flashcard front)
    static var wordDisplay: Font {
        .system(size: 48, weight: .bold, design: .rounded)
    }

    /// Translation text
    static var translation: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }

    /// Example sentence
    static var example: Font {
        .system(size: 16, weight: .regular, design: .default)
    }

    /// Card title
    static var cardTitle: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }

    /// Body text
    static var bodyText: Font {
        .system(size: 17, weight: .regular, design: .default)
    }

    /// Caption/hint text
    static var captionText: Font {
        .system(size: 14, weight: .regular, design: .default)
    }
}

// MARK: - Spacing

struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 24
    static let card: CGFloat = 20
    static let button: CGFloat = 20
}

// MARK: - Shadows

struct AppShadow {
    // MARK: - Card Shadow

    static let card = Shadow(
        color: .shadowColor,
        radius: 12,
        x: 0,
        y: 4
    )

    // MARK: - Button Shadow

    static let button = Shadow(
        color: .shadowColor,
        radius: 6,
        x: 0,
        y: 2
    )

    // MARK: - Light Shadow

    static let light = Shadow(
        color: .shadowColor,
        radius: 4,
        x: 0,
        y: 2
    )

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply card shadow
    func cardShadow() -> some View {
        self.shadow(
            color: AppShadow.card.color,
            radius: AppShadow.card.radius,
            x: AppShadow.card.x,
            y: AppShadow.card.y
        )
    }

    /// Apply button shadow
    func buttonShadow() -> some View {
        self.shadow(
            color: AppShadow.button.color,
            radius: AppShadow.button.radius,
            x: AppShadow.button.x,
            y: AppShadow.button.y
        )
    }

    /// Apply light shadow
    func lightShadow() -> some View {
        self.shadow(
            color: AppShadow.light.color,
            radius: AppShadow.light.radius,
            x: AppShadow.light.x,
            y: AppShadow.light.y
        )
    }

    /// Apply cream background
    func creamBackground() -> some View {
        self.background(Color.creamBackground)
    }
}

// MARK: - Animation Presets

struct AppAnimation {
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let quick = Animation.easeInOut(duration: 0.2)
    static let flip = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - Card Dimensions

struct CardDimensions {
    static let width: CGFloat = 340
    static let height: CGFloat = 480
    static let aspectRatio: CGFloat = height / width // ~1.41
}

// MARK: - Preview

#if DEBUG
struct AppTheme_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppSpacing.lg) {
            // Typography examples
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Word Display")
                    .font(AppTypography.wordDisplay)
                    .foregroundColor(.textPrimary)

                Text("Translation Text")
                    .font(AppTypography.translation)
                    .foregroundColor(.textSecondary)

                Text("Example sentence goes here")
                    .font(AppTypography.example)
                    .foregroundColor(.textTertiary)
            }

            // Card example
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.white)
                .frame(width: CardDimensions.width, height: 200)
                .cardShadow()
                .overlay(
                    Text("Card Example")
                        .font(AppTypography.cardTitle)
                        .foregroundColor(.textPrimary)
                )

            // Button example
            Text("Button")
                .font(AppTypography.bodyText)
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(Color.accentOrange)
                .cornerRadius(AppCornerRadius.medium)
                .buttonShadow()
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .creamBackground()
    }
}
#endif
