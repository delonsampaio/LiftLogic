import SwiftUI

struct WarmupModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            if vm.targetWeight == 0 {
                Text("Enter a target weight in CALC mode first")
                    .font(.subheadline)
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        // Header
                        HStack {
                            Text("%").frame(width: 44, alignment: .center)
                            Text("Target").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Per Side").frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(ThemeTokens.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

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
                    .font(.footnote.weight(.bold))
                    .monospaced()
                    .foregroundStyle(settings.accentColor)
                    .frame(width: 44, alignment: .center)

                Text("\(set.targetWeight.weightString) \(settings.unit.symbol)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeTokens.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let summary = PlateResult(platesPerSide: set.platesPerSide, totalWeight: set.targetWeight, remainder: 0).summary
                Text(summary)
                    .font(.caption.weight(.medium))
                    .monospaced()
                    .foregroundStyle(ThemeTokens.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(ThemeTokens.backgroundCard)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
