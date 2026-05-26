import SwiftUI

enum ThemeTokens {
    // Accent
    static let accent    = Color(red: 1.0, green: 0.42, blue: 0.21)       // #FF6B35 orange
    static let accentPro = Color(red: 0.608, green: 0.349, blue: 0.714)   // #9b59b6 purple

    // Backgrounds
    static let backgroundPrimary = Color(white: 0.06)
    static let backgroundCard    = Color(white: 0.09)
    static let backgroundInput   = Color(white: 0.11)

    // Text — contrast tuned for WCAG AA against backgroundPrimary
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textMuted     = Color(white: 0.5)

    // Warning
    static let warningAmber  = Color(red: 0.95, green: 0.61, blue: 0.07)

    // Delta banner — add (green) / remove (amber-red)
    static let deltaAdd    = Color(red: 0.25, green: 0.78, blue: 0.35)
    static let deltaRemove = Color(red: 0.95, green: 0.45, blue: 0.15)

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

    // Micro / small plate colors — IWF color cycle (red→blue→yellow→white→green)
    // applied to micro sizes so they read as a family with standard plates.
    private static func microPlateColor(weight: Double, unit: WeightUnit) -> Color {
        if unit == .lbs {
            switch weight {
            case 2..<4:   return Color(white: 0.50)                          // 2.5 lb   — gray (standard chrome)
            case 1.15...: return Color(red: 0.80, green: 0.10, blue: 0.10)  // 1.25 lb  — red  (matches 45 lb)
            case ..<0.40: return Color(red: 0.10, green: 0.60, blue: 0.15)  // 0.25 lb  — green (matches 5 lb)
            case ..<0.65: return Color(white: 0.88)                          // 0.50 lb  — white (matches 10 lb)
            case ..<0.90: return Color(red: 0.90, green: 0.75, blue: 0.10)  // 0.75 lb  — yellow (matches 25 lb)
            default:      return Color(red: 0.10, green: 0.30, blue: 0.80)  // 1.00 lb  — blue  (matches 35 lb)
            }
        } else {
            // weight here is the original kg value
            switch weight {
            case 1.15...: return Color(white: 0.50)                          // 1.25 kg  — gray (standard chrome)
            case ..<0.65: return Color(white: 0.88)                          // 0.25/0.50 kg — white
            case ..<1.15: return Color(red: 0.10, green: 0.60, blue: 0.15)  // 1.00 kg  — green (matches 5 lb)
            default:      return Color(red: 0.90, green: 0.75, blue: 0.10)  // 1.50 kg  — yellow (matches 15 kg)
            }
        }
    }

    // Fonts
    static let readoutFont    = Font.system(size: 72, weight: .black, design: .rounded)
    static let readoutSubFont = Font.system(size: 16, weight: .medium)
    static let numpadFont     = Font.system(size: 28, weight: .semibold, design: .rounded)
}
