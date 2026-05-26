import SwiftUI

struct OneRMModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 20) {
            if vm.targetWeight == 0 {
                Text("Enter the weight you lifted in CALC mode")
                    .font(.subheadline)
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding()
            } else {
                // Reps stepper
                HStack(spacing: 16) {
                    Text("Reps lifted:")
                        .foregroundStyle(ThemeTokens.textSecondary)
                        .font(.system(size: 15, weight: .medium))

                    Stepper("\(vm.oneRMReps)", value: Binding(
                        get: { vm.oneRMReps },
                        set: { vm.oneRMReps = $0 }
                    ), in: 1...OneRMEngine.maxReliableReps)
                    .fixedSize()
                }
                .padding(.horizontal)

                if vm.oneRMReps > 10 {
                    Text("Estimates lose accuracy above 10 reps")
                        .font(.caption2)
                        .foregroundStyle(ThemeTokens.textMuted)
                        .padding(.horizontal)
                }

                // Results
                let result = vm.oneRMResult

                VStack(spacing: 12) {
                    oneRMRow(label: "Epley", value: result.epley, unit: settings.unit.symbol)
                    oneRMRow(label: "Brzycki", value: result.brzycki, unit: settings.unit.symbol)

                    Divider().opacity(0.2)

                    // Average — tap to load
                    Button {
                        vm.loadWeight(result.average.rounded())
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            vm.currentMode = .calc
                        }
                        HapticManager.shared.numpadKey()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Average (Est. 1RM)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ThemeTokens.accentPro)
                                Text("Tap to load into CALC")
                                    .font(.caption2)
                                    .foregroundStyle(ThemeTokens.textMuted)
                            }
                            Spacer()
                            Text("\(Int(result.average.rounded())) \(settings.unit.symbol)")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(ThemeTokens.accentPro)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(ThemeTokens.accentPro.opacity(0.12)))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(ThemeTokens.accentPro.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func oneRMRow(label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ThemeTokens.textSecondary)
            Spacer()
            Text("\(Int(value.rounded())) \(unit)")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(ThemeTokens.textPrimary)
        }
        .padding(.horizontal)
    }
}
