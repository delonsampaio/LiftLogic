import SwiftUI

enum ThemeTokens {
    // Accent
    static let accent    = Color(red: 1.0, green: 0.42, blue: 0.21)       // #FF6B35 orange
    static let accentPro = Color(red: 0.608, green: 0.349, blue: 0.714)   // #9b59b6 purple

    // Backgrounds
    static let backgroundPrimary = Color(white: 0.06)
    static let backgroundCard    = Color(white: 0.09)
    static let backgroundInput   = Color(white: 0.11)

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 0.6)
    static let textMuted     = Color(white: 0.35)

    // Warning
    static let warningAmber = Color(red: 0.95, green: 0.61, blue: 0.07)

    // Plate colors (IWF-inspired: red=heavy, blue=35, yellow=25, white=10, green=5, gray=2.5)
    static func plateColor(for weight: Double, unit: WeightUnit) -> Color {
        let lbsWeight = unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        switch lbsWeight {
        case 99...:       return Color(red: 0.8, green: 0.1, blue: 0.1)   // red   — 45s
        case 75..<99:     return Color(red: 0.1, green: 0.3, blue: 0.8)   // blue  — 35s
        case 50..<75:     return Color(red: 0.9, green: 0.75, blue: 0.1)  // yellow — 25s
        case 20..<50:     return Color(white: 0.85)                        // white — 10s
        case 9..<20:      return Color(red: 0.1, green: 0.6, blue: 0.15)  // green — 5s
        default:          return Color(white: 0.5)                         // gray  — 2.5s
        }
    }

    // Fonts
    static let readoutFont    = Font.system(size: 72, weight: .black, design: .rounded)
    static let readoutSubFont = Font.system(size: 16, weight: .medium)
    static let numpadFont     = Font.system(size: 28, weight: .semibold, design: .rounded)
}
