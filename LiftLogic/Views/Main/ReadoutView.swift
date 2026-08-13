import SwiftUI

struct ReadoutView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 1.7 : 1.0 }

    private var displayWeight: Double {
        vm.currentMode == .reverse ? vm.reverseTotal : vm.targetWeight
    }

    private var isAmber: Bool {
        vm.currentMode == .calc && !vm.plateResult.isExact && vm.targetWeight > 0
    }

    private var remainderText: String? {
        guard isAmber else { return nil }
        let result = vm.plateResult
        let closest = String(format: "Closest: %.1f %@ (%.1f short)",
                             vm.closestLoadableWeight, settings.unit.symbol, vm.totalShort)
        switch result.shortageReason {
        case .outOfPlates:
            return "\(closest) · Out of Plates"
        case .unsupportedIncrement, .none:
            return closest
        }
    }

    private var bodyweightRatioText: String? {
        guard settings.isPro, settings.bodyWeight > 0, displayWeight > 0 else { return nil }
        let ratio = displayWeight / settings.bodyWeight
        return String(format: "%.2f× bodyweight", ratio)
    }

    private var percentOf1RMText: String? {
        guard let percent = settings.percentOfSavedOneRM(for: displayWeight) else { return nil }
        return "\(percent)% of your 1RM"
    }

    private var secondaryUnitText: String? {
        guard displayWeight > 0 else { return nil }
        let other: WeightUnit = settings.unit == .lbs ? .kg : .lbs
        let converted = settings.unit.convert(displayWeight, to: other)
        return String(format: "%.1f %@", converted, other.symbol)
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(displayWeight == 0 ? "0" : displayWeight.weightStringPrecise)
                    .font(.system(size: 72 * scale, weight: .black, design: .rounded))
                    .foregroundStyle(isAmber ? ThemeTokens.warningAmber : ThemeTokens.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayWeight)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)

                Text(settings.unit.symbol)
                    .font(sizeClass == .regular ? .title.weight(.semibold) : .title2.weight(.semibold))
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding(.bottom, 8)
            }

            if let text = remainderText {
                Text(text)
                    .font(sizeClass == .regular ? .subheadline.weight(.medium) : .footnote.weight(.medium))
                    .foregroundStyle(ThemeTokens.warningAmber)
            } else if let text = percentOf1RMText {
                Text(text)
                    .font(.system(size: 16 * scale, weight: .medium))
                    .foregroundStyle(Color(white: 0.4))
            } else if let text = bodyweightRatioText {
                Text(text)
                    .font(.system(size: 16 * scale, weight: .medium))
                    .foregroundStyle(Color(white: 0.4))
            } else if let text = secondaryUnitText {
                Text(text)
                    .font(sizeClass == .regular ? .title3.weight(.medium) : .subheadline.weight(.medium))
                    .monospaced()
                    .foregroundStyle(ThemeTokens.textMuted)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayWeight)
            }
        }
        .padding(.horizontal)
    }
}
