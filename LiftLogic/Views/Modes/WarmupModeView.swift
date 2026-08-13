import SwiftUI

struct WarmupModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 1.7 : 1.0 }

    var body: some View {
        VStack(spacing: 0) {
            if vm.targetWeight == 0 {
                Text("Enter a target weight in CALC mode first")
                    .font(sizeClass == .regular ? .title3 : .subheadline)
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        // Header
                        HStack {
                            Text("%").frame(width: 44 * scale, alignment: .center)
                            Text("Target").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Per Side").frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .font(sizeClass == .regular ? .subheadline.weight(.semibold) : .caption2.weight(.semibold))
                        .foregroundStyle(ThemeTokens.textMuted)
                        .padding(.horizontal, 16 * scale)
                        .padding(.vertical, 8 * scale)

                        ForEach(vm.warmupSets) { warmupSet in
                            warmupRow(warmupSet)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func warmupRow(_ set: WarmupSet) -> some View {
        Button {
            vm.loadWeight(set.targetWeight)
            HapticManager.shared.numpadKey()
        } label: {
            HStack {
                Text("\(set.percentage)%")
                    .font(sizeClass == .regular ? .subheadline.weight(.bold) : .footnote.weight(.bold))
                    .monospaced()
                    .foregroundStyle(settings.accentColor)
                    .frame(width: 44 * scale, alignment: .center)

                Text("\(set.targetWeight.weightString) \(settings.unit.symbol)")
                    .font(sizeClass == .regular ? .title3.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(ThemeTokens.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let summary = PlateResult(platesPerSide: set.platesPerSide, totalWeight: set.targetWeight, remainder: 0).summary
                Text(summary)
                    .font(sizeClass == .regular ? .footnote.weight(.medium) : .caption.weight(.medium))
                    .monospaced()
                    .foregroundStyle(ThemeTokens.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16 * scale)
            .padding(.vertical, 12 * scale)
            .background(ThemeTokens.backgroundCard)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
