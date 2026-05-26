import SwiftUI

struct ReadoutView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    private var displayWeight: Double {
        vm.currentMode == .reverse ? vm.reverseTotal : vm.targetWeight
    }

    private var isAmber: Bool {
        vm.currentMode == .calc && !vm.plateResult.isExact && vm.targetWeight > 0
    }

    private var remainderText: String? {
        guard isAmber else { return nil }
        let r = vm.plateResult.remainder
        return String(format: "Closest: %.1f %@ (%.1f short)",
                      displayWeight - r, settings.unit.symbol, r)
    }

    private var bodyweightRatioText: String? {
        guard settings.isPro, settings.bodyWeight > 0, displayWeight > 0 else { return nil }
        let ratio = displayWeight / settings.bodyWeight
        return String(format: "%.2f× bodyweight", ratio)
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
                    .font(ThemeTokens.readoutFont)
                    .foregroundStyle(isAmber ? ThemeTokens.warningAmber : ThemeTokens.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayWeight)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)

                Text(settings.unit.symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding(.bottom, 8)
            }

            if let text = remainderText {
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ThemeTokens.warningAmber)
            } else if let text = bodyweightRatioText {
                Text(text)
                    .font(ThemeTokens.readoutSubFont)
                    .foregroundStyle(Color(white: 0.4))
            } else if let text = secondaryUnitText {
                Text(text)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(ThemeTokens.textMuted)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayWeight)
            }
        }
        .padding(.horizontal)
    }
}
