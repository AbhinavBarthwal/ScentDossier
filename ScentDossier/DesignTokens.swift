import SwiftUI

// MARK: - Design Tokens
// Black & white theme with gold accent

enum DT {
    // Core palette — pure black & white
    static let ink = Color.black
    static let inkSoft = Color(white: 0.15)
    static let parchment = Color.white
    static let parchmentDim = Color(white: 0.7)
    static let gold = Color(hex: "C4975A")
    static let goldDeep = Color(hex: "96703D")
    static let rose = Color(hex: "C44536")
    static let sage = Color(hex: "6F8767")
    static let plum = Color(hex: "6B4E71")
    static let citrus = Color(hex: "B98A2E")
    
    // Surface layers
    static let card = Color(white: 0.08)
    static let cardBorder = Color.white.opacity(0.1)
    static let divider = Color.white.opacity(0.12)
    
    // Spacing (8pt grid)
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 36
    static let spacingXXL: CGFloat = 48
    
    // Corner radius
    static let radiusSM: CGFloat = 10
    static let radiusMD: CGFloat = 16
    static let radiusLG: CGFloat = 24
    static let radiusXL: CGFloat = 32
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

// MARK: - Button Modifiers

struct GoldBorderButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .tracking(0.5)
            .textCase(.uppercase)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(Color.white)
            .foregroundColor(Color.black)
            .clipShape(Capsule())
    }
}

struct SecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .medium))
            .tracking(0.5)
            .textCase(.uppercase)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .foregroundColor(Color.white)
            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
            .clipShape(Capsule())
    }
}

extension View {
    func goldButton() -> some View {
        modifier(GoldBorderButton())
    }
    
    func secondaryButton() -> some View {
        modifier(SecondaryButton())
    }
}

// MARK: - Shared Components

/// A small bulleted info row used in explanatory cards (e.g. cosmic/essence "How this works").
struct InfoBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundColor(DT.gold)
                .padding(.top, 6)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
