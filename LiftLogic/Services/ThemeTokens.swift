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

    // Standard plate colors — IWF/IPF (kg) and Rogue/Ivanko industry standard (lbs)
    static let chrome = Color(white: 0.72)    // silver / chrome — 1.25 kg, 0.25 kg
    static let gold   = Color(red: 0.85, green: 0.65, blue: 0.13)  // 100 lb

    static func plateColor(for weight: Double, unit: WeightUnit) -> Color {
        if unit == .kg {
            switch weight {
            case 50.0:  return .green
            case 25.0:  return .red
            case 20.0:  return .blue
            case 15.0:  return .yellow
            case 10.0:  return .green
            case 5.0:   return .white
            case 2.5:   return .red
            case 2.0:   return .blue
            case 1.5:   return .yellow
            case 1.25:  return chrome
            case 1.0:   return .green
            case 0.5:   return .white
            case 0.25:  return chrome
            default:    return Color(white: 0.2)
            }
        } else {
            switch weight {
            case 100.0: return gold
            case 55.0:  return .red
            case 45.0:  return .blue
            case 35.0:  return .yellow
            case 25.0:  return .green
            case 10.0:  return .white
            case 5.0:   return Color(white: 0.2)
            case 2.5:   return Color(white: 0.2)
            case 1.25:  return Color(white: 0.2)
            case 1.0:   return .green
            case 0.75:  return .blue
            case 0.5:   return .white
            case 0.25:  return .red
            default:    return Color(white: 0.2)
            }
        }
    }

    // Fonts
    static let readoutFont    = Font.system(size: 72, weight: .black, design: .rounded)
    static let readoutSubFont = Font.system(size: 16, weight: .medium)
    static let numpadFont     = Font.system(size: 28, weight: .semibold, design: .rounded)
}
