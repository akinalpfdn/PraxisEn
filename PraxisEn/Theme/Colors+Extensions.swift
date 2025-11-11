import SwiftUI

// MARK: - App Color Palette

extension Color {
    // MARK: - Primary Colors (Cream Theme)

    /// Açık krem - Ana arka plan rengi
    static let creamBackground = Color(hex: "FFF8E7")

    /// Koyu krem - Secondary background
    static let creamSecondary = Color(hex: "F5ECD7")

    /// Daha koyu krem - Borders ve subtle elements
    static let creamDark = Color(hex: "E8DCC4")

    // MARK: - Text Colors

    /// Ana metin rengi - Koyu gri
    static let textPrimary = Color(hex: "2C2C2C")

    /// İkincil metin rengi - Orta gri
    static let textSecondary = Color(hex: "6B6B6B")

    /// Açık metin rengi - Light gri (placeholder, disabled)
    static let textTertiary = Color(hex: "A0A0A0")

    // MARK: - Accent Colors

    /// Vurgu rengi - Soft orange/brown
    static let accentOrange = Color(hex: "E8A87C")

    /// İkincil vurgu - Warm terracotta
    static let accentTerracotta = Color(hex: "D68C6F")

    /// Soft brown - Buttons, highlights
    static let accentBrown = Color(hex: "A67C52")

    // MARK: - Semantic Colors

    /// Başarı rengi
    static let success = Color(hex: "8FBC8F")

    /// Uyarı rengi
    static let warning = Color(hex: "F4A460")

    /// Hata rengi
    static let error = Color(hex: "CD8B8B")

    /// Bilgi rengi
    static let info = Color(hex: "87CEEB")

    // MARK: - Shadow & Overlay

    /// Card shadow
    static let shadowColor = Color.black.opacity(0.08)

    /// Overlay için koyu
    static let overlayDark = Color.black.opacity(0.3)

    /// Overlay için açık
    static let overlayLight = Color.white.opacity(0.9)

    // MARK: - Helper for Hex Colors

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Color Preview Helper

#if DEBUG
struct ColorPalette_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                colorSection("Primary Colors", colors: [
                    ("Cream Background", .creamBackground),
                    ("Cream Secondary", .creamSecondary),
                    ("Cream Dark", .creamDark)
                ])

                colorSection("Text Colors", colors: [
                    ("Text Primary", .textPrimary),
                    ("Text Secondary", .textSecondary),
                    ("Text Tertiary", .textTertiary)
                ])

                colorSection("Accent Colors", colors: [
                    ("Accent Orange", .accentOrange),
                    ("Accent Terracotta", .accentTerracotta),
                    ("Accent Brown", .accentBrown)
                ])

                colorSection("Semantic Colors", colors: [
                    ("Success", .success),
                    ("Warning", .warning),
                    ("Error", .error),
                    ("Info", .info)
                ])
            }
            .padding()
        }
        .background(Color.creamBackground)
    }

    static func colorSection(_ title: String, colors: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForEach(colors, id: \.0) { name, color in
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 60, height: 40)

                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    Spacer()
                }
            }
        }
    }
}
#endif
