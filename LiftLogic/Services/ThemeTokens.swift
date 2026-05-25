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

    // Standard plate colors — IWF/IPF thresholds in lbs
    static func plateColor(for weight: Double, unit: WeightUnit) -> Color {
        let lbs = unit == .lbs ? weight : WeightUnit.kg.convert(weight, to: .lbs)
        switch lbs {
        case 44...:  return Color(red: 0.80, green: 0.10, blue: 0.10)  // red    — 45 lb / 20 kg
        case 33..<44: return Color(red: 0.10, green: 0.30, blue: 0.80) // blue   — 35 lb / 15 kg
        case 22..<33: return Color(red: 0.90, green: 0.75, blue: 0.10) // yellow — 25 lb / 10 kg
        case 9..<22:  return Color(white: 0.88)                         // white  — 10 lb / 5 kg
        case 4..<9:   return Color(red: 0.10, green: 0.60, blue: 0.15) // green  — 5 lb / 2.5 kg
        default:      return microPlateColor(weight: weight, unit: unit)
        }
    }

    // Micro / small plate colors — branched by unit system.
    // Slightly lighter/more vibrant than the standard equivalents so
    // a 1.0 lb plate reads as "red family" but is visually distinct from a 45.
    private static func microPlateColor(weight: Double, unit: WeightUnit) -> Color {
        if unit == .lbs {
            switch weight {
            case 2..<4:   return Color(white: 0.50)                          // 2.5 lb   — gray (standard)
            case ..<0.40: return Color(red: 0.20, green: 0.78, blue: 0.28)  // 0.25 lb  — bright green
            case ..<0.65: return Color(red: 0.97, green: 0.86, blue: 0.22)  // 0.50 lb  — bright yellow
            case ..<0.90: return Color(red: 0.22, green: 0.48, blue: 0.94)  // 0.75 lb  — bright blue
            case ..<1.15: return Color(red: 0.94, green: 0.22, blue: 0.22)  // 1.00 lb  — bright red
            default:      return Color(red: 0.54, green: 0.12, blue: 0.74)  // 1.25 lb  — purple (unique)
            }
        } else {
            // weight here is the original kg value
            switch weight {
            case 1.15...: return Color(white: 0.50)                          // 1.25 kg  — gray (standard)
            case ..<0.65: return Color(white: 0.86)                          // 0.25/0.50 kg — silver
            case ..<1.15: return Color(red: 0.20, green: 0.78, blue: 0.28)  // 1.00 kg  — bright green
            default:      return Color(red: 0.97, green: 0.86, blue: 0.22)  // 1.50 kg  — bright yellow
            }
        }
    }

    // Fonts
    static let readoutFont    = Font.system(size: 72, weight: .black, design: .rounded)
    static let readoutSubFont = Font.system(size: 16, weight: .medium)
    static let numpadFont     = Font.system(size: 28, weight: .semibold, design: .rounded)
}
